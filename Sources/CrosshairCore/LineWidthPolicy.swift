public enum LineWidthPolicy {
    public static func restoredWidth(_ value: Double, fallback: Double) -> Double {
        guard value.isFinite, (1...5).contains(value) else { return fallback }
        return value
    }
}
