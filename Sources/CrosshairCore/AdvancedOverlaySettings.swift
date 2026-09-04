import Foundation

public struct OverlayOffset: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double = 0, y: Double = 0) {
        self.x = x.isFinite ? x : 0
        self.y = y.isFinite ? y : 0
    }
}

public enum OverlayDisplayMode: String, CaseIterable, Codable, Equatable, Sendable {
    case activeDisplayOnly
    case allDisplays
    case externalOnly
    case mainDisplayOnly

    public var title: String {
        switch self {
        case .activeDisplayOnly: "Active Display Only"
        case .allDisplays: "All Displays"
        case .externalOnly: "External Displays Only"
        case .mainDisplayOnly: "Main Display Only"
        }
    }
}

public enum CursorMode: String, CaseIterable, Codable, Equatable, Sendable {
    case experimentalBackground
    case supportedForegroundOnly

    public var title: String {
        switch self {
        case .experimentalBackground: "Experimental Background Hiding"
        case .supportedForegroundOnly: "Supported Foreground Only"
        }
    }
}

public enum ReticleStyle: String, CaseIterable, Codable, Equatable, Sendable {
    case circle
    case sniperAim
    case cross
    case plus
    case diamond
    case t
    case ring
    case chevron
    case fourCorners
    case hollowSquare

    public var title: String {
        switch self {
        case .circle: "Circle"
        case .sniperAim: "Sniper Aim"
        case .cross: "Cross"
        case .plus: "Plus"
        case .diamond: "Diamond"
        case .t: "T"
        case .ring: "Ring"
        case .chevron: "Chevron"
        case .fourCorners: "Four Corners"
        case .hollowSquare: "Hollow Square"
        }
    }
}

public struct AdvancedOverlaySettings: Codable, Equatable, Sendable {
    public static let `default` = AdvancedOverlaySettings()

    public var opacity: Double
    public var lineGap: Double
    public var offset: OverlayOffset
    public var fadeAfterSeconds: Double
    public var displayMode: OverlayDisplayMode
    public var cursorMode: CursorMode
    public var reticle: ReticleStyle

    public init(
        opacity: Double = 1,
        lineGap: Double = 0,
        offsetX: Double = 0,
        offsetY: Double = 0,
        fadeAfterSeconds: Double = 0,
        displayMode: OverlayDisplayMode = .activeDisplayOnly,
        cursorMode: CursorMode = .experimentalBackground,
        reticle: ReticleStyle = .cross
    ) {
        self.opacity = opacity.isFinite ? min(max(opacity, 0), 1) : 1
        self.lineGap = lineGap.isFinite ? min(max(lineGap, 0), 100) : 0
        self.offset = OverlayOffset(x: offsetX, y: offsetY)
        self.fadeAfterSeconds = fadeAfterSeconds.isFinite ? min(max(fadeAfterSeconds, 0), 60) : 0
        self.displayMode = displayMode
        self.cursorMode = cursorMode
        self.reticle = reticle
    }

    public func encoded() -> Data {
        (try? JSONEncoder().encode(self)) ?? Data()
    }

    public static func decode(from data: Data) throws -> AdvancedOverlaySettings {
        try JSONDecoder().decode(AdvancedOverlaySettings.self, from: data)
    }
}

public struct ConfigurationExport: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let settings: AdvancedOverlaySettings

    public init(settings: AdvancedOverlaySettings) {
        self.schemaVersion = Self.currentSchemaVersion
        self.settings = settings
    }

    public func encoded() -> Data {
        (try? JSONEncoder().encode(self)) ?? Data()
    }

    public static func decode(from data: Data) throws -> ConfigurationExport {
        let exported = try JSONDecoder().decode(ConfigurationExport.self, from: data)
        guard exported.schemaVersion == currentSchemaVersion else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unsupported configuration schema version"))
        }
        return exported
    }
}

public struct DisplayDescriptor: Equatable, Sendable {
    public let isMain: Bool
    public let isBuiltIn: Bool

    public init(isMain: Bool, isBuiltIn: Bool) {
        self.isMain = isMain
        self.isBuiltIn = isBuiltIn
    }
}

public struct OverlayVisibilityRules: Equatable, Sendable {
    public let isCrosshairEnabled: Bool
    public let holdToShow: Bool
    public let isHoldKeyPressed: Bool
    public let excludedBundleIdentifiers: Set<String>
    public let frontmostBundleIdentifier: String?
    public let displayMode: OverlayDisplayMode

