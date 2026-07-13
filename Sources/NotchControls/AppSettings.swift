import AppKit
import ServiceManagement
import SwiftUI

/// UserDefaults keys for feature toggles. Views react via @AppStorage;
/// non-view consumers read the flag at the moment they act.
enum Pref {
    static let cameraIndicator = "pref.cameraIndicator"
    static let showTeleprompter = "pref.showTeleprompter"
    static let showSessions = "pref.showSessions"
    static let agentNotifications = "pref.agentNotifications"
    static let autoExpand = "pref.autoExpand"
    static let attentionSound = "pref.attentionSound"
    static let hidePrompterFromCapture = "pref.hidePrompterFromCapture"
    static let appearance = "pref.appearance" // "system" | "light" | "dark"
    static let meetingQuiet = "pref.meetingQuiet"
    static let quietHours = "pref.quietHours"
    static let quietStart = "pref.quietStart" // minutes since midnight
    static let quietEnd = "pref.quietEnd"
    static let projectColors = "pref.projectColors"
    static let subagentBadge = "pref.subagentBadge"
    static let mutedProjects = "pref.mutedProjects"
    static let fileShelf = "pref.fileShelf"
    static let cameraGuard = "pref.cameraGuard"

    static func mutedProjectList() -> [String] {
        UserDefaults.standard.stringArray(forKey: mutedProjects) ?? []
    }

    static func mute(project dir: String) {
        var list = mutedProjectList()
        guard !list.contains(dir) else { return }
        list.append(dir)
        UserDefaults.standard.set(list, forKey: mutedProjects)
    }

    static func unmute(project dir: String) {
        UserDefaults.standard.set(mutedProjectList().filter { $0 != dir }, forKey: mutedProjects)
    }

    static let defaults: [String: Any] = [
        cameraIndicator: true,
        showTeleprompter: true,
        showSessions: true,
        agentNotifications: true,
        autoExpand: true,
        attentionSound: true,
        hidePrompterFromCapture: true,
        appearance: "system",
        meetingQuiet: true,
        quietHours: false,
        quietStart: 22 * 60,
        quietEnd: 8 * 60,
        projectColors: true,
        subagentBadge: true,
        fileShelf: true,
        cameraGuard: false,
    ]

    static func enabled(_ key: String) -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    /// Inside the configured quiet-hours window (supports overnight ranges).
    static func quietHoursActive(now: Date = Date()) -> Bool {
        guard enabled(quietHours) else { return false }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: now)
        let minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        let start = UserDefaults.standard.integer(forKey: quietStart)
        let end = UserDefaults.standard.integer(forKey: quietEnd)
        if start == end { return false }
        return start < end ? (minutes >= start && minutes < end)
                           : (minutes >= start || minutes < end)
    }
}

/// Applies the Appearance setting to every window (settings, teleprompter).
/// The island stays black by design — it extends the physical notch.
enum ThemeApplier {
    static func apply() {
        switch UserDefaults.standard.string(forKey: Pref.appearance) {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        default: NSApp.appearance = nil // follow macOS
        }
    }
}

