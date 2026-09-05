import XCTest
import CrosshairCore

final class CursorVisibilityTests: XCTestCase {
    func testSharedColorPaletteContainsMajorColors() {
        XCTAssertEqual(
            ColorPalette.names,
            ["Black", "White", "Red", "Orange", "Yellow", "Green", "Cyan", "Blue", "Purple", "Magenta"]
        )
    }

    func testGlobalHotkeysRequireControlShiftAndCommand() {
        XCTAssertEqual(
            GlobalHotkey.action(
                key: "c",
                control: true,
                shift: true,
                command: true
            ),
            .toggleCrosshair
        )
        XCTAssertEqual(
            GlobalHotkey.action(
                key: "H",
                control: true,
                shift: true,
                command: true
            ),
            .toggleNativeCursor
        )
        XCTAssertEqual(
            GlobalHotkey.action(
                key: "p",
                control: true,
                shift: true,
                command: true
            ),
            .nextPreset
        )
        XCTAssertEqual(GlobalHotkey.action(key: "[", control: true, shift: true, command: true), .decreaseLineWidth)
        XCTAssertEqual(GlobalHotkey.action(key: "]", control: true, shift: true, command: true), .increaseLineWidth)
        XCTAssertEqual(GlobalHotkey.action(key: "-", control: true, shift: true, command: true), .decreaseOpacity)
        XCTAssertEqual(GlobalHotkey.action(key: "=", control: true, shift: true, command: true), .increaseOpacity)
        XCTAssertNil(
            GlobalHotkey.action(
                key: "c",
                control: false,
                shift: true,
                command: true
            )
        )
    }

    func testCarbonHotkeyIdentifiersMapToActions() {
        XCTAssertEqual(GlobalHotkey.action(identifier: 1), .toggleCrosshair)
        XCTAssertEqual(GlobalHotkey.action(identifier: 2), .toggleNativeCursor)
        XCTAssertEqual(GlobalHotkey.action(identifier: 3), .nextPreset)
        XCTAssertEqual(GlobalHotkey.action(identifier: 4), .decreaseLineWidth)
        XCTAssertEqual(GlobalHotkey.action(identifier: 5), .increaseLineWidth)
        XCTAssertEqual(GlobalHotkey.action(identifier: 6), .decreaseOpacity)
        XCTAssertEqual(GlobalHotkey.action(identifier: 7), .increaseOpacity)
        XCTAssertNil(GlobalHotkey.action(identifier: 0))
    }

    func testRestoredLineWidthRejectsInvalidValues() {
        XCTAssertEqual(LineWidthPolicy.restoredWidth(3, fallback: 1), 3)
        XCTAssertEqual(LineWidthPolicy.restoredWidth(0, fallback: 1), 1)
        XCTAssertEqual(LineWidthPolicy.restoredWidth(6, fallback: 1), 1)
        XCTAssertEqual(LineWidthPolicy.restoredWidth(.infinity, fallback: 1), 1)
        XCTAssertEqual(LineWidthPolicy.restoredWidth(.nan, fallback: 1), 1)
    }

    func testCursorIsHiddenOnlyWhileCrosshairIsVisible() {
        XCTAssertTrue(CursorVisibilityPolicy.shouldHideCursor(
            crosshairVisible: true,
            hideCursorEnabled: true
        ))
        XCTAssertFalse(CursorVisibilityPolicy.shouldHideCursor(
            crosshairVisible: false,
            hideCursorEnabled: true
        ))
        XCTAssertFalse(CursorVisibilityPolicy.shouldHideCursor(
            crosshairVisible: true,
            hideCursorEnabled: false
        ))
    }

    func testOptionKeyCanSwitchFromCrosshairHoldToCursorToggle() {
        XCTAssertFalse(OptionKeyBehaviorPolicy.shouldShowCrosshair(
            behavior: .showCrosshair,
            isOptionPressed: false
        ))
        XCTAssertTrue(OptionKeyBehaviorPolicy.shouldShowCrosshair(
            behavior: .showCrosshair,
            isOptionPressed: true
        ))
        XCTAssertTrue(OptionKeyBehaviorPolicy.shouldShowCrosshair(
            behavior: .toggleNativeCursor,
            isOptionPressed: false
        ))
        XCTAssertFalse(OptionKeyBehaviorPolicy.shouldHideNativeCursor(
            crosshairVisible: true,
            hideCursorEnabled: true,
            behavior: .showCrosshair,
            isOptionPressed: false
        ))
        XCTAssertTrue(OptionKeyBehaviorPolicy.shouldHideNativeCursor(
            crosshairVisible: true,
            hideCursorEnabled: true,
            behavior: .showCrosshair,
            isOptionPressed: true
        ))
        XCTAssertFalse(OptionKeyBehaviorPolicy.shouldHideNativeCursor(
            crosshairVisible: true,
            hideCursorEnabled: true,
            behavior: .toggleNativeCursor,
            isOptionPressed: true
        ))
        XCTAssertTrue(OptionKeyBehaviorPolicy.shouldHideNativeCursor(
            crosshairVisible: true,
            hideCursorEnabled: false,
            behavior: .toggleNativeCursor,
            isOptionPressed: true
        ))
    }

