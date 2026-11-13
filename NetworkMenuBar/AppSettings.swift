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

    /// The language's name in itself, e.g. "Español", whatever language the app runs in.
    var nativeName: String {
        let locale = Locale(identifier: rawValue)
        return locale.localizedString(forIdentifier: rawValue)?.capitalized(with: locale) ?? rawValue
    }

    /// Overrides the app's language from the next launch on.
    func apply() {
        if self == .system {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([rawValue], forKey: "AppleLanguages")
        }
    }
}
