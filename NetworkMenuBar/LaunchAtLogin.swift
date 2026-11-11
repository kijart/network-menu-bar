import Foundation
import ServiceManagement

enum LaunchAtLogin {
    private static let didApplyDefaultKey = "didApplyLaunchAtLoginDefault"

    static var status: SMAppService.Status {
        SMAppService.mainApp.status
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    /// Turns launch at login on once, the first time the app runs from an Applications folder,
    /// so development builds never register themselves.
    static func applyDefaultIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: didApplyDefaultKey), isInstalled else { return }
        defaults.set(true, forKey: didApplyDefaultKey)
        try? setEnabled(true)
    }

    private static var isInstalled: Bool {
        let path = Bundle.main.bundleURL.deletingLastPathComponent().path
        return path == "/Applications" || path == NSHomeDirectory() + "/Applications"
    }
}
