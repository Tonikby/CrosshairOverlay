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
}
