import AppKit
import Carbon.HIToolbox
import Combine
import SwiftUI

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let audio = AudioManager()
    private let camera = CameraMonitor()
    private var notch: NotchController?
    private let teleprompter = TeleprompterController()
    private var statusItem: NSStatusItem?
    private var muteMenuItem: NSMenuItem?
    private var guardMenuItem: NSMenuItem?
    private var hotKey: HotKey?
    private var guardHotKey: HotKey?
    private var cancellables = Set<AnyCancellable>()

    private let agentEvents = AgentEventCenter()
    private let sessions = SessionMonitor()
    private let shelf = ShelfStore()
    private let settings = SettingsWindowController()

    static func main() {
        NotifyCLI.runIfRequested() // headless `notify` subcommand exits here
        UserDefaults.standard.register(defaults: Pref.defaults)
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        ThemeApplier.apply()
        agentEvents.meetingActive = { [weak self] in
            guard let self else { return false }
            return self.audio.micInUse || self.camera.cameraInUse
        }
        notch = NotchController(
            audio: audio, camera: camera, agentEvents: agentEvents, sessions: sessions,
            shelf: shelf,
            openTeleprompter: { [weak self] in self?.teleprompter.toggle() },
            openSettings: { [weak self] in self?.settings.show() })
        setUpStatusItem()
        hotKey = HotKey(keyCode: UInt32(kVK_ANSI_M),
                        modifiers: UInt32(optionKey | shiftKey)) { [weak self] in
            self?.audio.toggleMute()
        }
        guardHotKey = HotKey(keyCode: UInt32(kVK_ANSI_G),
                             modifiers: UInt32(optionKey | shiftKey)) {
            UserDefaults.standard.set(!Pref.enabled(Pref.cameraGuard), forKey: Pref.cameraGuard)
        }
        DistributedNotificationCenter.default().addObserver(
            forName: NotifyCLI.commandNotification, object: nil, queue: .main
        ) { [weak self] note in
            switch note.userInfo?["command"] as? String {
            case "toggle-prompter": self?.teleprompter.toggle()
            case "open-settings": self?.settings.show()
            default: break
            }
        }
        // arming the guard while the camera is ALREADY live must alert immediately
        var lastGuard = Pref.enabled(Pref.cameraGuard)
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            let now = Pref.enabled(Pref.cameraGuard)
            defer { lastGuard = now }
            guard let self, now, !lastGuard, self.camera.cameraInUse else { return }
            self.agentEvents.ingest(agent: "Camera Guard", kind: .attention,
                                    message: "Camera is live right now — right-click to stop an app",
                                    urgent: true)
        }

        // camera guard: urgent banner the instant any app turns the camera on
        camera.$cameraInUse
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] live in
                guard let self else { return }
                if live, Pref.enabled(Pref.cameraGuard) {
                    // Block mode: quitting the app is the only real camera stop on macOS
                    if Pref.enabled(Pref.guardBlockMode),
                       let culprit = CameraAttribution.likelySuspects().first {
                        culprit.terminate()
                        self.agentEvents.ingest(
                            agent: "Camera Guard", kind: .attention,
                            message: "Blocked: quit \(culprit.localizedName ?? "the app") to stop the camera",
                            urgent: true)
                    } else {
                        self.agentEvents.ingest(agent: "Camera Guard", kind: .attention,
                                                message: "Your camera just went live",
                                                urgent: true)
                    }
                } else if !live {
                    self.agentEvents.dismissAll(agent: "Camera Guard")
                }
            }
            .store(in: &cancellables)
        audio.$isMuted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] muted in
                self?.statusItem?.button?.image = NSImage(
                    systemSymbolName: muted ? "mic.slash.circle.fill" : "mic.circle",
                    accessibilityDescription: "NotchControls")
            }
            .store(in: &cancellables)
    }

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "mic.circle",
                                     accessibilityDescription: "NotchControls")
        let menu = NSMenu()
        menu.delegate = self
        let mute = NSMenuItem(title: "Mute Microphone",
                              action: #selector(toggleMuteAction), keyEquivalent: "")
        mute.target = self
        menu.addItem(mute)
        muteMenuItem = mute

        let guardItem = NSMenuItem(title: "Camera Guard",
                                   action: #selector(toggleGuardAction), keyEquivalent: "")
        guardItem.target = self
        menu.addItem(guardItem)
        guardMenuItem = guardItem

        let prompter = NSMenuItem(title: "Toggle Teleprompter",
                                  action: #selector(toggleTeleprompterAction), keyEquivalent: "")
        prompter.target = self
        menu.addItem(prompter)

        menu.addItem(.separator())
        let settingsItem = NSMenuItem(title: "Settings…",
                                      action: #selector(openSettingsAction), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem(title: "Quit NotchControls",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }

    @objc private func toggleMuteAction() {
        audio.toggleMute()
    }

    @objc private func toggleTeleprompterAction() {
        teleprompter.toggle()
    }

    @objc private func toggleGuardAction() {
        UserDefaults.standard.set(!Pref.enabled(Pref.cameraGuard), forKey: Pref.cameraGuard)
    }

    @objc private func openSettingsAction() {
        settings.show()
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        muteMenuItem?.title = audio.isMuted ? "Unmute Microphone" : "Mute Microphone"
        muteMenuItem?.state = audio.isMuted ? .on : .off
        guardMenuItem?.title = Pref.enabled(Pref.cameraGuard) ? "Camera Guard (armed)" : "Camera Guard"
        guardMenuItem?.state = Pref.enabled(Pref.cameraGuard) ? .on : .off
    }
}
