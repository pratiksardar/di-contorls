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
    private var hotKey: HotKey?
    private var cancellables = Set<AnyCancellable>()

    private let agentEvents = AgentEventCenter()
    private let sessions = SessionMonitor()
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
            openTeleprompter: { [weak self] in self?.teleprompter.toggle() },
            openSettings: { [weak self] in self?.settings.show() })
        setUpStatusItem()
        hotKey = HotKey(keyCode: UInt32(kVK_ANSI_M),
                        modifiers: UInt32(optionKey | shiftKey)) { [weak self] in
            self?.audio.toggleMute()
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

    @objc private func openSettingsAction() {
        settings.show()
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        muteMenuItem?.title = audio.isMuted ? "Unmute Microphone" : "Mute Microphone"
        muteMenuItem?.state = audio.isMuted ? .on : .off
    }
}
