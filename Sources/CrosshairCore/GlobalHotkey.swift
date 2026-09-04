public enum GlobalHotkey: Equatable, Sendable {
    case toggleCrosshair
    case toggleNativeCursor

    public static func action(identifier: UInt32) -> GlobalHotkey? {
        switch identifier {
        case 1: return .toggleCrosshair
        case 2: return .toggleNativeCursor
        default: return nil
        }
    }

    public static func action(
        key: String,
        control: Bool,
        shift: Bool,
        command: Bool
    ) -> GlobalHotkey? {
        guard control && shift && command else { return nil }

        switch key.lowercased() {
        case "c": return .toggleCrosshair
        case "h": return .toggleNativeCursor
        default: return nil
        }
    }
}
