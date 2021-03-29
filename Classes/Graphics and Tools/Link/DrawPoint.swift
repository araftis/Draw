
import AJRFoundation

public class DrawPoint : DrawGraphic {
/*
    public var radius : CGFloat {
        didSet {
            if radius < 0.1 {
                radius = 0.1
            }
            updateBounds()
        }
    }
    public var location : NSPoint {
        didSet {
            updateBounds()
        }
    }

    public init(_ frame: NSRect) {
        radius = 1.0
        location = frame.origin

        super.init(frame: NSRect(x: location.x - radius,
                                 y: location.y - radius,
                                 width: radius * 2.0,
                                 height: radius * 2.0))
        let fill = DrawColorFill(graphic: self)
        fill.color = NSColor.black
        super.addAspect(fill, with: .afterChildren)
    }

    public override func setFrame(_ frame: NSRect) -> NSRect {
        var dx : CGFloat
        var dy : CGFloat

        dx = frame.origin.x - self.frame().origin.x
        dy = frame.origin.y - self.frame().origin.y
        location.x += dx
        location.y += dy
        updateBounds()

        return NSRect(x: dx, y: dy, width: 1.0, height: 1.0)
    }

    public override func updateBounds() -> Void {
        super.updateBounds()
        path.removeAllPoints()

        path.appendOval(in: NSRect(x: location.x - radius,
                                   y: location.y - radius,
                                   width: radius * 2.0,
                                   height: radius * 2.0))
    }

    public override func addAspect(_ aspect: DrawAspect, with priority: DrawAspectPriority) {
    }

    public override func takeAspects(from otherGraphic: DrawGraphic) {
    }

    public override func removeAspect(_ aspect: DrawAspect) {
    }

    public override func drawHandles() {
        drawHandle(at: location)
    }

    public override func draw() {
        super.draw()

        if radius < 3.0 {
            let workPath = AJRBezierPath()

            workPath.appendOval(in: NSRect(x: location.x - 3.0,
                                           y: location.y - 3.0,
                                           width: 6.0,
                                           height: 6.0))
            workPath.lineWidth = AJRHairLineWidth

            NSColor.darkGray.set()
            workPath.stroke()
        }
    }

    public override func setHandle(_ handle: DrawHandle, toLocation point: NSPoint) -> DrawHandle {
        if handle.elementIndex == 0 {
            location = point
        }
        return handle
    }

    public override func handle(for point: NSPoint) -> DrawHandle {
        if self.isPoint(point, inHandleAt: location) {
            return DrawHandle(type: .indexed, elementIndex: 0, index: 0)
        }
        return DrawHandle(type: .missed, elementIndex: 0, index: 0)
    }

    public override func graphicsHit(by point: NSPoint) -> [DrawGraphic] {
        if let scale = self.page?.scale {
            if (radius * scale) < 3.0 {
                if self.isPoint(point, inHandleAt: location) {
                    return [self]
                }
            }
        }
        return super.graphicsHit(by: point)
    }

    // MARK: - AJRXMLCoding

    public override func decode(with coder: AJRXMLCoder) {
        super.decode(with: coder)

        coder.decodePoint(forKey: "location") { (point) in
            self.location = point
        }
        coder.decodeFloat(forKey: "radius") { (value) in
            self.radius = CGFloat(value)
        }
    }

    public override func encode(with coder: AJRXMLCoder) {
        super.encode(with: coder)

        coder.encode(location, forKey: "location")
        coder.encode(radius, forKey: "radius")
    }
*/
}
