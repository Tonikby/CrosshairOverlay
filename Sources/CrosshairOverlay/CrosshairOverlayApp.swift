import Cocoa
import Carbon
import Quartz
import CrosshairCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusWindow: NSWindow!
    var menuController: MenuController!
    var overlayPanel: OverlayPanel!
    var cursorController: CursorController!
    let settings = SettingsStore.shared
    private var hotkeyHandler: EventHandlerRef?
    private var hotkeyReferences: [EventHotKeyRef] = []
    private var cursorTimer: Timer?
    private var eventMonitorTokens: [Any] = []

    private static let hotkeySignature: OSType = 0x43485253 // "CHRS"


    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = settings.restore()
        // Use regular activation policy so status item menus work properly
        NSApp.setActivationPolicy(.regular)

        // Create a small hidden main window — required for status item menu actions (Quit, etc.) to fire
        let mainWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        mainWindow.title = ""
        mainWindow.level = .floating
        mainWindow.ignoresMouseEvents = true
        mainWindow.alphaValue = 0.0
        mainWindow.isMovable = false
        mainWindow.minSize = NSSize(width: 1, height: 1)
        mainWindow.maxSize = NSSize(width: 1, height: 1)
        self.statusWindow = mainWindow
        mainWindow.orderBack(nil)

        cursorController = CursorController()

        // Create the crosshair overlay panel
        overlayPanel = OverlayPanel(settings: settings)

        // Create the menu bar controller
        menuController = MenuController(
            settings: settings,
            overlayPanel: overlayPanel,
            cursorController: cursorController
        )
        cursorController.apply(setting: settings.shouldHideNativeCursor)
        installGlobalHotkeys()

        // Use a high-frequency timer for reliable cursor tracking (works even when mouse button is held)
        Task { @MainActor in
            let panel = self.overlayPanel!
            let settings = self.settings
            let cursorController = self.cursorController!

            let timer = Timer(timeInterval: 0.016, repeats: true) { _ in
                let location = NSEvent.mouseLocation
                Task { @MainActor in
                    if settings.shouldHideNativeCursor {
                        cursorController.reassertHidden()
                    }
                    panel.updateCursorLocation(location)
                }
            }
            self.cursorTimer = timer
            RunLoop.main.add(timer, forMode: .common)
            RunLoop.main.add(timer, forMode: .eventTracking)
        }

        // Global monitor for cursor hiding when app is not active (e.g., during drag in other apps)
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved], handler: { _ in
            if self.settings.shouldHideNativeCursor {
                self.cursorController.reassertHidden()
            }
        }) {
            eventMonitorTokens.append(monitor)
        }

        // Also hide cursor during drag events (when other apps capture mouse)
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown], handler: { _ in
            if self.settings.shouldHideNativeCursor {
                self.cursorController.reassertHidden()
            }
        }) {
            eventMonitorTokens.append(monitor)
        }

        // Reapply the effective cursor state when a drag ends.
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp, .otherMouseUp], handler: { _ in
            self.cursorController.apply(setting: self.settings.shouldHideNativeCursor)
        }) {
            eventMonitorTokens.append(monitor)
        }

        print("Crosshair Overlay started. Ctrl+Shift+Cmd+C toggles crosshair lines; Ctrl+Shift+Cmd+H toggles native cursor hiding.")
    }

    private func installGlobalHotkeys() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }
                var hotkeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotkeyID
                )
                guard status == noErr, let hotkey = GlobalHotkey.action(identifier: hotkeyID.id) else {
                    return OSStatus(eventNotHandledErr)
                }

                let delegateAddress = UInt(bitPattern: userData)
                guard let delegatePointer = UnsafeMutableRawPointer(bitPattern: delegateAddress) else {
                    return OSStatus(eventNotHandledErr)
                }
                MainActor.assumeIsolated {
                    let delegate = Unmanaged<AppDelegate>.fromOpaque(delegatePointer).takeUnretainedValue()
                    delegate.perform(hotkey)
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &hotkeyHandler
        )
        guard handlerStatus == noErr else {
            print("Unable to install global hotkey handler: \(handlerStatus)")
            return
        }

        let modifiers = UInt32(controlKey | shiftKey | cmdKey)
        for (keyCode, identifier) in [(UInt32(kVK_ANSI_C), UInt32(1)), (UInt32(kVK_ANSI_H), UInt32(2))] {
            var reference: EventHotKeyRef?
            let status = RegisterEventHotKey(
                keyCode,
                modifiers,
                EventHotKeyID(signature: Self.hotkeySignature, id: identifier),
                GetApplicationEventTarget(),
                0,
                &reference
            )
            if status == noErr, let reference {
                hotkeyReferences.append(reference)
            } else {
                print("Unable to register global hotkey \(identifier): \(status)")
            }
        }
    }

    @MainActor
    private func perform(_ hotkey: GlobalHotkey) {
        switch hotkey {
        case .toggleCrosshair:
            menuController.toggleCrosshair()
        case .toggleNativeCursor:
            menuController.toggleNativeCursor()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep running as menu-bar-only app
    }

    func applicationWillTerminate(_ notification: Notification) {
        cursorTimer?.invalidate()
        cursorTimer = nil
        for token in eventMonitorTokens {
            NSEvent.removeMonitor(token)
        }
        eventMonitorTokens.removeAll()
        for reference in hotkeyReferences {
            UnregisterEventHotKey(reference)
        }
        hotkeyReferences.removeAll()
        if let hotkeyHandler {
            RemoveEventHandler(hotkeyHandler)
            self.hotkeyHandler = nil
        }
        cursorController.restoreCursor()
    }
}

@_cdecl("main")
func main() {
    MainActor.assumeIsolated {
        let argv = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: 1)
        argv.pointee = nil
        defer { argv.deallocate() }

        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        _ = NSApplicationMain(0, argv)
    }
}
