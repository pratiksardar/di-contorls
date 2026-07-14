import AppKit
import Combine
import SwiftUI

/// Borderless, non-activating panel pinned over the notch area.
final class NotchPanel: NSPanel {
    init() {
        super.init(contentRect: .zero,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        isFloatingPanel = true
        level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        isMovable = false
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = true
        acceptsMouseMovedEvents = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
    }

    // Non-activating + can-become-key is the load-bearing combo: the panel takes
    // clicks (SwiftUI buttons need key-capable windows) WITHOUT activating the
    // app or stealing focus from the user's meeting.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// The island never becomes key, so without this the FIRST click on any
/// control is swallowed by window-activation handling — buttons feel dead.
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

final class NotchState: ObservableObject {
    @Published var expanded = false
    @Published var showAllSessions = false
    @Published var showHistory = false
    var onHover: (Bool) -> Void = { _ in }
}

/// Owns the notch panel: positioning, hover expand/collapse.
final class NotchController {
    private let panel = NotchPanel()
    private let state = NotchState()
    private var collapseWork: DispatchWorkItem?
    private var bannerWork: DispatchWorkItem?
    private var collapsedSize: CGSize

    /// User-selected island scale (Settings → Island size).
    private struct SizeSpec {
        let extraWidth: CGFloat // beyond the physical notch, collapsed
        let expanded: CGSize
        let tall: CGSize
    }

    private var sizeSpec: SizeSpec {
        switch UserDefaults.standard.string(forKey: Pref.islandSize) {
        case "compact": return SizeSpec(extraWidth: 60, expanded: CGSize(width: 380, height: 370),
                                        tall: CGSize(width: 380, height: 510))
        case "roomy": return SizeSpec(extraWidth: 150, expanded: CGSize(width: 490, height: 480),
                                      tall: CGSize(width: 490, height: 660))
        default: return SizeSpec(extraWidth: 96, expanded: CGSize(width: 420, height: 420),
                                 tall: CGSize(width: 420, height: 580))
        }
    }

    private var expandedSize: CGSize { sizeSpec.expanded }
    private var tallSize: CGSize { sizeSpec.tall }
    private var hovering = false
    private var cancellables = Set<AnyCancellable>()
    private let agentEvents: AgentEventCenter

    init(audio: AudioManager, camera: CameraMonitor, agentEvents: AgentEventCenter,
         sessions: SessionMonitor, shelf: ShelfStore,
         openTeleprompter: @escaping () -> Void,
         openSettings: @escaping () -> Void) {
        self.agentEvents = agentEvents
        collapsedSize = Self.collapsedSize(for: Self.targetScreen(), extra: 96)
        let root = NotchView(audio: audio,
                             camera: camera,
                             agentEvents: agentEvents,
                             sessions: sessions,
                             shelf: shelf,
                             state: state,
                             collapsedHeight: collapsedSize.height,
                             openTeleprompter: openTeleprompter,
                             openSettings: openSettings)
        let hosting = FirstMouseHostingView(rootView: root)
        hosting.sizingOptions = [] // window frame is managed by applyFrame, not SwiftUI
        panel.contentView = hosting
        state.onHover = { [weak self] hovering in self?.setHover(hovering) }
        applyFrame(expanded: false, animate: false)
        panel.orderFrontRegardless()

        // "+N more sessions" toggles the tall frame while expanded
        state.$showAllSessions
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, self.state.expanded else { return }
                self.applyFrame(expanded: true, animate: false)
            }
            .store(in: &cancellables)

        // new agent event → pop the island open like a live activity, collapse after 8s
        agentEvents.$events
            .receive(on: DispatchQueue.main)
            .scan(([], []) as ([AgentEventCenter.AgentEvent], [AgentEventCenter.AgentEvent])) { ($0.1, $1) }
            .sink { [weak self] previous, current in
                guard let self, let newest = current.first,
                      !previous.contains(newest) else { return }
                self.popOpen(force: newest.urgent)
            }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.collapsedSize = Self.collapsedSize(for: Self.targetScreen(), extra: self.sizeSpec.extraWidth)
            self.applyFrame(expanded: self.state.expanded, animate: false)
        }
    }

    /// Honors macOS Reduce Motion: crossfade-fast instead of spring.
    private static var expandAnimation: Animation {
        reduceMotion ? .linear(duration: 0.05) : .spring(response: 0.3, dampingFraction: 0.8)
    }

    private static var collapseAnimation: Animation {
        reduceMotion ? .linear(duration: 0.05) : .easeOut(duration: 0.15)
    }

    /// Expand without hover (agent banner), then auto-collapse unless the user moved in.
    private func popOpen(force: Bool = false) {
        guard force || (Pref.enabled(Pref.autoExpand) && !agentEvents.suppressPopups()) else { return }
        bannerWork?.cancel()
        applyFrame(expanded: true, animate: false)
        withAnimation(Self.expandAnimation) {
            state.expanded = true
        }
        let work = DispatchWorkItem { [weak self] in
            guard let self, !self.hovering else { return }
            self.setHover(false)
        }
        bannerWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: work)
    }

    private func setHover(_ hovering: Bool) {
        self.hovering = hovering
        collapseWork?.cancel()
        collapseWork = nil
        if hovering {
            applyFrame(expanded: true, animate: false)
            withAnimation(Self.expandAnimation) {
                state.expanded = true
            }
        } else {
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                withAnimation(Self.collapseAnimation) { self.state.expanded = false }
                self.state.showAllSessions = false // back to compact next open
                self.state.showHistory = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
                    guard let self, !self.state.expanded else { return }
                    self.applyFrame(expanded: false, animate: false)
                }
            }
            collapseWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
        }
    }

    private func applyFrame(expanded: Bool, animate: Bool) {
        guard let screen = Self.targetScreen() else { return }
        collapsedSize = Self.collapsedSize(for: screen, extra: sizeSpec.extraWidth)
        let size = expanded ? (state.showAllSessions ? tallSize : expandedSize) : collapsedSize
        let rect = NSRect(x: screen.frame.midX - size.width / 2,
                          y: screen.frame.maxY - size.height,
                          width: size.width,
                          height: size.height)
        panel.setFrame(rect, display: true, animate: animate)
    }

    private static func targetScreen() -> NSScreen? {
        NSScreen.screens.first { $0.safeAreaInsets.top > 0 } ?? NSScreen.main ?? NSScreen.screens.first
    }

    private static func collapsedSize(for screen: NSScreen?, extra: CGFloat) -> CGSize {
        guard let screen else { return CGSize(width: 184 + extra, height: 32) }
        let inset = screen.safeAreaInsets.top
        if inset > 0, let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            // wider than the physical notch so the indicators peek out at the sides
            let notchWidth = screen.frame.width - left.width - right.width
            return CGSize(width: notchWidth + extra, height: inset)
        }
        return CGSize(width: 184 + extra, height: 32)
    }
}
