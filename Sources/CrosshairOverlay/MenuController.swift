import Cocoa
import Carbon
import Quartz

@MainActor
class MenuController {
    var statusItem: NSStatusItem!
    var settings: SettingsStore
    var overlayPanel: OverlayPanel
    var cursorController: CursorController
    private enum ColorSelection { case crosshair, dot, shade }
    private var colorSelection: ColorSelection = .crosshair

    init(settings: SettingsStore, overlayPanel: OverlayPanel, cursorController: CursorController) {
        self.settings = settings
        self.overlayPanel = overlayPanel
        self.cursorController = cursorController

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Build a custom crosshair icon as an NSImage
        let iconSize = NSSize(width: 22, height: 22)
        let icon = NSImage(size: iconSize)
        icon.lockFocus()

        // Draw crosshair lines on the icon
        let lineColor = NSColor.white
        lineColor.set()

        // Vertical line
        let vRect = NSRect(x: 10, y: 1, width: 2, height: 20)
        NSBezierPath(rect: vRect).fill()

        // Horizontal line
        let hRect = NSRect(x: 1, y: 10, width: 20, height: 2)
        NSBezierPath(rect: hRect).fill()

        // Center dot
        let dotRect = NSRect(x: 9, y: 9, width: 4, height: 4)
        NSBezierPath(ovalIn: dotRect).fill()

        icon.unlockFocus()
        icon.isTemplate = true

        statusItem.button?.image = icon
        
        buildMenu()
    }

    func buildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let toggleItem = NSMenuItem(
            title: settings.isVisible ? "Disable Crosshair Lines" : "Enable Crosshair Lines",
            action: #selector(toggleCrosshair),
            keyEquivalent: "c"
        )
        toggleItem.target = self
        toggleItem.keyEquivalentModifierMask = [.control, .shift, .command]
        menu.addItem(toggleItem)

        let cursorToggleItem = NSMenuItem(
            title: "Hide Native Cursor",
            action: #selector(toggleNativeCursor(_:)),
            keyEquivalent: "h"
        )
        cursorToggleItem.target = self
        cursorToggleItem.keyEquivalentModifierMask = [.control, .shift, .command]
        cursorToggleItem.state = settings.hideNativeCursor ? .on : .off
        menu.addItem(cursorToggleItem)

        menu.addItem(.separator())

