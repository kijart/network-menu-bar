import NetworkMenuBarKit
import SwiftUI

struct MenuBarLabel: View {
    let monitor: NetworkMonitor
    @AppStorage(SettingsKey.menuBarStyle) private var style: MenuBarStyle = .iconOnly
    @AppStorage(SettingsKey.menuBarText) private var textSource: MenuBarTextSource = .publicIP

    var body: some View {
        if style == .iconAndText, let text {
            Label(text, systemImage: monitor.connection.symbolName)
                .labelStyle(.titleAndIcon)
        } else {
            Image(systemName: monitor.connection.symbolName)
        }
    }

    private var text: String? {
        menuBarText(
            source: textSource,
            interfaces: monitor.interfaces,
            primaryInterface: monitor.primaryInterface,
            publicIP: monitor.publicIP
        )
    }
}