    public init(
        isCrosshairEnabled: Bool,
        holdToShow: Bool,
        isHoldKeyPressed: Bool,
        excludedBundleIdentifiers: Set<String>,
        frontmostBundleIdentifier: String?,
        displayMode: OverlayDisplayMode
    ) {
        self.isCrosshairEnabled = isCrosshairEnabled
        self.holdToShow = holdToShow
        self.isHoldKeyPressed = isHoldKeyPressed
        self.excludedBundleIdentifiers = excludedBundleIdentifiers
        self.frontmostBundleIdentifier = frontmostBundleIdentifier
        self.displayMode = displayMode
    }

    public func shouldShow(on display: DisplayDescriptor) -> Bool {
        guard isCrosshairEnabled, !excludedBundleIdentifiers.contains(frontmostBundleIdentifier ?? "") else { return false }
        guard !holdToShow || isHoldKeyPressed else { return false }
        switch displayMode {
        case .activeDisplayOnly, .allDisplays: return true
        case .externalOnly: return !display.isBuiltIn
        case .mainDisplayOnly: return display.isMain
        }
    }
}

public struct DisplayProfiles: Codable, Equatable, Sendable {
    public var defaultSettings: AdvancedOverlaySettings
    public var perDisplay: [String: AdvancedOverlaySettings]

    public init(defaultSettings: AdvancedOverlaySettings, perDisplay: [String: AdvancedOverlaySettings] = [:]) {
        self.defaultSettings = defaultSettings
        self.perDisplay = perDisplay
    }

    public func settings(for displayIdentifier: String) -> AdvancedOverlaySettings {
        perDisplay[displayIdentifier] ?? defaultSettings
    }
}

public struct AppProfile: Codable, Equatable, Sendable {
    public let bundleIdentifier: String
    public let settings: AdvancedOverlaySettings

    public init(bundleIdentifier: String, settings: AdvancedOverlaySettings) {
        self.bundleIdentifier = bundleIdentifier
        self.settings = settings
    }
}

public struct RGBAColor: Codable, Equatable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = min(max(red, 0), 1)
        self.green = min(max(green, 0), 1)
        self.blue = min(max(blue, 0), 1)
        self.alpha = min(max(alpha, 0), 1)
    }
}

public enum CrosshairLinePattern: String, Codable, Equatable, Sendable {
    case solid
    case dashed
    case dotted
}

public struct CrosshairAppearanceConfiguration: Codable, Equatable, Sendable {
    public let lineColor: RGBAColor
    public let lineWidth: Double
    public let pattern: CrosshairLinePattern
    public let dotColor: RGBAColor
    public let shadeColor: RGBAColor
    public let showDot: Bool
    public let showShade: Bool

    public init(lineColor: RGBAColor, lineWidth: Double, pattern: CrosshairLinePattern, dotColor: RGBAColor, shadeColor: RGBAColor, showDot: Bool, showShade: Bool) {
        self.lineColor = lineColor
        self.lineWidth = lineWidth.isFinite ? min(max(lineWidth, 1), 5) : 1
        self.pattern = pattern
        self.dotColor = dotColor
        self.shadeColor = shadeColor
        self.showDot = showDot
        self.showShade = showShade
    }
}

public struct CrosshairConfiguration: Codable, Equatable, Sendable {
    public static let `default` = CrosshairConfiguration(
        advanced: .default,
        appearance: .init(
            lineColor: .init(red: 0, green: 1, blue: 0, alpha: 1),
            lineWidth: 1,
            pattern: .dashed,
            dotColor: .init(red: 0, green: 1, blue: 0, alpha: 1),
            shadeColor: .init(red: 0, green: 0, blue: 0, alpha: 1),
            showDot: true,
            showShade: true
        ),
        isVisible: true,
        hideNativeCursor: true,
        holdToShow: false
    )

    public let advanced: AdvancedOverlaySettings
    public let appearance: CrosshairAppearanceConfiguration
    public let isVisible: Bool
    public let hideNativeCursor: Bool
    public let holdToShow: Bool

    public init(advanced: AdvancedOverlaySettings, appearance: CrosshairAppearanceConfiguration, isVisible: Bool, hideNativeCursor: Bool, holdToShow: Bool) {
        self.advanced = advanced
        self.appearance = appearance
        self.isVisible = isVisible
        self.hideNativeCursor = hideNativeCursor
        self.holdToShow = holdToShow
    }
}

public struct FullAppProfile: Codable, Equatable, Sendable {
    public let bundleIdentifier: String
    public let configuration: CrosshairConfiguration

