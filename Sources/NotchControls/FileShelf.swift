import AppKit
import Combine
import SwiftUI
import UniformTypeIdentifiers

/// Drop files onto the notch, stash them, drag them out anywhere later.
final class ShelfStore: ObservableObject {
    @Published private(set) var items: [URL] = []

    private static let key = "shelf.paths"
    private static let cap = 8

    init() {
        let paths = UserDefaults.standard.stringArray(forKey: Self.key) ?? []
        items = paths.map(URL.init(fileURLWithPath:))
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    func add(_ urls: [URL]) {
        var next = items
        for url in urls where !next.contains(url) {
            next.insert(url, at: 0)
        }
        if next.count > Self.cap { next.removeLast(next.count - Self.cap) }
        items = next
        persist()
    }

    func remove(_ url: URL) {
        items.removeAll { $0 == url }
        persist()
    }

    func clear() {
        items = []
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(items.map(\.path), forKey: Self.key)
    }
}

struct ShelfChip: View {
    let url: URL
    let store: ShelfStore

    var body: some View {
        VStack(spacing: 3) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .frame(width: 34, height: 34)
            Text(url.lastPathComponent)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
                .frame(maxWidth: 74)
        }
        .padding(6)
        .background(Color.white.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .hoverGlow(9)
        .onDrag { NSItemProvider(contentsOf: url) ?? NSItemProvider() }
        .contextMenu {
            Button("Remove from shelf") { store.remove(url) }
            Button("Reveal in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        }
        .help("Drag out to drop anywhere · right-click for options")
    }
}
