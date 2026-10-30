import NetworkMenuBarKit
import SwiftUI

@main
struct NetworkMenuBarApp: App {
    @State private var monitor: NetworkMonitor

    init() {
        LaunchAtLogin.applyDefaultIfNeeded()
        let monitor = NetworkMonitor()
        monitor.start()
        _monitor = State(initialValue: monitor)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(monitor: monitor)
        } label: {
            MenuBarLabel(monitor: monitor)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
