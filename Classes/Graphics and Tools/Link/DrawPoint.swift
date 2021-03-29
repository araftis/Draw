/*
DrawPoint.swift
Draw

Copyright © 2021, AJ Raftis and AJRFoundation authors
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this 
  list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, 
  this list of conditions and the following disclaimer in the documentation 
  and/or other materials provided with the distribution.
* Neither the name of Draw nor the names of its contributors may be 
  used to endorse or promote products derived from this software without 
  specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL AJ RAFTIS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

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
