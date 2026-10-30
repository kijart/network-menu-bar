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
    static let language = "language"
}