    func testFullProfilePreservesOptionKeyBehavior() throws {
        let configuration = CrosshairConfiguration(
            advanced: .default,
            appearance: CrosshairConfiguration.default.appearance,
            isVisible: true,
            hideNativeCursor: true,
            holdToShow: true,
            optionKeyBehavior: .toggleNativeCursor
        )

        let restored = try JSONDecoder().decode(
            CrosshairConfiguration.self,
            from: JSONEncoder().encode(configuration)
        )

        XCTAssertEqual(restored.optionKeyBehavior, .toggleNativeCursor)
    }

    func testLegacyFullProfileDefaultsOptionKeyBehaviorToCrosshairHold() throws {
        let configuration = CrosshairConfiguration.default
        var serialized = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(configuration)) as? [String: Any]
        )
        serialized.removeValue(forKey: "optionKeyBehavior")

        let restored = try JSONDecoder().decode(
            CrosshairConfiguration.self,
            from: JSONSerialization.data(withJSONObject: serialized)
        )

        XCTAssertEqual(restored.optionKeyBehavior, .showCrosshair)
    }


    func testAdvancedOverlaySettingsSanitizeAndRoundTrip() throws {
        let settings = AdvancedOverlaySettings(
            opacity: 2,
            lineGap: -10,
            offsetX: 14,
            offsetY: -9,
            fadeAfterSeconds: -1,
            displayMode: .externalOnly,
            cursorMode: .supportedForegroundOnly,
            reticle: .fourCorners
        )

        XCTAssertEqual(settings.opacity, 1)
        XCTAssertEqual(settings.lineGap, 0)
        XCTAssertEqual(settings.fadeAfterSeconds, 0)
        XCTAssertEqual(settings.offset, .init(x: 14, y: -9))
        XCTAssertEqual(settings.displayMode, .externalOnly)
        XCTAssertEqual(settings.cursorMode, .supportedForegroundOnly)
        XCTAssertEqual(settings.reticle, .fourCorners)

        let decoded = try AdvancedOverlaySettings.decode(from: settings.encoded())
        XCTAssertEqual(decoded, settings)
    }

    func testPresetLibraryProvidesBuiltInsAndCyclesNamedPresets() {
        var library = PresetLibrary.builtIn
        XCTAssertEqual(library.names, ["Accessibility", "FPS", "Minimal", "Presentation", "Sniper"])
        XCTAssertEqual(library.next(after: "FPS")?.name, "Minimal")
        XCTAssertEqual(library.next(after: "Sniper")?.name, "Accessibility")

        library.save(name: "Design", settings: .default)
        XCTAssertEqual(library.settings(named: "Design"), .default)
    }

    func testVisibilityRulesCombineHoldModeAppExclusionsAndDisplayMode() {
        let rules = OverlayVisibilityRules(
            isCrosshairEnabled: true,
            holdToShow: true,
            isHoldKeyPressed: false,
            excludedBundleIdentifiers: ["com.apple.TextEdit"],
            frontmostBundleIdentifier: "com.apple.TextEdit",
            displayMode: .externalOnly
        )
        XCTAssertFalse(rules.shouldShow(on: .init(isMain: false, isBuiltIn: false)))

        let allowed = OverlayVisibilityRules(
            isCrosshairEnabled: true,
            holdToShow: true,
            isHoldKeyPressed: true,
            excludedBundleIdentifiers: [],
            frontmostBundleIdentifier: "com.example.Game",
            displayMode: .externalOnly
        )
        XCTAssertTrue(allowed.shouldShow(on: .init(isMain: false, isBuiltIn: false)))
        XCTAssertFalse(allowed.shouldShow(on: .init(isMain: true, isBuiltIn: true)))
    }

    func testDisplayProfilesPreferExactDisplayThenDefault() {
        let defaults = AdvancedOverlaySettings.default
        let profile = AdvancedOverlaySettings(opacity: 0.4)
        let profiles = DisplayProfiles(defaultSettings: defaults, perDisplay: ["External-1": profile])
        XCTAssertEqual(profiles.settings(for: "External-1"), profile)
        XCTAssertEqual(profiles.settings(for: "Missing"), defaults)
    }

    func testFullAppProfileOverridesDisplayAdvancedSettings() {
        let base = CrosshairConfiguration.default
        let displaySettings = AdvancedOverlaySettings(opacity: 0.4, lineGap: 16, reticle: .ring)
        let appOverride = CrosshairConfiguration(
            advanced: .init(opacity: 0.8, lineGap: 4, reticle: .chevron),
            appearance: .init(
                lineColor: .init(red: 1, green: 0, blue: 0, alpha: 1),
                lineWidth: 4,
                pattern: .solid,
                dotColor: .init(red: 0, green: 1, blue: 0, alpha: 1),
                shadeColor: .init(red: 0, green: 0, blue: 0, alpha: 1),
                showDot: true,
                showShade: false
            ),
            isVisible: true,
            hideNativeCursor: false,
            holdToShow: false
        )

        XCTAssertEqual(
            OverlayProfileResolver.configuration(base: base, displaySettings: displaySettings, appConfiguration: nil).advanced,
            displaySettings
        )
        XCTAssertEqual(
            OverlayProfileResolver.configuration(base: base, displaySettings: displaySettings, appConfiguration: appOverride),
            appOverride
        )
    }

    func testConfigurationExportUsesVersionedValidatedEnvelope() throws {
        let original = AdvancedOverlaySettings(opacity: 0.45, lineGap: 12, reticle: .chevron)
        let data = ConfigurationExport(settings: original).encoded()
        XCTAssertEqual(try ConfigurationExport.decode(from: data).settings, original)

        let unsupported = try JSONSerialization.data(withJSONObject: ["schemaVersion": 999, "settings": [:]])
        XCTAssertThrowsError(try ConfigurationExport.decode(from: unsupported))
    }

    func testAppProfilesUseFullConfigurationOverride() {
        let defaultSettings = AdvancedOverlaySettings.default
        let override = AdvancedOverlaySettings(opacity: 0.4, lineGap: 16, reticle: .hollowSquare)
        let profiles = AppProfiles(defaultSettings: defaultSettings, profiles: [
            .init(bundleIdentifier: "com.example.Game", settings: override)
        ])

        XCTAssertEqual(profiles.settings(for: "com.example.Game"), override)
        XCTAssertEqual(profiles.settings(for: "com.example.Other"), defaultSettings)
    }

    func testFullAppearanceConfigurationRoundTripsInAppProfile() {
        let appearance = CrosshairAppearanceConfiguration(
            lineColor: .init(red: 1, green: 0, blue: 0, alpha: 1),
            lineWidth: 4,
            pattern: .dotted,
            dotColor: .init(red: 0, green: 1, blue: 1, alpha: 1),
            shadeColor: .init(red: 0, green: 0, blue: 0, alpha: 1),
            showDot: false,
            showShade: false
        )
        XCTAssertEqual(appearance.lineWidth, 4)
        XCTAssertEqual(appearance.pattern, .dotted)
        XCTAssertFalse(appearance.showDot)
        XCTAssertFalse(appearance.showShade)
    }

    func testFullAppProfileOverridesAppearanceAndAdvancedSettings() {
        let defaultConfiguration = CrosshairConfiguration.default
        let override = CrosshairConfiguration(
            advanced: .init(opacity: 0.6, lineGap: 12, reticle: .ring),
            appearance: .init(
                lineColor: .init(red: 1, green: 0, blue: 0, alpha: 1),
                lineWidth: 5,
                pattern: .solid,
                dotColor: .init(red: 0, green: 1, blue: 0, alpha: 1),
                shadeColor: .init(red: 0, green: 0, blue: 1, alpha: 1),
                showDot: false,
                showShade: false
            ),
            isVisible: false,
            hideNativeCursor: false,
            holdToShow: true
        )
        var profiles = FullAppProfiles(defaultConfiguration: defaultConfiguration)
        profiles.save(bundleIdentifier: "com.example.Game", configuration: override)

        XCTAssertEqual(profiles.configuration(for: "com.example.Game"), override)
        XCTAssertEqual(profiles.configuration(for: "com.example.Other"), defaultConfiguration)
    }

    func testFullAppProfilesMigratesLegacyAdvancedProfileWithAppearanceDefaults() {
        let appearance = CrosshairAppearanceConfiguration(
            lineColor: .init(red: 1, green: 1, blue: 1, alpha: 1),
            lineWidth: 3,
            pattern: .solid,
            dotColor: .init(red: 1, green: 0, blue: 0, alpha: 1),
            shadeColor: .init(red: 0, green: 0, blue: 0, alpha: 1),
            showDot: true,
            showShade: true
        )
        let legacy = AppProfiles(
            defaultSettings: .init(opacity: 1),
            profiles: [.init(bundleIdentifier: "com.example.Game", settings: .init(opacity: 0.4, reticle: .ring))]
        )
        let migrated = FullAppProfiles(
            legacyProfiles: legacy,
            defaultConfiguration: .init(advanced: .init(opacity: 1), appearance: appearance, isVisible: true, hideNativeCursor: true, holdToShow: false)
        )

        XCTAssertEqual(migrated.configuration(for: "com.example.Game").advanced.opacity, 0.4)
        XCTAssertEqual(migrated.configuration(for: "com.example.Game").appearance, appearance)
    }
}
