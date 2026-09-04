import Cocoa

@MainActor
class OverlayPanel: NSPanel {
    var crosshairView: CrosshairView!
    var settings: SettingsStore
    var cursorLocation: NSPoint = NSZeroPoint

    init(settings: SettingsStore) {
        self.settings = settings

        super.init(
            contentRect: NSRect.zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Stay above all windows but let clicks pass through
        self.level = .floating
        self.hasShadow = false
        self.backgroundColor = .clear
        self.isOpaque = false
        self.alphaValue = 1.0
        self.ignoresMouseEvents = true

        // Create crosshair view
        crosshairView = CrosshairView(settings: settings)
        self.contentView = crosshairView

        // Hide initially
        self.orderOut(nil)
    }

    func updateCursorLocation(_ location: NSPoint) {
        cursorLocation = location

        // Find the screen containing this point
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(location) }) else { return }

        // Resize panel to match screen frame
        self.setFrame(screen.frame, display: true, animate: false)

        // Update crosshair position and redraw
        crosshairView.cursorLocation = location
        crosshairView.needsDisplay = true

        // Show if visible
        if settings.isVisible {
            self.orderFront(nil)
        }
    }

    func toggleVisibility() {
        settings.isVisible.toggle()
        if settings.isVisible {
            updateCursorLocation(NSEvent.mouseLocation)
            self.orderFront(nil)
        } else {
            self.orderOut(nil)
        }
    }

    func redraw() {
        crosshairView.needsDisplay = true
    }
}

class CrosshairView: NSView {
    var settings: SettingsStore
    var cursorLocation: NSPoint = NSZeroPoint

