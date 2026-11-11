import NetworkMenuBarKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKey.menuLayout) private var layout: MenuLayout = .compact
    @AppStorage(SettingsKey.menuBarStyle) private var style: MenuBarStyle = .iconOnly
    @AppStorage(SettingsKey.menuBarText) private var textSource: MenuBarTextSource = .publicIP
    @AppStorage(SettingsKey.showNetworkIcons) private var showNetworkIcons = true
    @AppStorage(SettingsKey.language) private var language: AppLanguage = .system
    @State private var loginStatus = LaunchAtLogin.status

    var body: some View {
        TabView {
            general
                .tabItem { Label("General", systemImage: "gearshape") }
            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
    }

    private var launchAtLogin: Binding<Bool> {
        // Shown on while macOS waits for approval, so the note below explains why it isn't active yet.
        Binding {
            loginStatus == .enabled || loginStatus == .requiresApproval
        } set: { enabled in
            try? LaunchAtLogin.setEnabled(enabled)
            loginStatus = LaunchAtLogin.status
        }
    }

    private var general: some View {
        Form {
            Section {
                Picker("Menu layout", selection: $layout) {
                    Text("Compact").tag(MenuLayout.compact)
                    Text("Detailed").tag(MenuLayout.detailed)
                }
                Toggle("Show network icons", isOn: $showNetworkIcons)
                Picker("Menu bar", selection: $style) {
                    Text("Icon only").tag(MenuBarStyle.iconOnly)
                    Text("Icon and text").tag(MenuBarStyle.iconAndText)
                }
                Picker("Menu bar text", selection: $textSource) {
                    Text("Public IP").tag(MenuBarTextSource.publicIP)
                    Text("Private IP").tag(MenuBarTextSource.privateIP)
                }
                .disabled(style == .iconOnly)
            }
            Section {
                Toggle("Launch at login", isOn: launchAtLogin)
                if loginStatus == .requiresApproval {
                    HStack {
                        Text("Waiting for approval in System Settings.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Open…") { SMAppService.openSystemSettingsLoginItems() }
                    }
                }
                Picker("Language", selection: $language) {
                    Text("System").tag(AppLanguage.system)
                    Text(verbatim: "English").tag(AppLanguage.english)
                    Text(verbatim: "Español").tag(AppLanguage.spanish)
                }
                .onChange(of: language) { _, language in language.apply() }
            } footer: {
                Text("Language changes take effect after restarting Network Menu Bar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear { loginStatus = LaunchAtLogin.status }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            loginStatus = LaunchAtLogin.status
        }
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
    }
}
