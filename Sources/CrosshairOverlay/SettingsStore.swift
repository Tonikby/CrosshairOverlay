import Cocoa
import Quartz
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
    var opacity: CGFloat = 1.0
    var lineGap: CGFloat = 0
    var cursorOffset = CGPoint.zero
    var fadeAfterSeconds: TimeInterval = 0
    var displayMode: OverlayDisplayMode = .activeDisplayOnly
    var cursorMode: CursorMode = .experimentalBackground
    var reticle: ReticleStyle = .cross
    var holdToShow = false
    var optionKeyBehavior: OptionKeyBehavior = .showCrosshair
    var excludedBundleIdentifiers = Set<String>()
    var displayProfiles = DisplayProfiles(defaultSettings: .default)
    var presetLibrary = PresetLibrary.builtIn
    var appProfiles = AppProfiles(defaultSettings: .default)
    var fullAppProfiles = FullAppProfiles(defaultConfiguration: .default)
    private(set) var activeDisplayIdentifier: String?
    private var activeApplicationIdentifier: String?

    var shouldHideNativeCursor: Bool {
        let optionIsPressed = CGEventSource.flagsState(.combinedSessionState).contains(.maskAlternate)
        guard holdToShow else {
            return CursorVisibilityPolicy.shouldHideCursor(
                crosshairVisible: isVisible,
                hideCursorEnabled: hideNativeCursor
            )
        }
        return OptionKeyBehaviorPolicy.shouldHideNativeCursor(
            crosshairVisible: isVisible,
            hideCursorEnabled: hideNativeCursor,
            behavior: optionKeyBehavior,
            isOptionPressed: optionIsPressed
        )
    }

    var dotShadeCGColor: CGColor {
        showDotShade ? dotShadeColor.cgColor : NSColor.clear.cgColor
    }

    var advancedSettings: AdvancedOverlaySettings {
        AdvancedOverlaySettings(
            opacity: Double(opacity),
            lineGap: Double(lineGap),
            offsetX: cursorOffset.x,
            offsetY: cursorOffset.y,
            fadeAfterSeconds: fadeAfterSeconds,
            displayMode: displayMode,
            cursorMode: cursorMode,
            reticle: reticle
        )
    }

    func apply(_ advanced: AdvancedOverlaySettings) {
        opacity = advanced.opacity
        lineGap = advanced.lineGap
        cursorOffset = CGPoint(x: advanced.offset.x, y: advanced.offset.y)
        fadeAfterSeconds = advanced.fadeAfterSeconds
        displayMode = advanced.displayMode
        cursorMode = advanced.cursorMode
        reticle = advanced.reticle
    }

    var appearanceConfiguration: CrosshairAppearanceConfiguration {
        CrosshairAppearanceConfiguration(
            lineColor: rgba(crosshairColor),
            lineWidth: Double(lineWidth),
            pattern: CrosshairLinePattern(rawValue: pattern.description.lowercased()) ?? .dashed,
            dotColor: rgba(dotColor),
            shadeColor: rgba(dotShadeColor),
            showDot: showDot,
            showShade: showDotShade
        )
    }

    var configuration: CrosshairConfiguration {
        CrosshairConfiguration(
            advanced: advancedSettings,
            appearance: appearanceConfiguration,
            isVisible: isVisible,
            hideNativeCursor: hideNativeCursor,
            holdToShow: holdToShow,
            optionKeyBehavior: optionKeyBehavior
        )
    }

    func apply(_ configuration: CrosshairConfiguration) {
        apply(configuration.advanced)
        crosshairColor = color(configuration.appearance.lineColor)
        lineWidth = CGFloat(configuration.appearance.lineWidth)
        pattern = LinePattern.from(description: configuration.appearance.pattern.rawValue.capitalized) ?? .dashed
        dotColor = color(configuration.appearance.dotColor)
        dotShadeColor = color(configuration.appearance.shadeColor)
        showDot = configuration.appearance.showDot
        showDotShade = configuration.appearance.showShade
        isVisible = configuration.isVisible
        hideNativeCursor = configuration.hideNativeCursor
        holdToShow = configuration.holdToShow
        optionKeyBehavior = configuration.optionKeyBehavior
    }

    func activateDisplayProfile(_ identifier: String) {
        guard activeDisplayIdentifier != identifier else { return }
        activeDisplayIdentifier = identifier
        applyActiveProfileOverrides()
    }

    func activateAppProfile(_ bundleIdentifier: String?) {
        guard activeApplicationIdentifier != bundleIdentifier else { return }
        fullAppProfiles.defaultConfiguration = OverlayProfileResolver.fallbackConfiguration(
            base: fullAppProfiles.defaultConfiguration,
            current: configuration,
            activeAppConfiguration: fullAppProfiles.profile(for: activeApplicationIdentifier)
        )
        activeApplicationIdentifier = bundleIdentifier
        applyActiveProfileOverrides()
    }

    func saveAppProfile(_ bundleIdentifier: String) {
        fullAppProfiles.save(bundleIdentifier: bundleIdentifier, configuration: configuration)
    }

    func removeAppProfile(_ bundleIdentifier: String) {
        fullAppProfiles.profiles.removeAll { $0.bundleIdentifier == bundleIdentifier }
        applyActiveProfileOverrides()
    }

    func saveActiveDisplayProfile() {
        guard let activeDisplayIdentifier else { return }
        displayProfiles.perDisplay[activeDisplayIdentifier] = advancedSettings
    }

    func removeActiveDisplayProfile() {
        guard let activeDisplayIdentifier else { return }
        displayProfiles.perDisplay.removeValue(forKey: activeDisplayIdentifier)
        applyActiveProfileOverrides()
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
        if fullAppProfiles.profile(for: activeApplicationIdentifier) == nil,
           activeDisplayIdentifier.flatMap({ displayProfiles.perDisplay[$0] }) == nil {
            fullAppProfiles.defaultConfiguration = configuration
        }
        var values: [String: Any] = [
            "crosshairColor": archive(crosshairColor),
            "lineWidth": Double(lineWidth),
            "pattern": pattern.description,
            "isVisible": isVisible,
            "showDot": showDot,
            "intersectionShape": intersectionShape.rawValue,
            "dotColor": archive(dotColor),
            "dotShadeColor": archive(dotShadeColor),
            "showDotShade": showDotShade,
            "hideNativeCursor": hideNativeCursor,
            "advancedSettings": advancedSettings.encoded(),
            "holdToShow": holdToShow,
            "optionKeyBehavior": optionKeyBehavior.rawValue,
            "excludedBundleIdentifiers": Array(excludedBundleIdentifiers).sorted()
        ]
        if let data = try? JSONEncoder().encode(displayProfiles) { values["displayProfiles"] = data }
        if let data = try? JSONEncoder().encode(presetLibrary) { values["presetLibrary"] = data }
        if let data = try? JSONEncoder().encode(appProfiles) { values["appProfiles"] = data }
        if let data = try? JSONEncoder().encode(fullAppProfiles) { values["fullAppProfiles"] = data }
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
        if let data = values["advancedSettings"] as? Data, let advanced = try? AdvancedOverlaySettings.decode(from: data) { apply(advanced) }
        if let value = values["holdToShow"] as? Bool { holdToShow = value }
        if let value = values["optionKeyBehavior"] as? String, let behavior = OptionKeyBehavior(rawValue: value) {
            optionKeyBehavior = behavior
        }
        if let values = values["excludedBundleIdentifiers"] as? [String] { excludedBundleIdentifiers = Set(values) }
        if let data = values["displayProfiles"] as? Data, let profiles = try? JSONDecoder().decode(DisplayProfiles.self, from: data) { displayProfiles = profiles }
        if let data = values["presetLibrary"] as? Data, let library = try? JSONDecoder().decode(PresetLibrary.self, from: data) { presetLibrary = library }
        if let data = values["appProfiles"] as? Data, let profiles = try? JSONDecoder().decode(AppProfiles.self, from: data) {
            appProfiles = profiles
        } else {
            appProfiles.defaultSettings = advancedSettings
        }
        if let data = values["fullAppProfiles"] as? Data, let profiles = try? JSONDecoder().decode(FullAppProfiles.self, from: data) {
            fullAppProfiles = profiles
        } else {
            fullAppProfiles = FullAppProfiles(legacyProfiles: appProfiles, defaultConfiguration: configuration)
        }
        fullAppProfiles.defaultConfiguration = configuration
        return true
    }

    private func applyActiveProfileOverrides() {
        let displaySettings = activeDisplayIdentifier.flatMap { displayProfiles.perDisplay[$0] }
        let appConfiguration = fullAppProfiles.profile(for: activeApplicationIdentifier)
        apply(OverlayProfileResolver.configuration(
            base: fullAppProfiles.defaultConfiguration,
            displaySettings: displaySettings,
            appConfiguration: appConfiguration
        ))
    }

    private func archive(_ color: NSColor) -> Data {
        (try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)) ?? Data()
    }

    private func unarchive(_ data: Data) -> NSColor? {
        try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
    }

    private func rgba(_ color: NSColor) -> RGBAColor {
        let resolved = color.usingColorSpace(.deviceRGB) ?? color
        return RGBAColor(
            red: Double(resolved.redComponent),
            green: Double(resolved.greenComponent),
            blue: Double(resolved.blueComponent),
            alpha: Double(resolved.alphaComponent)
        )
    }

    private func color(_ rgba: RGBAColor) -> NSColor {
        NSColor(red: rgba.red, green: rgba.green, blue: rgba.blue, alpha: rgba.alpha)
    }
}
