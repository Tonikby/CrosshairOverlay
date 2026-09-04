public enum GlobalHotkey: Equatable, Sendable {
    case toggleCrosshair
    case toggleNativeCursor
    case nextPreset
    case decreaseLineWidth
    case increaseLineWidth
    case decreaseOpacity
    case increaseOpacity

    public static func action(identifier: UInt32) -> GlobalHotkey? {
        switch identifier {
        case 1: return .toggleCrosshair
        case 2: return .toggleNativeCursor
        case 3: return .nextPreset
        case 4: return .decreaseLineWidth
        case 5: return .increaseLineWidth
        case 6: return .decreaseOpacity
        case 7: return .increaseOpacity
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
        case "p": return .nextPreset
        case "[": return .decreaseLineWidth
        case "]": return .increaseLineWidth
        case "-": return .decreaseOpacity
        case "=": return .increaseOpacity
        default: return nil
        }
    }
}
