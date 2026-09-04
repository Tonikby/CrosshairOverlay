public enum CursorVisibilityPolicy {
    public static func shouldHideCursor(
        crosshairVisible: Bool,
        hideCursorEnabled: Bool
    ) -> Bool {
        crosshairVisible && hideCursorEnabled
    }
}
