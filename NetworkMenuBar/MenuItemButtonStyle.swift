import SwiftUI

/// A full-width, menu-like row that highlights on hover.
struct MenuItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        MenuItem(label: configuration.label, isPressed: configuration.isPressed)
    }

    private struct MenuItem<Label: View>: View {
        let label: Label
        let isPressed: Bool
        @Environment(\.isEnabled) private var isEnabled
        @State private var isHovered = false

        var body: some View {
            label
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.primary.opacity(highlightOpacity))
                )
                .contentShape(Rectangle())
                .onHover { isHovered = $0 }
        }

        private var highlightOpacity: Double {
            guard isEnabled else { return 0 }
            return isPressed ? 0.15 : isHovered ? 0.08 : 0
        }
    }
}
