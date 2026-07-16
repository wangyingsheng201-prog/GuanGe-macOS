import AppKit

final class GuideView: NSView {
    var settings: AppSettings {
        didSet { needsDisplay = true }
    }

    init(settings: AppSettings) {
        self.settings = settings
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) { nil }

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard settings.guidesVisible,
              let context = NSGraphicsContext.current?.cgContext else { return }

        let lineWidth = CGFloat(settings.lineWidth)
        let lineOpacity = CGFloat(settings.lineOpacity)
        let padding = max(1, lineWidth / 2 + 0.5)
        let canvas = bounds.insetBy(dx: padding, dy: padding)
        let frame = canvas.fitted(to: settings.frame.aspectRatio)
        let lineColor = NSColor(hex: settings.lineColor, alpha: lineOpacity).cgColor

        context.saveGState()
        context.setShouldAntialias(true)
        context.setLineWidth(lineWidth)
        context.setLineCap(.butt)
        context.setLineJoin(.miter)
        context.setStrokeColor(lineColor)
        context.setLineDash(phase: 0, lengths: [])

        context.stroke(frame)
        GuideRenderer.draw(settings.guide, in: frame, context: context)

        if settings.showDiagonals {
            context.move(to: CGPoint(x: frame.minX, y: frame.minY))
            context.addLine(to: CGPoint(x: frame.maxX, y: frame.maxY))
            context.move(to: CGPoint(x: frame.minX, y: frame.maxY))
            context.addLine(to: CGPoint(x: frame.maxX, y: frame.minY))
            context.strokePath()
        }

        if settings.showSafeFrame {
            let amount = CGFloat(max(1, min(99, 100 - settings.safePercent))) / 200
            let equalInset = min(frame.width, frame.height) * amount
            let safeRect = frame.insetBy(dx: equalInset, dy: equalInset)
            context.setStrokeColor(NSColor(hex: settings.safeColor, alpha: lineOpacity).cgColor)
            context.stroke(safeRect)
        }
        context.restoreGState()
    }
}

enum GuideRenderer {
    static func draw(_ preset: GuidePreset, in rect: CGRect, context: CGContext) {
        switch preset {
        case .thirds:
            grid(columns: 3, rows: 3, in: rect, context: context)
        case .halves:
            grid(columns: 2, rows: 2, in: rect, context: context)
        case .fourGrid:
            grid(columns: 4, rows: 4, in: rect, context: context)
        case .fiveGrid:
            grid(columns: 5, rows: 5, in: rect, context: context)
        case .phiGrid:
            phiGrid(in: rect, context: context)
        case .centerCross:
            line(CGPoint(x: rect.midX, y: rect.minY), CGPoint(x: rect.midX, y: rect.maxY), context)
            line(CGPoint(x: rect.minX, y: rect.midY), CGPoint(x: rect.maxX, y: rect.midY), context)
        case .goldenTriangleLeft:
            goldenTriangle(in: rect, reverse: false, context: context)
        case .goldenTriangleRight:
            goldenTriangle(in: rect, reverse: true, context: context)
        case .goldenSpiralTL:
            goldenSpiral(in: rect, horizontalFlip: false, verticalFlip: true, context: context)
        case .goldenSpiralTR:
            goldenSpiral(in: rect, horizontalFlip: true, verticalFlip: true, context: context)
        case .goldenSpiralBL:
            goldenSpiral(in: rect, horizontalFlip: false, verticalFlip: false, context: context)
        case .goldenSpiralBR:
            goldenSpiral(in: rect, horizontalFlip: true, verticalFlip: false, context: context)
        case .dynamicSymmetry:
            dynamicSymmetry(in: rect, context: context)
        }
    }

    private static func grid(columns: Int, rows: Int, in rect: CGRect, context: CGContext) {
        for column in 1..<columns {
            let x = rect.minX + rect.width * CGFloat(column) / CGFloat(columns)
            line(CGPoint(x: x, y: rect.minY), CGPoint(x: x, y: rect.maxY), context)
        }
        for row in 1..<rows {
            let y = rect.minY + rect.height * CGFloat(row) / CGFloat(rows)
            line(CGPoint(x: rect.minX, y: y), CGPoint(x: rect.maxX, y: y), context)
        }
    }

