import NetworkMenuBarKit
import SwiftUI

@main
struct NetworkMenuBarApp: App {
    @State private var monitor: NetworkMonitor

    init() {
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
            Text(verbatim: "Settings")
                .padding()
        }
    }
}
