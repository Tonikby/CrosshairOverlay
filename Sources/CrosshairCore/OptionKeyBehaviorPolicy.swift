public enum OptionKeyBehavior: String, CaseIterable, Codable, Equatable, Sendable {
    case showCrosshair
    case toggleNativeCursor

    public var title: String {
        switch self {
        case .showCrosshair: "Hold Option to Show Crosshair"
        case .toggleNativeCursor: "Hold Option to Toggle Native Cursor"
        }
    }
}

public enum OptionKeyBehaviorPolicy {
    public static func shouldShowCrosshair(
        behavior: OptionKeyBehavior,
        isOptionPressed: Bool
    ) -> Bool {
        behavior != .showCrosshair || isOptionPressed
    }

    public static func shouldHideNativeCursor(
        crosshairVisible: Bool,
        hideCursorEnabled: Bool,
        behavior: OptionKeyBehavior,
        isOptionPressed: Bool
    ) -> Bool {
        guard crosshairVisible else { return false }
        switch behavior {
        case .showCrosshair:
            return hideCursorEnabled && isOptionPressed
        case .toggleNativeCursor:
            return isOptionPressed ? !hideCursorEnabled : hideCursorEnabled
        }
    }
}