    private static func phiGrid(in rect: CGRect, context: CGContext) {
        let phi: CGFloat = 0.61803398875
        for factor in [1 - phi, phi] {
            let x = rect.minX + rect.width * factor
            let y = rect.minY + rect.height * factor
            line(CGPoint(x: x, y: rect.minY), CGPoint(x: x, y: rect.maxY), context)
            line(CGPoint(x: rect.minX, y: y), CGPoint(x: rect.maxX, y: y), context)
        }
    }

    private static func goldenTriangle(in rect: CGRect, reverse: Bool, context: CGContext) {
        let a = reverse ? CGPoint(x: rect.maxX, y: rect.minY) : CGPoint(x: rect.minX, y: rect.minY)
        let b = reverse ? CGPoint(x: rect.minX, y: rect.maxY) : CGPoint(x: rect.maxX, y: rect.maxY)
        line(a, b, context)

        let dx = b.x - a.x
        let dy = b.y - a.y
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else { return }

        func foot(from p: CGPoint) -> CGPoint {
            let t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSquared
            return CGPoint(x: a.x + t * dx, y: a.y + t * dy)
        }
        let corner1 = reverse ? CGPoint(x: rect.maxX, y: rect.maxY) : CGPoint(x: rect.minX, y: rect.maxY)
        let corner2 = reverse ? CGPoint(x: rect.minX, y: rect.minY) : CGPoint(x: rect.maxX, y: rect.minY)
        line(corner1, foot(from: corner1), context)
        line(corner2, foot(from: corner2), context)
    }

    private static func goldenSpiral(in rect: CGRect, horizontalFlip: Bool, verticalFlip: Bool, context: CGContext) {
        context.saveGState()
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: horizontalFlip ? rect.maxX : rect.minX, y: verticalFlip ? rect.maxY : rect.minY)
        transform = transform.scaledBy(x: horizontalFlip ? -1 : 1, y: verticalFlip ? -1 : 1)

        let w = rect.width
        let h = rect.height
        let phi: CGFloat = 1.61803398875
        let base = min(w / phi, h)
        let origin = CGPoint.zero.applying(transform)
        let scaleX = w / (base * phi)
        let scaleY = h / base

        context.translateBy(x: origin.x, y: origin.y)
        context.scaleBy(x: (horizontalFlip ? -1 : 1) * scaleX, y: (verticalFlip ? -1 : 1) * scaleY)

        var x: CGFloat = 0
        var y: CGFloat = 0
        var size = base
        var direction = 0
        for _ in 0..<9 {
            let arcRect: CGRect
            let start: CGFloat
            switch direction % 4 {
            case 0:
                arcRect = CGRect(x: x, y: y, width: size * 2, height: size * 2)
                start = .pi
                x += size
            case 1:
                arcRect = CGRect(x: x - size * 2, y: y, width: size * 2, height: size * 2)
                start = -.pi / 2
                y += size
            case 2:
                arcRect = CGRect(x: x - size * 2, y: y - size * 2, width: size * 2, height: size * 2)
                start = 0
                x -= size
            default:
                arcRect = CGRect(x: x, y: y - size * 2, width: size * 2, height: size * 2)
                start = .pi / 2
                y -= size
            }
            context.addArc(center: CGPoint(x: arcRect.midX, y: arcRect.midY), radius: size, startAngle: start, endAngle: start + .pi / 2, clockwise: false)
            context.strokePath()
            size /= phi
            direction += 1
        }
        context.restoreGState()
    }

    private static func dynamicSymmetry(in rect: CGRect, context: CGContext) {
        let tl = CGPoint(x: rect.minX, y: rect.maxY)
        let tr = CGPoint(x: rect.maxX, y: rect.maxY)
        let bl = CGPoint(x: rect.minX, y: rect.minY)
        let br = CGPoint(x: rect.maxX, y: rect.minY)
        line(bl, tr, context)
        line(br, tl, context)

        let k = rect.height / rect.width
        let reciprocalX = min(rect.width, rect.height * k)
        line(tl, CGPoint(x: rect.minX + reciprocalX, y: rect.minY), context)
        line(tr, CGPoint(x: rect.maxX - reciprocalX, y: rect.minY), context)
        line(bl, CGPoint(x: rect.minX + reciprocalX, y: rect.maxY), context)
        line(br, CGPoint(x: rect.maxX - reciprocalX, y: rect.maxY), context)
    }

    private static func line(_ from: CGPoint, _ to: CGPoint, _ context: CGContext) {
        context.move(to: from)
        context.addLine(to: to)
        context.strokePath()
    }
}
