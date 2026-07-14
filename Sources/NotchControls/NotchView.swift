import SwiftUI
import UniformTypeIdentifiers

struct NotchView: View {
    @ObservedObject var audio: AudioManager
    @ObservedObject var camera: CameraMonitor
    @ObservedObject var agentEvents: AgentEventCenter
    @ObservedObject var sessions: SessionMonitor
    @ObservedObject var shelf: ShelfStore
    @ObservedObject var state: NotchState
    @State private var dropTargeted = false
    let collapsedHeight: CGFloat
    let openTeleprompter: () -> Void
    let openSettings: () -> Void

    @AppStorage(Pref.cameraIndicator) private var cameraIndicator = true
    @AppStorage(Pref.showTeleprompter) private var showTeleprompter = true
    @AppStorage(Pref.showSessions) private var showSessions = true
    @AppStorage(Pref.projectColors) private var projectColors = true
    @AppStorage(Pref.subagentBadge) private var subagentBadge = true
    @AppStorage(Pref.fileShelf) private var fileShelf = true
    @AppStorage(Pref.cameraGuard) private var cameraGuard = false
    @AppStorage(Pref.showGuardButton) private var showGuardButton = true
    @AppStorage(Pref.showHistoryButton) private var showHistoryButton = true

    var body: some View {
        VStack(spacing: 0) {
            island
            Spacer(minLength: 0)
        }
    }

