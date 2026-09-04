import Cocoa
import Carbon
import Quartz
import CrosshairCore

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

        let opacityMenu = NSMenu(title: "Opacity")
        for (index, opacity) in [CGFloat(0.4), 0.6, 0.8, 1.0].enumerated() {
            let item = NSMenuItem(title: "\(Int(opacity * 100))%", action: #selector(selectOpacity(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            item.state = settings.opacity == opacity ? .on : .off
            opacityMenu.addItem(item)
        }
        let opacityItem = NSMenuItem(title: "Opacity", action: nil, keyEquivalent: "")
        opacityItem.submenu = opacityMenu
        appearanceMenu.addItem(opacityItem)

        let gapMenu = NSMenu(title: "Center Gap")
        for (index, gap) in [CGFloat(0), 4, 8, 12, 16].enumerated() {
            let item = NSMenuItem(title: "\(Int(gap))px", action: #selector(selectLineGap(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            item.state = settings.lineGap == gap ? .on : .off
            gapMenu.addItem(item)
        }
        let gapItem = NSMenuItem(title: "Center Gap", action: nil, keyEquivalent: "")
        gapItem.submenu = gapMenu
        appearanceMenu.addItem(gapItem)

        let offsetMenu = NSMenu(title: "Offset")
        for (index, title) in ["Up 5px", "Down 5px", "Left 5px", "Right 5px", "Reset Offset"].enumerated() {
            let item = NSMenuItem(title: title, action: #selector(adjustOffset(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            offsetMenu.addItem(item)
        }
        let offsetItem = NSMenuItem(title: "Offset", action: nil, keyEquivalent: "")
        offsetItem.submenu = offsetMenu
        appearanceMenu.addItem(offsetItem)

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
        for (index, shape) in ReticleStyle.allCases.enumerated() {
            let item = NSMenuItem(title: shape.title, action: #selector(selectShape(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            item.state = shape == settings.reticle ? .on : .off
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

        let presetsMenu = NSMenu(title: "Presets")
        for preset in settings.presetLibrary.presets {
            let item = NSMenuItem(title: preset.name, action: #selector(applyPreset(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = preset.name
            presetsMenu.addItem(item)
        }
        presetsMenu.addItem(.separator())
        let savePresetItem = NSMenuItem(title: "Save Current as Preset…", action: #selector(saveCurrentAsPreset), keyEquivalent: "")
        savePresetItem.target = self
        presetsMenu.addItem(savePresetItem)
        let nextPresetItem = NSMenuItem(title: "Next Preset", action: #selector(cyclePreset), keyEquivalent: "")
        nextPresetItem.target = self
        presetsMenu.addItem(nextPresetItem)
        let presetsItem = NSMenuItem(title: "Presets", action: nil, keyEquivalent: "")
        presetsItem.submenu = presetsMenu
        menu.addItem(presetsItem)

        let behaviorMenu = NSMenu(title: "Behavior")
        let holdItem = NSMenuItem(title: "Hold Option to Show", action: #selector(toggleHoldToShow(_:)), keyEquivalent: "")
        holdItem.target = self
        holdItem.state = settings.holdToShow ? .on : .off
        behaviorMenu.addItem(holdItem)
        let exclusionItem = NSMenuItem(title: "Toggle Exclusion for Frontmost App", action: #selector(toggleFrontmostApplicationExclusion), keyEquivalent: "")
        exclusionItem.target = self
        behaviorMenu.addItem(exclusionItem)
        let saveAppProfileItem = NSMenuItem(title: "Save Full Profile for Frontmost App", action: #selector(saveFrontmostApplicationProfile), keyEquivalent: "")
        saveAppProfileItem.target = self
        behaviorMenu.addItem(saveAppProfileItem)
        let clearAppProfileItem = NSMenuItem(title: "Clear Profile for Frontmost App", action: #selector(clearFrontmostApplicationProfile), keyEquivalent: "")
        clearAppProfileItem.target = self
        behaviorMenu.addItem(clearAppProfileItem)
        let fadeMenu = NSMenu(title: "Fade After Inactivity")
        for (index, seconds) in [TimeInterval(0), 1, 3, 5].enumerated() {
            let title = seconds == 0 ? "Never" : "\(Int(seconds)) seconds"
            let item = NSMenuItem(title: title, action: #selector(selectFadeDuration(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            item.state = settings.fadeAfterSeconds == seconds ? .on : .off
            fadeMenu.addItem(item)
        }
        let fadeItem = NSMenuItem(title: "Fade After Inactivity", action: nil, keyEquivalent: "")
        fadeItem.submenu = fadeMenu
        behaviorMenu.addItem(fadeItem)
        let displayItem = NSMenuItem(title: "Display: Active Monitor Only", action: nil, keyEquivalent: "")
        displayItem.isEnabled = false
        behaviorMenu.addItem(displayItem)
        let saveDisplayProfile = NSMenuItem(title: "Save Advanced Settings for Active Display", action: #selector(saveActiveDisplayProfile), keyEquivalent: "")
        saveDisplayProfile.target = self
        behaviorMenu.addItem(saveDisplayProfile)
        let clearDisplayProfile = NSMenuItem(title: "Clear Active Display Profile", action: #selector(clearActiveDisplayProfile), keyEquivalent: "")
        clearDisplayProfile.target = self
        clearDisplayProfile.isEnabled = settings.activeDisplayIdentifier != nil
        behaviorMenu.addItem(clearDisplayProfile)
        let cursorModeMenu = NSMenu(title: "Cursor Mode")
        for (index, mode) in CursorMode.allCases.enumerated() {
            let item = NSMenuItem(title: mode.title, action: #selector(selectCursorMode(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            item.state = mode == settings.cursorMode ? .on : .off
            cursorModeMenu.addItem(item)
        }
        let cursorModeItem = NSMenuItem(title: "Cursor Mode", action: nil, keyEquivalent: "")
        cursorModeItem.submenu = cursorModeMenu
        behaviorMenu.addItem(cursorModeItem)
        let behaviorItem = NSMenuItem(title: "Behavior", action: nil, keyEquivalent: "")
        behaviorItem.submenu = behaviorMenu
        menu.addItem(behaviorItem)

        let diagnosticsItem = NSMenuItem(title: "Diagnostics…", action: #selector(showDiagnostics), keyEquivalent: "")
        diagnosticsItem.target = self
        menu.addItem(diagnosticsItem)

        menu.addItem(.separator())
        
        let saveItem = NSMenuItem(title: "Save Settings", action: #selector(saveSettings), keyEquivalent: "")
        saveItem.target = self
        menu.addItem(saveItem)

        let restoreItem = NSMenuItem(title: "Restore Settings", action: #selector(restoreSettings), keyEquivalent: "")
        restoreItem.target = self
        menu.addItem(restoreItem)

        let exportItem = NSMenuItem(title: "Export Advanced Settings…", action: #selector(exportAdvancedSettings), keyEquivalent: "")
        exportItem.target = self
        menu.addItem(exportItem)

        let importItem = NSMenuItem(title: "Import Advanced Settings…", action: #selector(importAdvancedSettings), keyEquivalent: "")
        importItem.target = self
        menu.addItem(importItem)

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

    func adjustLineWidth(by step: Int) {
        let current = settings.widths.firstIndex(of: settings.lineWidth) ?? 0
        let index = min(max(current + step, 0), settings.widths.count - 1)
        settings.lineWidth = settings.widths[index]
        overlayPanel.redraw()
        buildMenu()
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

    @objc private func selectOpacity(_ sender: NSMenuItem) {
        settings.opacity = [CGFloat(0.4), 0.6, 0.8, 1.0][sender.tag]
        overlayPanel.redraw()
        buildMenu()
    }

    func adjustOpacity(by step: Int) {
        let values: [CGFloat] = [0.4, 0.6, 0.8, 1.0]
        let current = values.firstIndex(of: settings.opacity) ?? values.count - 1
        let index = min(max(current + step, 0), values.count - 1)
        settings.opacity = values[index]
        overlayPanel.updateCursorLocation(NSEvent.mouseLocation)
        buildMenu()
    }

    @objc private func selectLineGap(_ sender: NSMenuItem) {
        settings.lineGap = [CGFloat(0), 4, 8, 12, 16][sender.tag]
        overlayPanel.redraw()
        buildMenu()
    }

    @objc private func adjustOffset(_ sender: NSMenuItem) {
        switch sender.tag {
        case 0: settings.cursorOffset.y += 5
        case 1: settings.cursorOffset.y -= 5
        case 2: settings.cursorOffset.x -= 5
        case 3: settings.cursorOffset.x += 5
        default: settings.cursorOffset = .zero
        }
        overlayPanel.updateCursorLocation(NSEvent.mouseLocation)
        buildMenu()
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

    @objc private func exportAdvancedSettings() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "CrosshairOverlaySettings.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try ConfigurationExport(settings: settings.advancedSettings).encoded().write(to: url, options: .atomic)
        } catch {
            presentError(error)
        }
    }

    @objc private func importAdvancedSettings() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            settings.apply(try ConfigurationExport.decode(from: Data(contentsOf: url)).settings)
            cursorController.apply(setting: settings.shouldHideNativeCursor)
            overlayPanel.redraw()
            buildMenu()
        } catch {
            presentError(error)
        }
    }

    private func presentError(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
    }

    @objc func selectShape(_ sender: NSMenuItem) {
        let shapes = ReticleStyle.allCases
        settings.reticle = shapes[sender.tag]
        if let menu = sender.menu {
            for item in menu.items where item.tag >= 0 && item.tag < shapes.count {
                item.state = (item.tag == sender.tag) ? .on : .off
            }
        }
        overlayPanel.redraw()
    }

    @objc private func applyPreset(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String,
              let preset = settings.presetLibrary.settings(named: name) else { return }
        settings.apply(preset)
        overlayPanel.redraw()
        buildMenu()
    }

    @objc func cyclePreset() {
        guard let preset = settings.presetLibrary.next(after: nil) else { return }
        settings.apply(preset.settings)
        overlayPanel.redraw()
        buildMenu()
    }

    @objc private func saveCurrentAsPreset() {
        let alert = NSAlert()
        alert.messageText = "Save Crosshair Preset"
        alert.informativeText = "Enter a name for the current advanced crosshair settings."
        let nameField = NSTextField(string: "Custom Preset")
        nameField.frame = NSRect(x: 0, y: 0, width: 260, height: 24)
        alert.accessoryView = nameField
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        settings.presetLibrary.save(name: nameField.stringValue, settings: settings.advancedSettings)
        settings.save()
        buildMenu()
    }

    @objc private func toggleHoldToShow(_ sender: NSMenuItem) {
        settings.holdToShow.toggle()
        sender.state = settings.holdToShow ? .on : .off
    }

    @objc private func toggleFrontmostApplicationExclusion() {
        guard let bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
              bundleIdentifier != Bundle.main.bundleIdentifier else {
            let alert = NSAlert()
            alert.messageText = "Select another app first"
            alert.informativeText = "The Crosshair Overlay cannot exclude itself. Click the app you want to exclude, then reopen this menu."
            alert.runModal()
            return
        }
        if settings.excludedBundleIdentifiers.contains(bundleIdentifier) {
            settings.excludedBundleIdentifiers.remove(bundleIdentifier)
        } else {
            settings.excludedBundleIdentifiers.insert(bundleIdentifier)
        }
        buildMenu()
    }

    @objc private func saveFrontmostApplicationProfile() {
        guard let bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
              bundleIdentifier != Bundle.main.bundleIdentifier else { return }
        settings.saveAppProfile(bundleIdentifier)
        settings.save()
        buildMenu()
    }

    @objc private func clearFrontmostApplicationProfile() {
        guard let bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
              bundleIdentifier != Bundle.main.bundleIdentifier else { return }
        settings.removeAppProfile(bundleIdentifier)
        settings.save()
        buildMenu()
    }

    @objc private func selectFadeDuration(_ sender: NSMenuItem) {
        settings.fadeAfterSeconds = [TimeInterval(0), 1, 3, 5][sender.tag]
        overlayPanel.updateCursorLocation(NSEvent.mouseLocation)
        buildMenu()
    }

    @objc private func saveActiveDisplayProfile() {
        overlayPanel.updateCursorLocation(NSEvent.mouseLocation)
        settings.saveActiveDisplayProfile()
        settings.save()
        buildMenu()
    }

    @objc private func clearActiveDisplayProfile() {
        settings.removeActiveDisplayProfile()
        settings.save()
        buildMenu()
    }

    @objc private func selectCursorMode(_ sender: NSMenuItem) {
        settings.cursorMode = CursorMode.allCases[sender.tag]
        cursorController.apply(setting: settings.shouldHideNativeCursor && settings.cursorMode == .experimentalBackground)
        buildMenu()
    }


    @objc private func showDiagnostics() {
        let display = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) })
        let displayName = display?.localizedName ?? "Unavailable"
        let alert = NSAlert()
        alert.messageText = "Crosshair Overlay Diagnostics"
        alert.informativeText = """
        Active display: \(displayName)
        Crosshair lines: \(settings.isVisible ? "enabled" : "disabled")
        Cursor mode: \(settings.cursorMode.title)
        Cursor hiding effective: \(settings.shouldHideNativeCursor && settings.cursorMode == .experimentalBackground ? "yes" : "no")
        Opacity: \(Int(settings.opacity * 100))%
        Reticle: \(settings.reticle.title)
        Presets: \(settings.presetLibrary.presets.count)
        Excluded apps: \(settings.excludedBundleIdentifiers.count)
        """
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}
