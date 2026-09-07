import Cocoa
import CrosshairCore

@MainActor
final class SettingsWindowController: NSWindowController {
    private let settings: SettingsStore
    private let overlayPanel: OverlayPanel
    private let cursorController: CursorController
    private var profileTargetBundleIdentifier: String?

    private var crosshairSwitch: NSSwitch!
    private var cursorSwitch: NSSwitch!
    private var opacitySlider: NSSlider!
    private var opacityValue: NSTextField!
    private var gapSlider: NSSlider!
    private var gapValue: NSTextField!
    private var lineWidthSlider: NSSlider!
    private var lineWidthValue: NSTextField!
    private var lineColorPopup: NSPopUpButton!
    private var patternPopup: NSPopUpButton!
    private var dotSwitch: NSSwitch!
    private var dotShadeSwitch: NSSwitch!
    private var reticlePopup: NSPopUpButton!
    private var dotColorPopup: NSPopUpButton!
    private var shadeColorPopup: NSPopUpButton!
    private var optionKeyPopup: NSPopUpButton!
    private var fadeSlider: NSSlider!
    private var fadeValue: NSTextField!
    private var cursorModePopup: NSPopUpButton!
    private var presetPopup: NSPopUpButton!

    init(settings: SettingsStore, overlayPanel: OverlayPanel, cursorController: CursorController) {
        self.settings = settings
        self.overlayPanel = overlayPanel
        self.cursorController = cursorController

        let tabs = NSTabView()
        tabs.tabViewType = .topTabsBezelBorder
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 246),
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.isMovableByWindowBackground = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        let roundedContent = NSView()
        roundedContent.wantsLayer = true
        roundedContent.layer?.backgroundColor = NSColor.white.cgColor
        roundedContent.layer?.cornerRadius = 12
        roundedContent.layer?.masksToBounds = true
        tabs.translatesAutoresizingMaskIntoConstraints = false
        roundedContent.addSubview(tabs)
        NSLayoutConstraint.activate([
            tabs.leadingAnchor.constraint(equalTo: roundedContent.leadingAnchor),
            tabs.trailingAnchor.constraint(equalTo: roundedContent.trailingAnchor),
            tabs.topAnchor.constraint(equalTo: roundedContent.topAnchor, constant: 8),
            tabs.bottomAnchor.constraint(equalTo: roundedContent.bottomAnchor)
        ])
        panel.contentView = roundedContent
        panel.level = NSWindow.Level(rawValue: OverlayWindowLevelPolicy.settingsWindowRawValue)