    private var island: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button(action: audio.toggleMute) {
                    Image(systemName: micSymbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(micColor)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .hoverGlow(6)
                .help(audio.isMuted ? "Unmute (⌥⇧M)" : "Mute (⌥⇧M)")
                if agentEvents.attentionCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .symbolEffect(.pulse, options: .repeating)
                        Text("\(agentEvents.attentionCount)")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(.orange)
                }
                Spacer()
                if cameraIndicator {
                    Button {
                        cameraGuard.toggle()
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: cameraGuard ? "video.badge.checkmark" : "video.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(camera.cameraInUse ? .green
                                                 : cameraGuard ? .orange : .white.opacity(0.25))
                            if cameraGuard {
                                // guard state stays visible even while the camera is live (green)
                                Circle().fill(.orange).frame(width: 5, height: 5).offset(x: 3, y: -2)
                            }
                        }
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .hoverGlow(6)
                    .help(cameraGuard
                          ? "Camera Guard ON — alerts the instant any app starts your camera"
                          : "Camera Guard off — click to arm (macOS can't force the camera off system-wide)")
                }
            }
            .padding(.horizontal, 16)
            .frame(height: collapsedHeight)

            if state.expanded {
                VStack(spacing: 12) {
                    if state.showHistory {
                        historyList
                    } else {
                        if !agentEvents.events.isEmpty {
                            eventList
                        }
                        if fileShelf, !shelf.items.isEmpty || dropTargeted {
                            shelfRow
                        }
                        if showSessions, !sessions.sessions.isEmpty {
                            sessionList
                        }
                    }
                    controls
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.18),
                           value: agentEvents.events)
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(bottomLeadingRadius: 18,
                                   bottomTrailingRadius: 18,
                                   style: .continuous)
                .fill(Color.black)
                .shadow(color: .black.opacity(state.expanded ? 0.45 : 0), radius: 12, y: 5)
        )
        .overlay(
            UnevenRoundedRectangle(bottomLeadingRadius: 18,
                                   bottomTrailingRadius: 18,
                                   style: .continuous)
                .strokeBorder(Color.orange.opacity(dropTargeted ? 0.8 : 0), lineWidth: 2)
                .allowsHitTesting(false)
        )
        .onHover { state.onHover($0) }
        .onDrop(of: [UTType.fileURL], isTargeted: fileShelf ? $dropTargeted : nil) { providers in
            let group = DispatchGroup()
            var dropped: [URL] = []
            for provider in providers {
                group.enter()
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url, url.isFileURL { dropped.append(url) }
                    group.leave()
                }
            }
            group.notify(queue: .main) { shelf.add(dropped) }
            return true
        }
        .onChange(of: dropTargeted) { _, targeted in
            if targeted { state.onHover(true) } // drag-hover opens the bay
        }
    }

    private var eventList: some View {
        VStack(spacing: 6) {
            ForEach(Array(agentEvents.events.prefix(3))) { event in
                HStack(spacing: 10) {
                    Button {
                        agentEvents.activate(event)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: event.kind == .attention
                                  ? "exclamationmark.bubble.fill" : "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(event.kind == .attention ? .orange : .green)
                            VStack(alignment: .leading, spacing: 1) {
                                HStack(spacing: 4) {
                                    Text(event.agent)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.9))
                                    if let dir = event.directoryName {
                                        Text(dir)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(event.kind == .attention ? .orange : .green)
                                            .lineLimit(1)
                                    }
                                }
                                Text(event.message)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .lineLimit(2)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Jump to this session")

                    Button {
                        agentEvents.dismiss(event.id)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .hoverGlow(6)
                    .help("Dismiss")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .hoverGlow(10)
                .contextMenu {
                    if event.agent == "Camera Guard" {
                        // quitting the app is the only real way to stop the camera on macOS
                        ForEach(CameraAttribution.likelySuspects(), id: \.processIdentifier) { app in
                            Button("Quit \(app.localizedName ?? "app") (stops the camera)") {
                                app.terminate()
                            }
                        }
                    }
                    if let dir = event.directory {
                        Button("Mute \(event.directoryName ?? "this project")") {
                            Pref.mute(project: dir)
                            for muted in agentEvents.events where muted.directory == dir {
                                agentEvents.dismiss(muted.id)
                            }
                        }
                    }
                }
            }
            if agentEvents.events.count > 3 {
                Text("+\(agentEvents.events.count - 3) more")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
    }

    /// Directories with a pending attention event — these sessions need the user.
    private var attentionDirs: Set<String> {
        Set(agentEvents.events.filter { $0.kind == .attention }.compactMap(\.directory))
    }

    /// Blocked sessions first, then newest.
    private var orderedSessions: [SessionMonitor.AgentSession] {
        let dirs = attentionDirs
        return sessions.sessions.sorted { a, b in
            let na = dirs.contains(a.directory), nb = dirs.contains(b.directory)
            if na != nb { return na }
            return (a.started ?? .distantPast) > (b.started ?? .distantPast)
        }
    }

    private var sessionList: some View {
        let dirs = attentionDirs
        let ordered = orderedSessions
        return VStack(spacing: 4) {
            if state.showAllSessions {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(ordered) { session in
                            sessionRow(session, needsYou: dirs.contains(session.directory))
                        }
                    }
                }
                .frame(maxHeight: 210)
            } else {
                ForEach(Array(ordered.prefix(3))) { session in
                    sessionRow(session, needsYou: dirs.contains(session.directory))
                }
            }
            if ordered.count > 3 {
                Button {
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
                        state.showAllSessions.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(state.showAllSessions
                             ? "Show less"
                             : "Show all \(ordered.count) sessions")
                        Image(systemName: state.showAllSessions ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .hoverGlow(6)
                .help(state.showAllSessions ? "Collapse the list" : "Expand to all sessions")
            }
        }
    }

    private func sessionRow(_ session: SessionMonitor.AgentSession, needsYou: Bool) -> some View {
        Button {
            sessions.focus(session)
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(needsYou ? Color.orange
                          : session.working ? Color.green : Color.white.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .help(needsYou ? "Needs your input"
                          : session.working ? "Working" : "Idle")
                Text(session.agent)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                Text(URL(fileURLWithPath: session.directory).lastPathComponent)
                    .font(.system(size: 11, weight: projectColors ? .semibold : .regular))
                    .foregroundStyle(projectColors
                                     ? Self.projectColor(session.directory)
                                     : Color.white.opacity(0.55))
                    .lineLimit(1)
                if subagentBadge, session.subagents > 0 {
                    Text("+\(session.subagents)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.white.opacity(0.12), in: Capsule())
                        .help("\(session.subagents) sub-process\(session.subagents == 1 ? "" : "es")")
                }
                Spacer()
                if needsYou {
                    Text("needs you")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15), in: Capsule())
                }
                Text(elapsed(session.started))
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.45))
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.05),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverGlow(8)
        .help("Jump to this session · right-click for more")
        .contextMenu {
            ForEach(SessionMonitor.availableEditors, id: \.bundleID) { editor in
                Button("Open in \(editor.name)") {
                    SessionMonitor.open(directory: session.directory, in: editor)
                }
            }
            Divider()
            Button("Reveal in Finder") {
                SessionMonitor.revealInFinder(session.directory)
            }
        }
    }

    private var shelfRow: some View {
        VStack(spacing: 4) {
            HStack {
                Text("SHELF")
                    .font(.system(size: 9, weight: .bold))
                    .kerning(1.1)
                    .foregroundStyle(.white.opacity(0.45))
                Spacer()
                if !shelf.items.isEmpty {
                    Button("Clear") { shelf.clear() }
                        .buttonStyle(.plain)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .hoverGlow(4)
                }
            }
            .padding(.horizontal, 2)
            if shelf.items.isEmpty {
                Text("Drop files here — drag them out anywhere later")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.vertical, 10)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(shelf.items, id: \.self) { url in
                            ShelfChip(url: url, store: shelf)
                        }
                    }
                }
            }
        }
    }

    private var historyList: some View {
        VStack(spacing: 4) {
            Text("RECENT ACTIVITY")
                .font(.system(size: 9, weight: .bold))
                .kerning(1.1)
                .foregroundStyle(.white.opacity(0.45))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 2)
            if agentEvents.history.isEmpty {
                Text("No agent events yet")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.vertical, 12)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(agentEvents.history) { event in
                            Button {
                                agentEvents.activate(event)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: event.kind == .attention
                                          ? "exclamationmark.bubble.fill" : "checkmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(event.kind == .attention ? .orange : .green)
                                    Text(event.directoryName ?? event.agent)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.85))
                                    Text(event.message)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.white.opacity(0.55))
                                        .lineLimit(1)
                                    Spacer()
                                    Text(timeAgo(event.date))
                                        .font(.system(size: 10))
                                        .foregroundStyle(.white.opacity(0.45))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.05),
                                            in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .hoverGlow(8)
                        }
                    }
                }
                .frame(maxHeight: 230)
            }
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        return "\(seconds / 3600)h ago"
    }

    /// Stable per-project hue so long session lists scan by color.
    private static func projectColor(_ path: String) -> Color {
        var hash: UInt64 = 5381
        for byte in path.utf8 { hash = (hash &* 33) &+ UInt64(byte) }
        return Color(hue: Double(hash % 360) / 360, saturation: 0.5, brightness: 0.9)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                islandButton(
                    title: audio.isMuted ? "Unmute" : "Mute",
                    symbol: audio.isMuted ? "mic.slash.fill" : "mic.fill",
                    tint: audio.isMuted ? Color.red : Color.white.opacity(0.14),
                    action: audio.toggleMute)
                if cameraIndicator, showGuardButton {
                    islandButton(
                        title: cameraGuard ? "Guarded" : "Guard",
                        symbol: cameraGuard ? "video.badge.checkmark" : "video",
                        tint: cameraGuard ? Color.orange.opacity(0.3) : Color.white.opacity(0.14),
                        action: { cameraGuard.toggle() })
                }
                if showTeleprompter {
                    islandButton(
                        title: "Prompter",
                        symbol: "text.viewfinder",
                        tint: Color.white.opacity(0.14),
                        action: openTeleprompter)
                }
            }
            HStack {
                Text(audio.deviceName)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
                Spacer()
                if cameraIndicator {
                    Label(camera.cameraInUse ? "Camera in use" : "Camera off",
                          systemImage: "video.fill")
                        .font(.caption)
                        .foregroundStyle(camera.cameraInUse ? .green : .white.opacity(0.5))
                    Text("·")
                        .foregroundStyle(.white.opacity(0.3))
                }
                Text(micStatusText)
                    .font(.caption)
                    .foregroundStyle(micColor)
                if showHistoryButton {
                Button {
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) {
                        state.showHistory.toggle()
                    }
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 11))
                        .foregroundStyle(state.showHistory ? .orange : .white.opacity(0.5))
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .hoverGlow(6)
                .help("Recent activity")
                }
                Button(action: openSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .hoverGlow(6)
                .help("Settings")
            }
        }
    }

    private func islandButton(title: String, symbol: String, tint: Color,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(tint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .foregroundStyle(.white)
        .hoverGlow(12)
    }

    private func elapsed(_ start: Date?) -> String {
        guard let start else { return "" }
        let seconds = Int(Date().timeIntervalSince(start))
        if seconds < 3600 { return "\(max(seconds / 60, 0))m" }
        if seconds < 86400 { return "\(seconds / 3600)h \((seconds % 3600) / 60)m" }
        return "\(seconds / 86400)d \((seconds % 86400) / 3600)h"
    }

    private var micSymbol: String {
        audio.isMuted ? "mic.slash.fill" : "mic.fill"
    }

    private var micColor: Color {
        if audio.isMuted { return .red }
        return audio.micInUse ? .orange : .white.opacity(0.4)
    }

    private var micStatusText: String {
        if audio.isMuted { return "Muted" }
        return audio.micInUse ? "Mic live" : "Mic idle"
    }
}
