public enum SettingsTab: CaseIterable, Sendable {
    case general
    case appearance
    case reticle
    case behavior
    case profiles
    case about

    public var title: String {
        switch self {
        case .general: "General"
        case .appearance: "Appearance"
        case .reticle: "Reticle"
        case .behavior: "Behavior"
        case .profiles: "Profiles"
        case .about: "About"
        }
    }

    public var symbolName: String {
        switch self {
        case .general: "power"
        case .appearance: "paintbrush"
        case .reticle: "scope"
        case .behavior: "cursorarrow"
        case .profiles: "slider.horizontal.3"
        case .about: "info.circle"
        }
    }
}
