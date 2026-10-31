import NetworkMenuBarKit
import SwiftUI

struct MenuBarLabel: View {
    let monitor: NetworkMonitor
    @AppStorage(SettingsKey.menuBarStyle) private var style: MenuBarStyle = .iconOnly
    @AppStorage(SettingsKey.menuBarText) private var textSource: MenuBarTextSource = .publicIP

    var body: some View {
        Group {
            if let text = shownText {
                Label { Text(text) } icon: { icon }
                    .labelStyle(.titleAndIcon)
            } else {
                icon
            }
        }
        .accessibilityLabel(Text(verbatim: "Network Menu Bar"))
        .accessibilityValue([monitor.connection.title, shownText].compactMap { $0 }.joined(separator: ", "))
    }

    private var icon: Image {
        Image(monitor.connection == .offline ? "MenuBarIconOffline" : "MenuBarIcon")
    }

    private var shownText: String? {
        guard style == .iconAndText else { return nil }
        return menuBarText(
            source: textSource,
            interfaces: monitor.interfaces,
            primaryInterface: monitor.primaryInterface,
            publicIP: monitor.publicIP
        )
    }
}