    init(settings: SettingsStore) {
        self.settings = settings
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let bounds = self.bounds

        // Calculate cursor position relative to this view's coordinate system
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(cursorLocation) }) else { return }
        let originX = screen.frame.origin.x
        let originY = screen.frame.origin.y  // bottom of screen in macOS global coords

        // Convert to view-local coords (CoreGraphics uses bottom-left origin, same as macOS screen coords)
        let relativeX = cursorLocation.x - originX
        let relativeY = cursorLocation.y - originY

        // Clamp to bounds
        let clampedX = max(0, min(bounds.width, relativeX))
        let clampedY = max(0, min(bounds.height, relativeY))

        // Set up line drawing
        context.setStrokeColor(settings.crosshairColor.cgColor)
        context.setLineWidth(settings.lineWidth)

        switch settings.pattern {
        case .solid:
            context.setLineDash(phase: 0, lengths: [])
        case .dashed:
            context.setLineDash(phase: 0, lengths: [12.0, 6.0])
        case .dotted:
            context.setLineDash(phase: 0, lengths: [2.0, 4.0])
        }

        // Vertical crosshair line (full height)
        context.beginPath()
        context.move(to: NSPoint(x: clampedX, y: bounds.minY))
        context.addLine(to: NSPoint(x: clampedX, y: bounds.maxY))
        context.strokePath()

        // Horizontal crosshair line (full width)
        context.beginPath()
        context.move(to: NSPoint(x: bounds.minX, y: clampedY))
        context.addLine(to: NSPoint(x: bounds.maxX, y: clampedY))
        context.strokePath()

        // Draw intersection marker based on settings
        if settings.showDot {
            context.setLineDash(phase: 0, lengths: []) // Reset dash pattern
            
            switch settings.intersectionShape {
            case .circle:
                drawCircleMarker(context, x: clampedX, y: clampedY)
                
            case .sniperAim:
                drawSniperAimMarker(context, x: clampedX, y: clampedY)
                
            case .cross:
                drawCrossMarker(context, x: clampedX, y: clampedY)
                
            case .plus:
                drawPlusMarker(context, x: clampedX, y: clampedY)
                
            case .diamond:
                drawDiamondMarker(context, x: clampedX, y: clampedY)
            }
        }
    }
    
    private func drawCircleMarker(_ context: CGContext, x: CGFloat, y: CGFloat) {
        // Dot fill with configured color
        context.setFillColor(settings.dotColor.cgColor)
        context.beginPath()
        context.addArc(center: NSPoint(x: x, y: y), radius: 7.0, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.fillPath()
        
        // Black ring outline for contrast
        context.setFillColor(settings.dotShadeCGColor)
        context.beginPath()
        context.addArc(center: NSPoint(x: x, y: y), radius: 3.0, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.fillPath()
    }
    
    private func drawSniperAimMarker(_ context: CGContext, x: CGFloat, y: CGFloat) {
        let outerRadius: CGFloat = 10.0
        let innerRadius: CGFloat = 4.0
        let lineWidth: CGFloat = 2.0
        
        context.setStrokeColor(settings.dotShadeCGColor)
        context.setLineWidth(lineWidth + 2)
        context.beginPath()
        context.addArc(center: NSPoint(x: x, y: y), radius: outerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.strokePath()
        context.beginPath()
        context.addArc(center: NSPoint(x: x, y: y), radius: innerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.strokePath()

        // Dot-color circles over the configured shade outline.
        context.setStrokeColor(settings.dotColor.cgColor)
        context.setLineWidth(lineWidth)
        context.beginPath()
        context.addArc(center: NSPoint(x: x, y: y), radius: outerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.strokePath()
        
        // Inner circle (dot color with black outline)
        context.beginPath()
        context.addArc(center: NSPoint(x: x, y: y), radius: innerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.strokePath()
        
        // Crosshair lines (small gaps at cardinal points)
        let gapSize: CGFloat = 3.0
        
        // Top line
        context.beginPath()
        context.move(to: NSPoint(x: x, y: y + innerRadius))
        context.addLine(to: NSPoint(x: x, y: y + outerRadius - gapSize))
        context.strokePath()
        
        // Bottom line
        context.beginPath()
        context.move(to: NSPoint(x: x, y: y - innerRadius))
        context.addLine(to: NSPoint(x: x, y: y - outerRadius + gapSize))
        context.strokePath()
        
        // Left line
        context.beginPath()
        context.move(to: NSPoint(x: x - innerRadius, y: y))
        context.addLine(to: NSPoint(x: x - outerRadius + gapSize, y: y))
        context.strokePath()
        
        // Right line
        context.beginPath()
        context.move(to: NSPoint(x: x + innerRadius, y: y))
        context.addLine(to: NSPoint(x: x + outerRadius - gapSize, y: y))
        context.strokePath()
        
        // Center dot (small dot color circle)
        context.setFillColor(settings.dotColor.cgColor)
        context.beginPath()
        context.addArc(center: NSPoint(x: x, y: y), radius: 1.5, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.fillPath()
    }
    
    private func drawCrossMarker(_ context: CGContext, x: CGFloat, y: CGFloat) {
        let size: CGFloat = 8.0
        let lineWidth: CGFloat = 3.0
        
        // Dot color cross with black outline effect (draw black slightly larger first)
        context.setStrokeColor(settings.dotShadeCGColor)
        context.setLineWidth(lineWidth + 2)
        
        // Vertical bar
        context.beginPath()
        context.move(to: NSPoint(x: x, y: y - size))
        context.addLine(to: NSPoint(x: x, y: y + size))
        context.strokePath()
        
        // Horizontal bar
        context.beginPath()
        context.move(to: NSPoint(x: x - size, y: y))
        context.addLine(to: NSPoint(x: x + size, y: y))
        context.strokePath()
        
        // Dot color cross on top (slightly smaller for outline effect)
        context.setStrokeColor(settings.dotColor.cgColor)
        context.setLineWidth(lineWidth)
        
        // Vertical bar
        context.beginPath()
        context.move(to: NSPoint(x: x, y: y - size))
        context.addLine(to: NSPoint(x: x, y: y + size))
        context.strokePath()
        
        // Horizontal bar
        context.beginPath()
        context.move(to: NSPoint(x: x - size, y: y))
        context.addLine(to: NSPoint(x: x + size, y: y))
        context.strokePath()
    }
    
    private func drawPlusMarker(_ context: CGContext, x: CGFloat, y: CGFloat) {
        let size: CGFloat = 6.0
        let lineWidth: CGFloat = 3.0
        
        // Dot color plus sign with black outline effect
        context.setStrokeColor(settings.dotShadeCGColor)
        context.setLineWidth(lineWidth + 2)
        
        // Vertical bar
        context.beginPath()
        context.move(to: NSPoint(x: x, y: y - size))
        context.addLine(to: NSPoint(x: x, y: y + size))
        context.strokePath()
        
        // Horizontal bar
        context.beginPath()
        context.move(to: NSPoint(x: x - size, y: y))
        context.addLine(to: NSPoint(x: x + size, y: y))
        context.strokePath()
        
        // Dot color plus on top (slightly smaller for outline effect)
        context.setStrokeColor(settings.dotColor.cgColor)
        context.setLineWidth(lineWidth)
        
        // Vertical bar
        context.beginPath()
        context.move(to: NSPoint(x: x, y: y - size))
        context.addLine(to: NSPoint(x: x, y: y + size))
        context.strokePath()
        
        // Horizontal bar
        context.beginPath()
        context.move(to: NSPoint(x: x - size, y: y))
        context.addLine(to: NSPoint(x: x + size, y: y))
        context.strokePath()
    }
    
    private func drawDiamondMarker(_ context: CGContext, x: CGFloat, y: CGFloat) {
        let size: CGFloat = 8.0
        
        // Black outline diamond (slightly larger)
        context.setStrokeColor(settings.dotShadeCGColor)
        context.setLineWidth(3.0)
        context.beginPath()
        context.move(to: NSPoint(x: x, y: y + size))
        context.addLine(to: NSPoint(x: x + size, y: y))
        context.addLine(to: NSPoint(x: x, y: y - size))
        context.addLine(to: NSPoint(x: x - size, y: y))
        context.closePath()
        context.strokePath()
        
        // Dot color filled diamond (slightly smaller)
        let innerSize: CGFloat = 6.0
        context.setFillColor(settings.dotColor.cgColor)
        context.beginPath()
        context.move(to: NSPoint(x: x, y: y + innerSize))
        context.addLine(to: NSPoint(x: x + innerSize, y: y))
        context.addLine(to: NSPoint(x: x, y: y - innerSize))
        context.addLine(to: NSPoint(x: x - innerSize, y: y))
        context.closePath()
        context.fillPath()
        
        // Center dot (small black circle)
        context.setFillColor(settings.dotShadeCGColor)
        context.beginPath()
        context.addArc(center: NSPoint(x: x, y: y), radius: 1.5, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.fillPath()
    }
}
