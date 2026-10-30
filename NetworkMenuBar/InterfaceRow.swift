import NetworkMenuBarKit
import SwiftUI

struct InterfaceRow: View {
    let interface: NetworkInterfaceInfo
    let layout: MenuLayout
    @State private var copied = false

    var body: some View {
        Button(action: copy) {
            HStack(spacing: 8) {
                Circle()
                    .fill(interface.isActive ? Color.green : Color.secondary.opacity(0.4))
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 1) {
                    Text(interface.title)
                        .foregroundStyle(interface.isActive ? .primary : .secondary)
                    if layout == .detailed {
                        Text(interface.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                Spacer(minLength: 12)
                if copied {
                    Label("Copied", systemImage: "checkmark")
                        .foregroundStyle(.secondary)
                } else {
                    Text(interface.ipv4 ?? "—")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(interface.isActive ? .primary : .secondary)
                        .fixedSize()
                }
            }
        }
        .disabled(!interface.isActive)
    }

    private func copy() {
        guard let ipv4 = interface.ipv4 else { return }
        Clipboard.copy(ipv4)
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(1))
            copied = false
        }
    }
}
