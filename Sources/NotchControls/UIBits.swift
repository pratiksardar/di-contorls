import AppKit
import SwiftUI

/// Hover feedback for island controls: a soft white wash over the element.
/// Product rule: everything clickable shows a hover state.
struct HoverGlow: ViewModifier {
    var radius: CGFloat
    @State private var hovered = false

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.white.opacity(hovered ? 0.08 : 0))
                    .allowsHitTesting(false)
            )
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: hovered)
            .onHover { hovered = $0 }
    }
}

extension View {
    func hoverGlow(_ radius: CGFloat = 10) -> some View {
        modifier(HoverGlow(radius: radius))
    }
}

var reduceMotion: Bool {
    NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
}
