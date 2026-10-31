import NetworkMenuBarKit
import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKey.menuLayout) private var layout: MenuLayout = .compact
    @AppStorage(SettingsKey.menuBarStyle) private var style: MenuBarStyle = .iconOnly
    @AppStorage(SettingsKey.menuBarText) private var textSource: MenuBarTextSource = .publicIP
    @AppStorage(SettingsKey.showNetworkIcons) private var showNetworkIcons = true
    @AppStorage(SettingsKey.language) private var language: AppLanguage = .system
    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
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
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        guard enabled != LaunchAtLogin.isEnabled else { return }
                        try? LaunchAtLogin.setEnabled(enabled)
                        launchAtLogin = LaunchAtLogin.isEnabled
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
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
    }
}