        let appearanceMenu = NSMenu(title: "Crosshair Appearance")
        let colorMenu = NSMenu(title: "Color")
        for (index, color) in settings.colors.enumerated() {
            let item = NSMenuItem(
                title: settings.colorNames[index],
                action: #selector(selectColor(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = index
            item.isEnabled = true
            if color == settings.crosshairColor {
                item.state = .on
            }
            // Set a small colored swatch as the image for visual feedback
            let swatch = NSImage(size: NSSize(width: 12, height: 12))
            swatch.lockFocus()
            color.set()
            NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: 12, height: 12)).fill()
            swatch.unlockFocus()
            swatch.isTemplate = true
            item.image = swatch
            colorMenu.addItem(item)
        }
        let colorItem = NSMenuItem(title: "Color", action: nil, keyEquivalent: "")
        colorItem.submenu = colorMenu
        appearanceMenu.addItem(colorItem)

        let customLineColor = NSMenuItem(title: "Choose Custom…", action: #selector(chooseLineColor), keyEquivalent: "")
        customLineColor.target = self
        colorMenu.addItem(customLineColor)

        // Width submenu
        let widthMenu = NSMenu(title: "Width")
        for (index, width) in settings.widths.enumerated() {
            let item = NSMenuItem(
                title: "\(Int(width))px",
                action: #selector(selectWidth(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = index
            item.isEnabled = true
            if width == settings.lineWidth {
                item.state = .on
            }
            widthMenu.addItem(item)
        }
        let widthItem = NSMenuItem(title: "Width", action: nil, keyEquivalent: "")
        widthItem.submenu = widthMenu
        appearanceMenu.addItem(widthItem)

        // Pattern submenu
        let patternMenu = NSMenu(title: "Pattern")
        for (index, pattern) in [SettingsStore.LinePattern.solid, .dashed, .dotted].enumerated() {
            let item = NSMenuItem(
                title: pattern.description,
                action: #selector(selectPattern(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = index
            item.isEnabled = true
            if pattern == settings.pattern {
                item.state = .on
            }
            patternMenu.addItem(item)
        }
        let patternItem = NSMenuItem(title: "Pattern", action: nil, keyEquivalent: "")
        patternItem.submenu = patternMenu
        appearanceMenu.addItem(patternItem)

        let appearanceItem = NSMenuItem(title: "Crosshair Appearance", action: nil, keyEquivalent: "")
        appearanceItem.submenu = appearanceMenu
        menu.addItem(appearanceItem)

        let intersectionMenu = NSMenu(title: "Intersection")
        let dotToggleItem = NSMenuItem(
            title: "Show Intersection Dot",
            action: #selector(toggleDot(_:)),
            keyEquivalent: ""
        )
        dotToggleItem.target = self
        dotToggleItem.state = settings.showDot ? .on : .off
        intersectionMenu.addItem(dotToggleItem)

        let shapeMenu = NSMenu(title: "Intersection Shape")
        for (index, shape) in [SettingsStore.IntersectionShape.circle, .sniperAim, .cross, .plus, .diamond].enumerated() {
            let item = NSMenuItem(title: shape.description, action: #selector(selectShape(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            item.state = shape == settings.intersectionShape ? .on : .off
            shapeMenu.addItem(item)
        }
        let shapeItem = NSMenuItem(title: "Shape", action: nil, keyEquivalent: "")
        shapeItem.submenu = shapeMenu
        intersectionMenu.addItem(shapeItem)

        let dotColorMenu = NSMenu(title: "Dot Color")
        for (index, color) in settings.dotColors.enumerated() {
            let item = NSMenuItem(
                title: settings.dotColorNames[index],
                action: #selector(selectDotColor(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = index
            item.isEnabled = true
            if color == settings.dotColor {
                item.state = .on
            }
            // Set a small colored swatch as the image for visual feedback
            let swatch = NSImage(size: NSSize(width: 12, height: 12))
            swatch.lockFocus()
            color.set()
            NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: 12, height: 12)).fill()
            swatch.unlockFocus()
            swatch.isTemplate = true
            item.image = swatch
            dotColorMenu.addItem(item)
        }
        let dotColorItem = NSMenuItem(title: "Dot Color", action: nil, keyEquivalent: "")
        dotColorItem.submenu = dotColorMenu
        intersectionMenu.addItem(dotColorItem)

        let customDotColor = NSMenuItem(title: "Choose Custom…", action: #selector(chooseDotColor), keyEquivalent: "")
        customDotColor.target = self
        dotColorMenu.addItem(customDotColor)

        let shadeToggle = NSMenuItem(title: "Show Dot Shade", action: #selector(toggleDotShade(_:)), keyEquivalent: "")
        shadeToggle.target = self
        shadeToggle.state = settings.showDotShade ? .on : .off
        intersectionMenu.addItem(shadeToggle)

        let shadeColorItem = NSMenuItem(title: "Dot Shade Color…", action: #selector(chooseShadeColor), keyEquivalent: "")
        shadeColorItem.target = self
        intersectionMenu.addItem(shadeColorItem)

        let intersectionItem = NSMenuItem(title: "Intersection", action: nil, keyEquivalent: "")
        intersectionItem.submenu = intersectionMenu
        menu.addItem(intersectionItem)

        menu.addItem(.separator())
        
        let saveItem = NSMenuItem(title: "Save Settings", action: #selector(saveSettings), keyEquivalent: "")
        saveItem.target = self
        menu.addItem(saveItem)

        let restoreItem = NSMenuItem(title: "Restore Settings", action: #selector(restoreSettings), keyEquivalent: "")
        restoreItem.target = self
        menu.addItem(restoreItem)

        menu.addItem(.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit Crosshair Overlay",
            action: #selector(quit),
            keyEquivalent: ""
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        
    }


    @objc func toggleCrosshair() {
        overlayPanel.toggleVisibility()
        cursorController.apply(setting: settings.shouldHideNativeCursor)
        buildMenu()
    }

    @objc func selectColor(_ sender: NSMenuItem) {
        settings.crosshairColor = settings.colors[sender.tag]
        // Update checkmarks in color submenu
        if let menu = sender.menu {
            for item in menu.items where item.tag >= 0 && item.tag < settings.colors.count {
                item.state = (item.tag == sender.tag) ? .on : .off
            }
        }
        overlayPanel.redraw()
    }

    @objc func chooseLineColor() {
        showColorPanel(for: .crosshair, color: settings.crosshairColor)
    }

    @objc func chooseDotColor() {
        showColorPanel(for: .dot, color: settings.dotColor)
    }

    @objc func chooseShadeColor() {
        showColorPanel(for: .shade, color: settings.dotShadeColor)
    }

    private func showColorPanel(for selection: ColorSelection, color: NSColor) {
        colorSelection = selection
        let panel = NSColorPanel.shared
        panel.color = color
        panel.setTarget(self)
        panel.setAction(#selector(colorPanelChanged(_:)))
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
    }

    @objc func colorPanelChanged(_ sender: NSColorPanel) {
        switch colorSelection {
        case .crosshair: settings.crosshairColor = sender.color
        case .dot: settings.dotColor = sender.color
        case .shade: settings.dotShadeColor = sender.color
        }
        overlayPanel.redraw()
    }

    @objc func selectWidth(_ sender: NSMenuItem) {
        settings.lineWidth = settings.widths[sender.tag]
        if let menu = sender.menu {
            for item in menu.items where item.tag >= 0 && item.tag < settings.widths.count {
                item.state = (item.tag == sender.tag) ? .on : .off
            }
        }
        overlayPanel.redraw()
    }

    @objc func selectPattern(_ sender: NSMenuItem) {
        let patterns: [SettingsStore.LinePattern] = [.solid, .dashed, .dotted]
        settings.pattern = patterns[sender.tag]
        if let menu = sender.menu {
            for item in menu.items where item.tag >= 0 && item.tag < patterns.count {
                item.state = (item.tag == sender.tag) ? .on : .off
            }
        }
        overlayPanel.redraw()
    }

    @objc func toggleDot(_ sender: NSMenuItem) {
        settings.showDot.toggle()
        sender.state = settings.showDot ? .on : .off
        overlayPanel.redraw()
    }

    @objc func toggleDotShade(_ sender: NSMenuItem) {
        settings.showDotShade.toggle()
        sender.state = settings.showDotShade ? .on : .off
        overlayPanel.redraw()
    }

    func toggleNativeCursor() {
        settings.hideNativeCursor.toggle()
        cursorController.apply(setting: settings.shouldHideNativeCursor)
        buildMenu()
    }

    @objc func toggleNativeCursor(_ sender: NSMenuItem) {
        toggleNativeCursor()
    }

    @objc func selectDotColor(_ sender: NSMenuItem) {
        settings.dotColor = settings.dotColors[sender.tag]
        if let menu = sender.menu {
            for item in menu.items where item.tag >= 0 && item.tag < settings.dotColors.count {
                item.state = (item.tag == sender.tag) ? .on : .off
            }
        }
        overlayPanel.redraw()
    }

    @objc func saveSettings() {
        settings.save()
    }

    @objc func restoreSettings() {
        guard settings.restore() else { return }
        cursorController.apply(setting: settings.shouldHideNativeCursor)
        buildMenu()
        overlayPanel.redraw()
    }

    @objc func selectShape(_ sender: NSMenuItem) {
        let shapes: [SettingsStore.IntersectionShape] = [.circle, .sniperAim, .cross, .plus, .diamond]
        settings.intersectionShape = shapes[sender.tag]
        if let menu = sender.menu {
            for item in menu.items where item.tag >= 0 && item.tag < shapes.count {
                item.state = (item.tag == sender.tag) ? .on : .off
            }
        }
        overlayPanel.redraw()
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}