struct SettingsView: View {
    @AppStorage(Pref.cameraIndicator) private var cameraIndicator = true
    @AppStorage(Pref.showTeleprompter) private var showTeleprompter = true
    @AppStorage(Pref.showSessions) private var showSessions = true
    @AppStorage(Pref.agentNotifications) private var agentNotifications = true
    @AppStorage(Pref.autoExpand) private var autoExpand = true
    @AppStorage(Pref.attentionSound) private var attentionSound = true
    @AppStorage(Pref.hidePrompterFromCapture) private var hidePrompterFromCapture = true
    @AppStorage(Pref.appearance) private var appearance = "system"
    @AppStorage(Pref.meetingQuiet) private var meetingQuiet = true
    @AppStorage(Pref.quietHours) private var quietHours = false
    @AppStorage(Pref.quietStart) private var quietStart = 22 * 60
    @AppStorage(Pref.quietEnd) private var quietEnd = 8 * 60
    @AppStorage(Pref.projectColors) private var projectColors = true
    @AppStorage(Pref.subagentBadge) private var subagentBadge = true
    @AppStorage(Pref.fileShelf) private var fileShelf = true
    @AppStorage(Pref.cameraGuard) private var cameraGuard = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var mutedProjects = Pref.mutedProjectList()

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $appearance) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
                .onChange(of: appearance) { _, _ in ThemeApplier.apply() }
            }
            Section("Island modules") {
                Toggle("Camera in-use indicator", isOn: $cameraIndicator)
                Toggle("Teleprompter button", isOn: $showTeleprompter)
                Toggle("Running agent sessions list", isOn: $showSessions)
                Toggle("File shelf (drop files on the notch)", isOn: $fileShelf)
                Toggle("Camera Guard (alert when camera turns on)", isOn: $cameraGuard)
                    .help("macOS doesn't let apps switch the camera off system-wide — the guard alerts you the instant any app starts it")
            }
            Section("Sessions") {
                Toggle("Per-project name colors", isOn: $projectColors)
                    .disabled(!showSessions)
                Toggle("Sub-process count badges", isOn: $subagentBadge)
                    .disabled(!showSessions)
            }
            Section("Teleprompter") {
                Toggle("Invisible in screen shares & recordings", isOn: $hidePrompterFromCapture)
            }
            Section {
                Toggle("Show agent notifications", isOn: $agentNotifications)
                Toggle("Auto-expand island on new events", isOn: $autoExpand)
                    .disabled(!agentNotifications)
                Toggle("Play sound when attention needed", isOn: $attentionSound)
                    .disabled(!agentNotifications)
                Toggle("Hold pop-ups during meetings", isOn: $meetingQuiet)
                    .disabled(!agentNotifications)
                    .help("While your mic or camera is live, events badge silently instead of popping open")
                Toggle("Quiet hours", isOn: $quietHours)
                    .disabled(!agentNotifications)
                if quietHours {
                    HStack {
                        DatePicker("From", selection: timeBinding($quietStart),
                                   displayedComponents: .hourAndMinute)
                        DatePicker("To", selection: timeBinding($quietEnd),
                                   displayedComponents: .hourAndMinute)
                    }
                    .disabled(!agentNotifications)
                }
            } header: {
                Text("Agent notifications")
            } footer: {
                Text("Posted by your Claude Code and Codex hooks. Click a banner to jump to the session's window; orange events stay until dismissed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Muted projects") {
                if mutedProjects.isEmpty {
                    Text("None — right-click a notification to mute its project")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(mutedProjects, id: \.self) { dir in
                        HStack {
                            Text(URL(fileURLWithPath: dir).lastPathComponent)
                            Text(dir)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button {
                                Pref.unmute(project: dir)
                                mutedProjects = Pref.mutedProjectList()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Unmute")
                        }
                    }
                }
            }
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enable in
                        do {
                            if enable {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
                LabeledContent("System-wide mic mute", value: "⌥⇧M")
                LabeledContent("Version", value: "0.3.0")
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 620)
        .onAppear { mutedProjects = Pref.mutedProjectList() }
    }

    /// Bridges minutes-since-midnight storage to hour-and-minute DatePickers.
    private func timeBinding(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: minutes.wrappedValue / 60,
                                  minute: minutes.wrappedValue % 60,
                                  second: 0, of: Date()) ?? Date()
        } set: { date in
            let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
            minutes.wrappedValue = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        }
    }
}

final class SettingsWindowController {
    private lazy var window: NSWindow = {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 540),
                              styleMask: [.titled, .closable],
                              backing: .buffered,
                              defer: false)
        window.title = "NotchControls Settings"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: SettingsView())
        window.center()
        return window
    }()

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless() // cooperative activation ignores background apps
    }
}
