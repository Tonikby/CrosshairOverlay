import Cocoa
import CrosshairCore

final class SettingsStore: @unchecked Sendable {
    static let shared = SettingsStore()

    // Properties for reactive updates
    var crosshairColor: NSColor = NSColor.green
    var lineWidth: CGFloat = 1.0
    var pattern: LinePattern = .dashed
    var isVisible: Bool = true
    var showDot: Bool = true
    var intersectionShape: IntersectionShape = .cross
    var dotColor: NSColor = NSColor.green
    var dotShadeColor: NSColor = NSColor.black
    var showDotShade: Bool = true
    var hideNativeCursor: Bool = true

    var shouldHideNativeCursor: Bool {
        CursorVisibilityPolicy.shouldHideCursor(
            crosshairVisible: isVisible,
            hideCursorEnabled: hideNativeCursor
        )
    }

    var dotShadeCGColor: CGColor {
        showDotShade ? dotShadeColor.cgColor : NSColor.clear.cgColor
    }

    enum IntersectionShape: String {
        case circle, sniperAim, cross, plus, diamond

        var description: String {
            switch self {
            case .circle: return "Circle"
            case .sniperAim: return "Sniper Aim"
            case .cross: return "Cross"
            case .plus: return "Plus"
            case .diamond: return "Diamond"
            }
        }
    }

    var dotColors: [NSColor] { colors }

    var dotColorNames: [String] { ColorPalette.names }

    enum LinePattern {
        case solid, dashed, dotted

        static func from(description: String) -> LinePattern? {
            switch description {
            case "Solid": return .solid
            case "Dashed": return .dashed
            case "Dotted": return .dotted
            default: return nil
            }
        }

        var description: String {
            switch self {
            case .solid: return "Solid"
            case .dashed: return "Dashed"
            case .dotted: return "Dotted"
            }
        }
    }

    let colors: [NSColor] = [
        NSColor.black,
        NSColor.white,
        NSColor.red,
        NSColor.orange,
        NSColor.yellow,
        NSColor.green,
        NSColor.cyan,
        NSColor.blue,
        NSColor.purple,
        NSColor.magenta
    ]

    let widths: [CGFloat] = [1.0, 2.0, 3.0, 4.0, 5.0]

    var colorNames: [String] { ColorPalette.names }

    private let savedSettingsKey = "CrosshairOverlay.savedSettings"

    func save() {
        let values: [String: Any] = [
            "crosshairColor": archive(crosshairColor),
            "lineWidth": Double(lineWidth),
            "pattern": pattern.description,
            "isVisible": isVisible,
            "showDot": showDot,
            "intersectionShape": intersectionShape.rawValue,
            "dotColor": archive(dotColor),
            "dotShadeColor": archive(dotShadeColor),
            "showDotShade": showDotShade,
            "hideNativeCursor": hideNativeCursor
        ]
        UserDefaults.standard.set(values, forKey: savedSettingsKey)
    }

    @discardableResult
    func restore() -> Bool {
        guard let values = UserDefaults.standard.dictionary(forKey: savedSettingsKey) else { return false }
        if let data = values["crosshairColor"] as? Data, let color = unarchive(data) { crosshairColor = color }
        if let value = values["lineWidth"] as? Double {
            lineWidth = CGFloat(LineWidthPolicy.restoredWidth(value, fallback: Double(lineWidth)))
        }
        if let value = values["pattern"] as? String { pattern = LinePattern.from(description: value) ?? pattern }
        if let value = values["isVisible"] as? Bool { isVisible = value }
        if let value = values["showDot"] as? Bool { showDot = value }
        if let value = values["intersectionShape"] as? String { intersectionShape = IntersectionShape(rawValue: value) ?? intersectionShape }
        if let data = values["dotColor"] as? Data, let color = unarchive(data) { dotColor = color }
        if let data = values["dotShadeColor"] as? Data, let color = unarchive(data) { dotShadeColor = color }
        if let value = values["showDotShade"] as? Bool { showDotShade = value }
        if let value = values["hideNativeCursor"] as? Bool { hideNativeCursor = value }
        return true
    }

    private func archive(_ color: NSColor) -> Data {
        (try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)) ?? Data()
    }

    private func unarchive(_ data: Data) -> NSColor? {
        try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
    }
}