        super.init(window: panel)
        configureTabs(tabs)
        refresh()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(relativeTo statusButton: NSStatusBarButton?) {
        refresh()
        guard let window else { return }
        if let statusButton, let statusWindow = statusButton.window {
            let statusFrame = statusButton.convert(statusButton.bounds, to: nil)
            let screenFrame = statusWindow.convertToScreen(statusFrame)
            let gap = screenFrame.height * 0.01
            window.setFrameTopLeftPoint(NSPoint(
                x: screenFrame.midX - (window.frame.width / 2),
                y: screenFrame.minY - gap
            ))
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func setProfileTarget(_ bundleIdentifier: String?) {
        profileTargetBundleIdentifier = bundleIdentifier
    }

    func refresh() {
        guard crosshairSwitch != nil else { return }
        crosshairSwitch.state = settings.isVisible ? .on : .off
        cursorSwitch.state = settings.hideNativeCursor ? .on : .off
        opacitySlider.doubleValue = settings.opacity
        opacityValue.stringValue = "\(Int(settings.opacity * 100))%"
        gapSlider.doubleValue = settings.lineGap
        gapValue.stringValue = "\(Int(settings.lineGap)) px"
        lineWidthSlider.doubleValue = settings.lineWidth
        lineWidthValue.stringValue = "\(Int(settings.lineWidth)) px"
        selectColor(settings.crosshairColor, in: lineColorPopup)
        patternPopup.selectItem(withTitle: settings.pattern.description)
        dotSwitch.state = settings.showDot ? .on : .off
        dotShadeSwitch.state = settings.showDotShade ? .on : .off
        reticlePopup.selectItem(withTitle: settings.reticle.title)
        selectColor(settings.dotColor, in: dotColorPopup)
        selectColor(settings.dotShadeColor, in: shadeColorPopup)
        optionKeyPopup.selectItem(at: optionKeySelectionIndex)
        fadeSlider.doubleValue = settings.fadeAfterSeconds
        fadeValue.stringValue = settings.fadeAfterSeconds == 0 ? "Never" : "\(Int(settings.fadeAfterSeconds)) s"
        cursorModePopup.selectItem(withTitle: settings.cursorMode.title)
        presetPopup.removeAllItems()
        presetPopup.addItems(withTitles: settings.presetLibrary.names)
    }

    private func configureTabs(_ tabs: NSTabView) {
        tabs.addTabViewItem(makePane(.general, content: generalContent()))
        tabs.addTabViewItem(makePane(.appearance, content: appearanceContent()))
        tabs.addTabViewItem(makePane(.reticle, content: reticleContent()))
        tabs.addTabViewItem(makePane(.behavior, content: behaviorContent()))
        tabs.addTabViewItem(makePane(.profiles, content: profilesContent()))
        tabs.addTabViewItem(makePane(.about, content: aboutContent()))
    }

    private func makePane(_ tab: SettingsTab, content: NSView) -> NSTabViewItem {
        let item = NSTabViewItem(identifier: tab)
        item.label = tab.title
        item.image = NSImage(systemSymbolName: tab.symbolName, accessibilityDescription: tab.title)
        item.view = content
        return item
    }

    private func contentStack() -> NSStackView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 18, left: 22, bottom: 18, right: 22)
        stack.translatesAutoresizingMaskIntoConstraints = false
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 340))
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor)
        ])
        stack.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return stack
    }

    private func generalContent() -> NSView {
        let stack = contentStack()
        crosshairSwitch = makeSwitch(action: #selector(crosshairChanged(_:)))
        cursorSwitch = makeSwitch(action: #selector(cursorChanged(_:)))
        opacitySlider = makeSlider(minimum: 0.1, maximum: 1, action: #selector(opacityChanged(_:)))
        opacityValue = valueLabel()
        gapSlider = makeSlider(minimum: 0, maximum: 100, action: #selector(gapChanged(_:)))
        gapValue = valueLabel()
        addRow("Crosshair Lines", control: crosshairSwitch, to: stack)
        addRow("Hide Native Cursor", control: cursorSwitch, to: stack)
        addRow("Opacity", control: sliderRow(opacitySlider, opacityValue), to: stack)
        addRow("Center Gap", control: sliderRow(gapSlider, gapValue), to: stack)
        let container = stack.superview!
        let quitButton = NSButton(title: "Quit Crosshair Overlay", target: self, action: #selector(quit))
        quitButton.bezelStyle = .rounded
        quitButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(quitButton)
        NSLayoutConstraint.activate([
            quitButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -22),
            quitButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -18)
        ])
        return container
    }

    private func appearanceContent() -> NSView {
        let stack = contentStack()
        lineWidthSlider = makeSlider(minimum: 1, maximum: 5, action: #selector(lineWidthChanged(_:)))
        lineWidthSlider.numberOfTickMarks = 5
        lineWidthSlider.allowsTickMarkValuesOnly = true
        lineWidthValue = valueLabel()
        lineColorPopup = makePopup(settings.colorNames, action: #selector(lineColorChanged(_:)))
        patternPopup = makePopup(["Solid", "Dashed", "Dotted"], action: #selector(patternChanged(_:)))
        addRow("Line Width", control: sliderRow(lineWidthSlider, lineWidthValue), to: stack)
        addRow("Line Color", control: lineColorPopup, to: stack)
        addRow("Line Pattern", control: patternPopup, to: stack)
        return stack.superview!
    }

    private func reticleContent() -> NSView {
        let stack = contentStack()
        dotSwitch = makeSwitch(action: #selector(dotChanged(_:)))
        dotShadeSwitch = makeSwitch(action: #selector(dotShadeChanged(_:)))
        reticlePopup = makePopup(ReticleStyle.allCases.map(\.title), action: #selector(reticleChanged(_:)))
        dotColorPopup = makePopup(settings.dotColorNames, action: #selector(dotColorChanged(_:)))
        shadeColorPopup = makePopup(settings.dotColorNames, action: #selector(shadeColorChanged(_:)))
        addRow("Show Intersection Dot", control: dotSwitch, to: stack)
        addRow("Show Dot Shade", control: dotShadeSwitch, to: stack)
        addRow("Reticle Shape", control: reticlePopup, to: stack)
        addRow("Dot Color", control: dotColorPopup, to: stack)
        addRow("Shade Color", control: shadeColorPopup, to: stack)
        return stack.superview!
    }

    private func behaviorContent() -> NSView {
        let stack = contentStack()
        optionKeyPopup = makePopup(["Off", OptionKeyBehavior.showCrosshair.title, OptionKeyBehavior.toggleNativeCursor.title], action: #selector(optionKeyChanged(_:)))
        fadeSlider = makeSlider(minimum: 0, maximum: 60, action: #selector(fadeChanged(_:)))
        fadeValue = valueLabel()
        cursorModePopup = makePopup(CursorMode.allCases.map(\.title), action: #selector(cursorModeChanged(_:)))
        addRow("Option Key", control: optionKeyPopup, to: stack)
        addRow("Fade After Inactivity", control: sliderRow(fadeSlider, fadeValue), to: stack)
        addRow("Cursor Mode", control: cursorModePopup, to: stack)
        return stack.superview!
    }

    private func profilesContent() -> NSView {
        let stack = contentStack()
        presetPopup = makePopup(settings.presetLibrary.names, action: #selector(presetChanged(_:)))
        addRow("Apply Preset", control: presetPopup, to: stack)
        addButtonRow("Save Settings", action: #selector(saveSettings))
        addButtonRow("Restore Settings", action: #selector(restoreSettings))
        addButtonRow("Save Profile for Frontmost App", action: #selector(saveFrontmostApplicationProfile))
        addButtonRow("Clear Profile for Frontmost App", action: #selector(clearFrontmostApplicationProfile))
        return stack.superview!

        func addButtonRow(_ title: String, action: Selector) {
            let button = NSButton(title: title, target: self, action: action)
            button.bezelStyle = .rounded
            stack.addArrangedSubview(button)
        }
    }

    private func aboutContent() -> NSView {
        let stack = contentStack()
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let title = NSTextField(labelWithString: AboutInformation.appName)
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        let details = NSTextField(wrappingLabelWithString: "Version \(version)\nCreated by \(AboutInformation.author)\n\(AboutInformation.creationCredit)\n\n\(AboutInformation.repositoryURL.absoluteString)")
        details.textColor = .secondaryLabelColor
        details.maximumNumberOfLines = 0
        let github = NSButton(title: "Open GitHub", target: self, action: #selector(openGitHub))
        github.bezelStyle = .rounded
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(details)
        stack.addArrangedSubview(github)
        return stack.superview!
    }

    private func makeSwitch(action: Selector) -> NSSwitch {
        let control = NSSwitch()
        control.target = self
        control.action = action
        return control
    }

    private func makeSlider(minimum: Double, maximum: Double, action: Selector) -> NSSlider {
        let slider = NSSlider(value: minimum, minValue: minimum, maxValue: maximum, target: self, action: action)
        slider.widthAnchor.constraint(equalToConstant: 180).isActive = true
        return slider
    }

    private func makePopup(_ titles: [String], action: Selector) -> NSPopUpButton {
        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        popup.addItems(withTitles: titles)
        popup.target = self
        popup.action = action
        popup.widthAnchor.constraint(equalToConstant: 210).isActive = true
        return popup
    }

    private func valueLabel() -> NSTextField {
        let label = NSTextField(labelWithString: "")
        label.alignment = .right
        label.widthAnchor.constraint(equalToConstant: 48).isActive = true
        return label
    }

    private func sliderRow(_ slider: NSSlider, _ value: NSTextField) -> NSStackView {
        let row = NSStackView(views: [slider, value])
        row.orientation = .horizontal
        row.spacing = 8
        return row
    }

    private func addRow(_ title: String, control: NSView, to stack: NSStackView) {
        let label = NSTextField(labelWithString: title)
        label.widthAnchor.constraint(equalToConstant: 170).isActive = true
        let row = NSStackView(views: [label, control])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        stack.addArrangedSubview(row)
    }

    private var optionKeySelectionIndex: Int {
        guard settings.holdToShow else { return 0 }
        return settings.optionKeyBehavior == .showCrosshair ? 1 : 2
    }

    private func selectColor(_ color: NSColor, in popup: NSPopUpButton) {
        if let index = paletteIndex(for: color) {
            popup.selectItem(at: index)
            return
        }

        let customTitle = "Custom Color"
        if popup.item(withTitle: customTitle) == nil {
            popup.addItem(withTitle: customTitle)
        }
        popup.selectItem(withTitle: customTitle)
    }

    private func paletteIndex(for color: NSColor) -> Int? {
        let resolvedColor = color.usingColorSpace(.deviceRGB) ?? color
        return settings.colors.firstIndex { candidate in
            let resolvedCandidate = candidate.usingColorSpace(.deviceRGB) ?? candidate
            return abs(resolvedColor.redComponent - resolvedCandidate.redComponent) < 0.001
                && abs(resolvedColor.greenComponent - resolvedCandidate.greenComponent) < 0.001
                && abs(resolvedColor.blueComponent - resolvedCandidate.blueComponent) < 0.001
                && abs(resolvedColor.alphaComponent - resolvedCandidate.alphaComponent) < 0.001
        }
    }

    private func applyChanges() {
        settings.save()
        cursorController.apply(setting: settings.shouldHideNativeCursor && settings.cursorMode == .experimentalBackground)
        // Native AppKit controls can reveal the cursor while they dismiss.
        // Reassert after the control action without changing cursor-hide
        // ownership or adding work to the cursor-tracking timer.
        cursorController.reassertHidden()
        overlayPanel.updateCursorLocation(NSEvent.mouseLocation)
        overlayPanel.redraw()
        refresh()
    }

    @objc private func crosshairChanged(_ sender: NSSwitch) { settings.isVisible = sender.state == .on; applyChanges() }
    @objc private func cursorChanged(_ sender: NSSwitch) { settings.hideNativeCursor = sender.state == .on; applyChanges() }
    @objc private func opacityChanged(_ sender: NSSlider) { settings.opacity = sender.doubleValue; applyChanges() }
    @objc private func gapChanged(_ sender: NSSlider) { settings.lineGap = sender.doubleValue; applyChanges() }
    @objc private func lineWidthChanged(_ sender: NSSlider) { settings.lineWidth = sender.doubleValue.rounded(); applyChanges() }
    @objc private func dotChanged(_ sender: NSSwitch) { settings.showDot = sender.state == .on; applyChanges() }
    @objc private func dotShadeChanged(_ sender: NSSwitch) { settings.showDotShade = sender.state == .on; applyChanges() }
    @objc private func fadeChanged(_ sender: NSSlider) { settings.fadeAfterSeconds = sender.doubleValue.rounded(); applyChanges() }

    @objc private func lineColorChanged(_ sender: NSPopUpButton) { selectColor(sender, apply: { settings.crosshairColor = $0 }) }
    @objc private func dotColorChanged(_ sender: NSPopUpButton) { selectColor(sender, apply: { settings.dotColor = $0 }) }
    @objc private func shadeColorChanged(_ sender: NSPopUpButton) { selectColor(sender, apply: { settings.dotShadeColor = $0 }) }

    private func selectColor(_ popup: NSPopUpButton, apply: (NSColor) -> Void) {
        guard popup.indexOfSelectedItem >= 0,
              popup.indexOfSelectedItem < settings.colors.count else { return }
        apply(settings.colors[popup.indexOfSelectedItem])
        applyChanges()
    }

    @objc private func patternChanged(_ sender: NSPopUpButton) {
        settings.pattern = SettingsStore.LinePattern.from(description: sender.titleOfSelectedItem ?? "") ?? settings.pattern
        applyChanges()
    }

    @objc private func reticleChanged(_ sender: NSPopUpButton) {
        guard let title = sender.titleOfSelectedItem,
              let reticle = ReticleStyle.allCases.first(where: { $0.title == title }) else { return }
        settings.reticle = reticle
        applyChanges()
    }

    @objc private func optionKeyChanged(_ sender: NSPopUpButton) {
        switch sender.indexOfSelectedItem {
        case 1:
            settings.holdToShow = true
            settings.optionKeyBehavior = .showCrosshair
        case 2:
            settings.holdToShow = true
            settings.optionKeyBehavior = .toggleNativeCursor
        default:
            settings.holdToShow = false
        }
        applyChanges()
    }

    @objc private func cursorModeChanged(_ sender: NSPopUpButton) {
        guard let title = sender.titleOfSelectedItem,
              let mode = CursorMode.allCases.first(where: { $0.title == title }) else { return }
        settings.cursorMode = mode
        applyChanges()
    }

    @objc private func presetChanged(_ sender: NSPopUpButton) {
        guard let name = sender.titleOfSelectedItem,
              let preset = settings.presetLibrary.settings(named: name) else { return }
        settings.apply(preset)
        applyChanges()
    }

    @objc private func saveSettings() { settings.save() }

    @objc private func restoreSettings() {
        guard settings.restore() else { return }
        applyChanges()
    }

    @objc private func saveFrontmostApplicationProfile() {
        guard let bundleIdentifier = profileTargetBundleIdentifier,
              bundleIdentifier != Bundle.main.bundleIdentifier else { return }
        settings.saveAppProfile(bundleIdentifier)
        settings.save()
    }

    @objc private func clearFrontmostApplicationProfile() {
        guard let bundleIdentifier = profileTargetBundleIdentifier,
              bundleIdentifier != Bundle.main.bundleIdentifier else { return }
        settings.removeAppProfile(bundleIdentifier)
        applyChanges()
    }

    @objc private func openGitHub() {
        NSWorkspace.shared.open(AboutInformation.repositoryURL)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
