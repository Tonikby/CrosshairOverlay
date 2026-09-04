import Cocoa
import Quartz

@_silgen_name("_CGSDefaultConnection")
private func CGSDefaultConnection() -> Int32

@_silgen_name("CGSSetConnectionProperty")
private func CGSSetConnectionProperty(
    _ connection: Int32,
    _ targetConnection: Int32,
    _ key: CFString,
    _ value: CFTypeRef
) -> CGError

@_silgen_name("CGCursorIsVisible")
private func CGCursorIsVisible() -> Int32

@MainActor
final class CursorController {
    private(set) var isHidden = false
    private var hideCount = 0

    init() {
        let connection = CGSDefaultConnection()
        let error = CGSSetConnectionProperty(
            connection,
            connection,
            "SetsCursorInBackground" as CFString,
            kCFBooleanTrue
        )
        if error != .success {
            print("Unable to enable background cursor control: \(error.rawValue)")
        }
    }

    func setHidden(_ hidden: Bool) {
        guard hidden != isHidden else { return }

        if hidden {
            isHidden = true
            reassertHidden()
        } else {
            isHidden = false
            restoreOwnedCursorHides()
        }
    }

    func apply(setting hidden: Bool) {
        setHidden(hidden)
    }

    func reassertHidden() {
        guard isHidden, CGCursorIsVisible() != 0 else { return }
        let error = CGDisplayHideCursor(CGMainDisplayID())
        if error == .success {
            hideCount += 1
        } else {
            print("Unable to hide cursor: \(error.rawValue)")
        }
    }

    func restoreCursor() {
        isHidden = false
        restoreOwnedCursorHides()
    }

    private func restoreOwnedCursorHides() {
        while hideCount > 0 {
            _ = CGDisplayShowCursor(CGMainDisplayID())
            hideCount -= 1
        }
    }
}
