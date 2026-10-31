import Foundation

enum MenuLayout: String, CaseIterable {
    case compact
    case detailed
}

enum MenuBarStyle: String, CaseIterable {
    case iconOnly
    case iconAndText
}

enum SettingsKey {
    static let menuLayout = "menuLayout"
    static let menuBarStyle = "menuBarStyle"
    static let menuBarText = "menuBarText"
    static let showNetworkIcons = "showNetworkIcons"
    static let language = "language"
}

enum AppLanguage: String, CaseIterable {
    case system
    case english = "en"
    case spanish = "es"

    /// Overrides the app's language from the next launch on.
    func apply() {
        if self == .system {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([rawValue], forKey: "AppleLanguages")
        }
    }
}
