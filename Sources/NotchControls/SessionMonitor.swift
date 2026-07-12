import AppKit
import Combine
import Foundation

/// Live list of coding-agent CLI sessions (claude, codex) running system-wide.
final class SessionMonitor: ObservableObject {
    struct AgentSession: Identifiable, Equatable {
        let pid: pid_t
        let agent: String
        let directory: String
        let started: Date?
        let guiPID: pid_t?
        let subagents: Int
        let working: Bool
        var id: pid_t { pid }
    }

    struct Editor {
        let name: String
        let bundleID: String
    }

    /// Editors/terminals installed on this machine (checked once at launch).
    static let availableEditors: [Editor] = [
        Editor(name: "Cursor", bundleID: "com.todesktop.230313mzl4w4u92"),
        Editor(name: "VS Code", bundleID: "com.microsoft.VSCode"),
        Editor(name: "iTerm", bundleID: "com.googlecode.iterm2"),
        Editor(name: "Terminal", bundleID: "com.apple.Terminal"),
    ].filter { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0.bundleID) != nil }

    static func open(directory: String, in editor: Editor) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: editor.bundleID)
        else { return }
        NSWorkspace.shared.open([URL(fileURLWithPath: directory)],
                                withApplicationAt: appURL,
                                configuration: NSWorkspace.OpenConfiguration())
    }

    static func revealInFinder(_ directory: String) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: directory)])
    }

    @Published private(set) var sessions: [AgentSession] = []

    private static let agentBinaries = ["claude": "Claude Code", "codex": "Codex"]
    private var timer: Timer?
    private var cpuSamples: [pid_t: UInt64] = [:]
    // >80ms of CPU across a 5s poll ⇒ the agent is actively working, not waiting
    private static let workingThresholdNs: UInt64 = 80_000_000

    init() {
        poll()
        // ponytail: 5s full-pid-list poll (~ms of syscalls); kqueue proc events if it ever matters
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    deinit { timer?.invalidate() }

    func focus(_ session: AgentSession) {
        guard let pid = session.guiPID,
              let app = NSRunningApplication(processIdentifier: pid) else { return }
        app.activate()
    }

    private func poll() {
        guard UserDefaults.standard.bool(forKey: Pref.showSessions) else {
            if !sessions.isEmpty { sessions = [] }
            return
        }
        var matched: [pid_t: String] = [:]
        for pid in ProcessUtils.allPIDs() {
            // argv0 match (exec name is a version string for the claude CLI);
            // tty filter drops app daemons like Codex.app's bundled codex
            guard ProcessUtils.hasControllingTerminal(pid),
                  let argv0 = ProcessUtils.argv0(of: pid),
                  let agent = Self.agentBinaries[(argv0 as NSString).lastPathComponent]
            else { continue }
            matched[pid] = agent
        }
        // children roll up into their topmost matched ancestor's subagent count
        let all = Set(matched.keys)
        var tops: [pid_t] = []
        var childCount: [pid_t: Int] = [:]
        for pid in all {
            var parent = ProcessUtils.parentPID(of: pid)
            var hops = 0
            var topAncestor: pid_t?
            while let cur = parent, cur > 1, hops < 15 {
                if all.contains(cur) { topAncestor = cur }
                parent = ProcessUtils.parentPID(of: cur)
                hops += 1
            }
            if let topAncestor {
                childCount[topAncestor, default: 0] += 1
            } else {
                tops.append(pid)
            }
        }
        var nextSamples: [pid_t: UInt64] = [:]
        let top = tops
            .map { pid in
                let cpu = ProcessUtils.cpuTime(of: pid)
                if let cpu { nextSamples[pid] = cpu }
                let working: Bool
                if let cpu, let previous = cpuSamples[pid] {
                    working = cpu &- previous > Self.workingThresholdNs
                } else {
                    working = true // first sighting: assume active until sampled
                }
                return AgentSession(pid: pid,
                                    agent: matched[pid] ?? "Agent",
                                    directory: ProcessUtils.cwd(of: pid) ?? "?",
                                    started: ProcessUtils.startDate(of: pid),
                                    guiPID: ProcessUtils.nearestGUIApp(from: pid),
                                    subagents: childCount[pid] ?? 0,
                                    working: working)
            }
            .sorted { ($0.started ?? .distantPast) > ($1.started ?? .distantPast) }
        cpuSamples = nextSamples
        if top != sessions { sessions = top }
    }
}
