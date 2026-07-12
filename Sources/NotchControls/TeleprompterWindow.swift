import AppKit
import SwiftUI

/// Floating always-on-top teleprompter panel, positioned just under the
/// notch/camera so reading keeps eyes near the lens. Stays above Meet/Zoom.
final class TeleprompterController {
    private lazy var panel: NSPanel = makePanel()

    func toggle() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            // invisible in screen shares/recordings so the audience never sees the script
            panel.sharingType = Pref.enabled(Pref.hidePrompterFromCapture) ? .none : .readOnly
            position()
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKeyAndOrderFront(nil)
            panel.orderFrontRegardless()
        }
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 360),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        panel.title = "Teleprompter"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.minSize = NSSize(width: 360, height: 220)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        let hosting = NSHostingView(rootView: TeleprompterView())
        hosting.sizingOptions = [] // don't let SwiftUI pin window min/max — keeps panel resizable
        panel.contentView = hosting
        return panel
    }

    private func position() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let frame = panel.frame
        let top = NSPoint(x: screen.visibleFrame.midX - frame.width / 2,
                          y: screen.visibleFrame.maxY - 8)
        panel.setFrameTopLeftPoint(top)
    }
}
