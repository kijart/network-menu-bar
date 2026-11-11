import NetworkMenuBarKit
import SwiftUI

struct MenuContentView: View {
    let monitor: NetworkMonitor
    @AppStorage(SettingsKey.menuLayout) private var layout: MenuLayout = .compact
    @Environment(\.openSettings) private var openSettings
    @State private var publicIPCopied = false

    var body: some View {
        ClampedWidth(range: 280...400) {
            content
        }
        .onAppear { monitor.reloadInterfaces() }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            publicIPHeader
            Divider().padding(.vertical, 4)
            ForEach(monitor.interfaces) { interface in
                InterfaceRow(interface: interface, title: interface.title(among: monitor.interfaces), layout: layout)
            }
            Divider().padding(.vertical, 4)
            footer
        }
        .buttonStyle(MenuItemButtonStyle())
        .padding(6)
    }

    private var publicIPHeader: some View {
        Button(action: copyPublicIP) {
            VStack(alignment: .leading, spacing: 2) {
                Text(publicIPCopied ? "Copied" : "Public IP")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let address = monitor.publicIP.address {
                    Text(address)
                        .font(.system(.title3, design: .monospaced).weight(.semibold))
                        .opacity(isLoading ? 0.5 : 1)
                } else {
                    Text(isLoading ? LocalizedStringKey("…") : "Unavailable")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                if layout == .detailed, let via = monitor.viaInterface {
                    Text("via \(via.title(among: monitor.interfaces))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .disabled(monitor.publicIP.address == nil)
    }

    private var footer: some View {
        Group {
            Button { monitor.refresh() } label: { shortcutLabel("Refresh", shortcut: "⌘R") }
                .keyboardShortcut("r")
            Button {
                NSApp.activate()
                openSettings()
            } label: { shortcutLabel("Settings…", shortcut: "⌘,") }
                .keyboardShortcut(",")
            Button { NSApp.terminate(nil) } label: { shortcutLabel("Quit Network Menu Bar", shortcut: "⌘Q") }
                .keyboardShortcut("q")
        }
    }

    private func shortcutLabel(_ title: LocalizedStringKey, shortcut: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(shortcut).foregroundStyle(.secondary)
        }
    }

    private var isLoading: Bool {
        if case .loading = monitor.publicIP { true } else { false }
    }

    private func copyPublicIP() {
        guard let address = monitor.publicIP.address else { return }
        Clipboard.copy(address)
        publicIPCopied = true
        Task {
            try? await Task.sleep(for: .seconds(1))
            publicIPCopied = false
        }
    }
}
