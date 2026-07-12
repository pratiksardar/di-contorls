import SwiftUI
import UniformTypeIdentifiers

struct TeleprompterView: View {
    @AppStorage("teleprompter.script") private var script = ""
    @AppStorage("teleprompter.speed") private var speed = 40.0
    @AppStorage("teleprompter.fontSize") private var fontSize = 28.0
    @AppStorage("teleprompter.fontDesign") private var fontDesignRaw = "rounded"

    @State private var playing = false
    @State private var offset: CGFloat = 0
    @State private var textHeight: CGFloat = 0
    @State private var dragBase: CGFloat?
    @State private var importing = false
    @Environment(\.colorScheme) private var scheme

    private let tick = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    private var progress: CGFloat {
        textHeight > 0 ? min(max(offset / textHeight, 0), 1) : 0
    }

    // theme-aware palette; window appearance is driven by the Appearance setting
    private var ink: Color { scheme == .dark ? .white : .black }
    private var paper: Color { scheme == .dark ? .black : .white }
    private var scriptIsEmpty: Bool {
        script.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var fontDesign: Font.Design {
        switch fontDesignRaw {
        case "serif": return .serif
        case "mono": return .monospaced
        case "plain": return .default
        default: return .rounded
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            content
            progressBar
            controls
        }
        .background(.ultraThinMaterial)
        .background(paper.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ink.opacity(0.12), lineWidth: 1)
        )
        .onReceive(tick) { _ in
            guard playing else { return }
            offset += CGFloat(speed) / 60
            if textHeight > 0, offset > textHeight {
                playing = false
            }
        }
    }

    // MARK: - Prompter / editor

    private var content: some View {
        Group {
            if playing {
                prompter
            } else {
                editor
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var prompter: some View {
        GeometryReader { geo in
            let focalY = geo.size.height * 0.22
            let column = min(geo.size.width - 72, 640)

            ZStack(alignment: .topLeading) {
                Text(script)
                    .font(.system(size: fontSize, weight: .medium, design: fontDesign))
                    .lineSpacing(fontSize * 0.4)
                    .foregroundStyle(ink)
                    .frame(width: column, alignment: .leading)
                    .background(
                        GeometryReader { text in
                            Color.clear
                                .onAppear { textHeight = text.size.height }
                                .onChange(of: text.size.height) { _, new in textHeight = new }
                        }
                    )
                    .offset(x: (geo.size.width - column) / 2, y: focalY - offset)

                // reading guide at the focal line
                HStack(spacing: 6) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.orange)
                    Rectangle()
                        .fill(LinearGradient(colors: [.orange.opacity(0.35), .clear],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(height: 1)
                }
                .padding(.leading, 10)
                .offset(y: focalY + fontSize * 0.7)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .clipped()
            .mask(
                LinearGradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.1),
                    .init(color: .black, location: 0.82),
                    .init(color: .clear, location: 1),
                ], startPoint: .top, endPoint: .bottom)
            )
        }
        .contentShape(Rectangle())
        .onTapGesture { playing = false }
        // drag to scrub / catch up mid-read; auto-scroll resumes from the new spot
        .gesture(
            DragGesture()
                .onChanged { value in
                    if dragBase == nil { dragBase = offset }
                    offset = max(0, min(textHeight, (dragBase ?? 0) - value.translation.height))
                }
                .onEnded { _ in dragBase = nil }
        )
        .onChange(of: textHeight) { _, new in
            offset = min(offset, max(new, 0)) // window resize reflows text — stay in bounds
        }
    }

    /// Live remote keys while playing: ↑/↓ speed, ←/→ jump back/forward.
    private var playbackShortcuts: some View {
        Group {
            Button("") { speed = min(150, speed + 10) }
                .keyboardShortcut(.upArrow, modifiers: [])
            Button("") { speed = max(10, speed - 10) }
                .keyboardShortcut(.downArrow, modifiers: [])
            Button("") { offset = max(0, offset - 250) }
                .keyboardShortcut(.leftArrow, modifiers: [])
            Button("") { offset = min(textHeight, offset + 250) }
                .keyboardShortcut(.rightArrow, modifiers: [])
        }
        .buttonStyle(.plain)
        .frame(width: 0, height: 0)
        .opacity(0)
        .accessibilityHidden(true)
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SCRIPT")
                .font(.system(size: 10, weight: .bold))
                .kerning(1.2)
                .foregroundStyle(ink.opacity(0.5))
                .padding(.horizontal, 6)
            TextEditor(text: $script)
                .font(.system(size: 16))
                .lineSpacing(5)
                .scrollContentBackground(.hidden)
                .foregroundStyle(ink.opacity(0.95))
                .overlay(alignment: .topLeading) {
                    if script.isEmpty {
                        Text("Paste or type your script, then press play (space)")
                            .font(.system(size: 16))
                            .foregroundStyle(ink.opacity(0.45))
                            .padding(.top, 1)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }
        }
        .padding(.horizontal, 18)
        .padding(.top, 30)
        .padding(.bottom, 8)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(Color.orange.opacity(0.9))
                .frame(width: geo.size.width * progress)
        }
        .frame(height: playing ? 2 : 0)
        .background(ink.opacity(0.08))
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 16) {
            Button {
                playing.toggle()
            } label: {
                Image(systemName: playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(paper)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(ink.opacity(scriptIsEmpty ? 0.35 : 1)))
                    .contentShape(Circle())
            }
            .keyboardShortcut(.space, modifiers: [])
            .disabled(scriptIsEmpty)
            .hoverGlow(17)
            .help(playing ? "Pause (space)" : "Play (space)")

            Button {
                offset = 0
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            .hoverGlow(6)
            .help("Restart from top")

            slider(icon: "hare.fill", value: $speed, range: 10...150, width: 100)
                .help("Scroll speed (↑/↓ while playing)")
            slider(icon: "textformat.size", value: $fontSize, range: 16...60, width: 80)
                .help("Font size")

            Menu {
                Picker("Font style", selection: $fontDesignRaw) {
                    Text("Rounded").tag("rounded")
                    Text("Standard").tag("plain")
                    Text("Serif").tag("serif")
                    Text("Monospaced").tag("mono")
                }
            } label: {
                Image(systemName: "textformat")
                    .font(.system(size: 11))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(width: 24)
            .hoverGlow(6)
            .help("Font style")

            Button {
                importing = true
            } label: {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 11))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .hoverGlow(6)
            .help("Import script (.md, .txt)")

            Spacer()

            Text(playing ? "Drag to scrub · ↑↓ speed · ←→ jump · space pause"
                         : "Space to play")
                .font(.system(size: 10))
                .foregroundStyle(ink.opacity(0.5))

            if playing { playbackShortcuts }
        }
        .fileImporter(isPresented: $importing,
                      allowedContentTypes: [.plainText, .text]) { result in
            if let url = try? result.get(),
               let text = try? String(contentsOf: url, encoding: .utf8) {
                script = text
                offset = 0
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(ink.opacity(0.85))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(paper.opacity(0.35))
    }

    private func slider(icon: String, value: Binding<Double>,
                        range: ClosedRange<Double>, width: CGFloat) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(ink.opacity(0.5))
            Slider(value: value, in: range)
                .controlSize(.mini)
                .frame(width: width)
        }
    }
}