    public init(bundleIdentifier: String, configuration: CrosshairConfiguration) {
        self.bundleIdentifier = bundleIdentifier
        self.configuration = configuration
    }
}

public struct FullAppProfiles: Codable, Equatable, Sendable {
    public var defaultConfiguration: CrosshairConfiguration
    public var profiles: [FullAppProfile]

    public init(defaultConfiguration: CrosshairConfiguration, profiles: [FullAppProfile] = []) {
        self.defaultConfiguration = defaultConfiguration
        self.profiles = profiles
    }

    public init(legacyProfiles: AppProfiles, defaultConfiguration: CrosshairConfiguration) {
        self.defaultConfiguration = defaultConfiguration
        self.profiles = legacyProfiles.profiles.map {
            FullAppProfile(
                bundleIdentifier: $0.bundleIdentifier,
                configuration: CrosshairConfiguration(
                    advanced: $0.settings,
                    appearance: defaultConfiguration.appearance,
                    isVisible: defaultConfiguration.isVisible,
                    hideNativeCursor: defaultConfiguration.hideNativeCursor,
                    holdToShow: defaultConfiguration.holdToShow
                )
            )
        }
    }

    public func configuration(for bundleIdentifier: String?) -> CrosshairConfiguration {
        guard let bundleIdentifier else { return defaultConfiguration }
        return profiles.first { $0.bundleIdentifier == bundleIdentifier }?.configuration ?? defaultConfiguration
    }

    public mutating func save(bundleIdentifier: String, configuration: CrosshairConfiguration) {
        profiles.removeAll { $0.bundleIdentifier == bundleIdentifier }
        profiles.append(.init(bundleIdentifier: bundleIdentifier, configuration: configuration))
        profiles.sort { $0.bundleIdentifier < $1.bundleIdentifier }
    }
}

public struct AppProfiles: Codable, Equatable, Sendable {
    public var defaultSettings: AdvancedOverlaySettings
    public var profiles: [AppProfile]

    public init(defaultSettings: AdvancedOverlaySettings, profiles: [AppProfile] = []) {
        self.defaultSettings = defaultSettings
        self.profiles = profiles
    }

    public func settings(for bundleIdentifier: String?) -> AdvancedOverlaySettings {
        guard let bundleIdentifier else { return defaultSettings }
        return profiles.first { $0.bundleIdentifier == bundleIdentifier }?.settings ?? defaultSettings
    }

    public mutating func save(bundleIdentifier: String, settings: AdvancedOverlaySettings) {
        profiles.removeAll { $0.bundleIdentifier == bundleIdentifier }
        profiles.append(.init(bundleIdentifier: bundleIdentifier, settings: settings))
        profiles.sort { $0.bundleIdentifier < $1.bundleIdentifier }
    }
}

public struct CrosshairPreset: Codable, Equatable, Sendable {
    public let name: String
    public let settings: AdvancedOverlaySettings

    public init(name: String, settings: AdvancedOverlaySettings) {
        self.name = name
        self.settings = settings
    }
}

public struct PresetLibrary: Codable, Equatable, Sendable {
    public var presets: [CrosshairPreset]

    public init(presets: [CrosshairPreset] = []) {
        self.presets = presets.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public static let builtIn = PresetLibrary(presets: [
        .init(name: "Accessibility", settings: .init(opacity: 1, lineGap: 8, reticle: .ring)),
        .init(name: "FPS", settings: .init(opacity: 1, lineGap: 6, reticle: .cross)),
        .init(name: "Minimal", settings: .init(opacity: 0.65, lineGap: 0, reticle: .plus)),
        .init(name: "Presentation", settings: .init(opacity: 0.85, lineGap: 12, reticle: .circle)),
        .init(name: "Sniper", settings: .init(opacity: 1, lineGap: 10, reticle: .sniperAim))
    ])

    public var names: [String] { presets.map(\.name) }

    public func settings(named name: String) -> AdvancedOverlaySettings? {
        presets.first { $0.name == name }?.settings
    }

    public func next(after name: String?) -> CrosshairPreset? {
        guard !presets.isEmpty else { return nil }
        guard let name, let index = presets.firstIndex(where: { $0.name == name }) else { return presets.first }
        return presets[(index + 1) % presets.count]
    }

    public mutating func save(name: String, settings: AdvancedOverlaySettings) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        presets.removeAll { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }
        presets.append(.init(name: trimmed, settings: settings))
        presets.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
