public enum OverlayWindowLevelPolicy {
    // CGWindowLevelForKey(.screenSaverWindow): above status and pop-up menus.
    public static let alwaysOnTopRawValue = 1000

    // NSWindow.Level.floating: below the overlay so its lines remain visible.
    public static let settingsWindowRawValue = 3
}
