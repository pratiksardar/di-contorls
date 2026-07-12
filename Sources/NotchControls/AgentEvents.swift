import AppKit
import Combine
import Foundation

/// Agent session notifications (Claude Code, Codex, …). External processes
/// post events via `NotchControls notify …`; the running app observes them
/// over DistributedNotificationCenter and surfaces island banners.
final class AgentEventCenter: ObservableObject {
    static let notificationName = Notification.Name("dev.lemon.notchcontrols.agent-event")

    enum Kind: String {
        case attention
        case done
    }

    struct AgentEvent: Identifiable, Equatable {
        let id = UUID()
        let agent: String
        let message: String
        let kind: Kind
        let sourcePID: pid_t?
        let directory: String?
        let date = Date()

        var directoryName: String? {
            directory.map { URL(fileURLWithPath: $0).lastPathComponent }
        }
    }

    @Published private(set) var events: [AgentEvent] = []
    /// Everything ingested (incl. auto-dismissed), newest first, capped at 20.
    @Published private(set) var history: [AgentEvent] = []

    /// Wired by the app to "mic or camera live" — you're in a meeting/recording.
    var meetingActive: () -> Bool = { false }

    var attentionCount: Int { events.filter { $0.kind == .attention }.count }

    /// Hold pop-ups and sounds (badge still shows): during meetings or quiet hours.
    func suppressPopups() -> Bool {
        if Pref.enabled(Pref.meetingQuiet), meetingActive() { return true }
        return Pref.quietHoursActive()
    }

    init() {
        DistributedNotificationCenter.default().addObserver(
            forName: Self.notificationName, object: nil, queue: .main
        ) { [weak self] note in
            guard let info = note.userInfo else { return }
            self?.ingest(
                agent: info["agent"] as? String ?? "Agent",
                kind: Kind(rawValue: info["kind"] as? String ?? "") ?? .attention,
                message: info["message"] as? String ?? "Needs your attention",
                sourcePID: (info["sourcePID"] as? Int).map(pid_t.init),
                directory: info["dir"] as? String)
        }
    }

    func ingest(agent: String, kind: Kind, message: String,
                sourcePID: pid_t? = nil, directory: String? = nil) {
        guard Pref.enabled(Pref.agentNotifications) else { return }
        if let directory, Pref.mutedProjectList().contains(directory) { return }
        // coalesce: a new event replaces the previous one of the same kind
        // from the same agent+project (kills repeated Stop noise)
        events.removeAll { $0.kind == kind && $0.agent == agent && $0.directory == directory }
        let event = AgentEvent(agent: agent, message: message, kind: kind,
                               sourcePID: sourcePID, directory: directory)
        events.insert(event, at: 0)
        if events.count > 6 { events.removeLast(events.count - 6) }
        history.insert(event, at: 0)
        if history.count > 20 { history.removeLast(history.count - 20) }
        if kind == .attention {
            if Pref.enabled(Pref.attentionSound), !suppressPopups() {
                NSSound(named: "Ping")?.play()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
                self?.dismiss(event.id)
            }
        }
    }

    /// Banner click: jump to the terminal/editor that owns the session, then clear the event.
    func activate(_ event: AgentEvent) {
        if let pid = event.sourcePID, let app = NSRunningApplication(processIdentifier: pid) {
            app.activate()
        }
        dismiss(event.id)
    }

    func dismiss(_ id: UUID) {
        events.removeAll { $0.id == id }
    }
}

/// CLI side: `NotchControls notify [--agent X] [--kind attention|done] [--message "…"]`.
/// Reads hook JSON from stdin when piped (Claude Code hooks) and accepts a raw
/// JSON argv payload (Codex `notify` config). Runs headless and exits.
enum NotifyCLI {
    static let commandNotification = Notification.Name("dev.lemon.notchcontrols.command")

    static func runIfRequested() {
        let args = Array(CommandLine.arguments.dropFirst())
        if args.first == "install-hooks" {
            InstallHooks.run()
        }
        if args.first == "prompter" || args.first == "settings" {
            DistributedNotificationCenter.default().postNotificationName(
                commandNotification, object: nil,
                userInfo: ["command": args.first == "prompter" ? "toggle-prompter" : "open-settings"],
                deliverImmediately: true)
            exit(0)
        }
        guard args.first == "notify" else { return }

        var agent = "Agent"
        var kind = "attention"
        var message = ""

        var iterator = args.dropFirst().makeIterator()
        while let arg = iterator.next() {
            switch arg {
            case "--agent": agent = iterator.next() ?? agent
            case "--kind": kind = iterator.next() ?? kind
            case "--message": message = iterator.next() ?? message
            default:
                // Codex notify passes one JSON argv payload
                if arg.hasPrefix("{"), let json = parseJSON(Data(arg.utf8)) {
                    if agent == "Agent" { agent = "Codex" }
                    let type = json["type"] as? String ?? ""
                    kind = type.contains("complete") ? "done" : "attention"
                    if let m = json["last-assistant-message"] as? String { message = m }
                }
            }
        }

        // Claude Code hooks pipe event JSON on stdin
        if isatty(0) == 0,
           let data = try? FileHandle.standardInput.readToEnd(), !data.isEmpty,
           let json = parseJSON(data) {
            if message.isEmpty {
                message = json["message"] as? String ?? json["title"] as? String ?? ""
            }
            if let hookEvent = json["hook_event_name"] as? String, hookEvent == "Stop" {
                kind = "done"
            }
        }
        if message.isEmpty {
            message = kind == "done" ? "Finished — ready for review" : "Needs your input to continue"
        }

        var userInfo: [String: Any] = ["agent": agent, "kind": kind, "message": message]
        // hooks run in the session's project directory — that's the session identity
        userInfo["dir"] = FileManager.default.currentDirectoryPath
        // hook chain: this CLI ← shell ← agent ← … ← terminal/editor GUI app
        if let gui = ProcessUtils.nearestGUIApp(from: getpid()) {
            userInfo["sourcePID"] = Int(gui)
        }
        DistributedNotificationCenter.default().postNotificationName(
            AgentEventCenter.notificationName,
            object: nil,
            userInfo: userInfo,
            deliverImmediately: true)
        exit(0)
    }

    private static func parseJSON(_ data: Data) -> [String: Any]? {
        (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}
