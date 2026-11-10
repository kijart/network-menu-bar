import NetworkMenuBarKit
import SwiftUI

struct InterfaceRow: View {
    let interface: NetworkInterfaceInfo
    let title: String
    let layout: MenuLayout
    @AppStorage(SettingsKey.showNetworkIcons) private var showNetworkIcons = true
    @State private var copied = false

    var body: some View {
        Button(action: copy) {
            HStack(spacing: 8) {
                Circle()
                    .fill(interface.isActive ? Color.green : Color.secondary.opacity(0.4))
                    .frame(width: 8, height: 8)
                if showNetworkIcons {
                    Image(systemName: interface.kind.symbolName)
                        .foregroundStyle(interface.isActive ? .primary : .secondary)
                        .frame(width: 16)
                        .accessibilityLabel(String(localized: "VPN"))
                        .accessibilityHidden(interface.kind != .vpn)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .foregroundStyle(interface.isActive ? .primary : .secondary)
                        .lineLimit(1)
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
