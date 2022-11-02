/*
 DrawShadow.swift
 Draw

 Copyright © 2022, AJ Raftis and Draw authors
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

import AJRInterface

let DrawShadowIdentifier = "shadow"

@objcMembers
open class DrawShadow : DrawAspect {

    // MARK: - Creation

    internal static func createDefaultShadow() -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor(calibratedWhite: 0.0, alpha: 1.0/4.0)
        shadow.shadowOffset = NSSize(width: 0.0, height: -4.0)
        shadow.shadowBlurRadius = 10.0
        return shadow
    }

    public required init() {
        shadow = DrawShadow.createDefaultShadow()
        super.init()
    }

    public override init(graphic: DrawGraphic?) {
        shadow = DrawShadow.createDefaultShadow()
        super.init(graphic: graphic)
    }

    // MARK: - Properties

    open var shadow : NSShadow

    open var color : NSColor {
        get {
            return shadow.shadowColor ?? NSColor(calibratedWhite: 0.0, alpha: 1.0 / 4.0)
        }
        set {
            shadow.shadowColor = newValue
            graphic?.setNeedsDisplay()
        }
    }

    open var offset : NSSize {
        get {
            return shadow.shadowOffset
        }
        set {
            shadow.shadowOffset = newValue
            graphic?.setNeedsDisplay()
        }
    }

    open var blurRadius : CGFloat {
        get {
            return shadow.shadowBlurRadius
        }
        set {
            shadow.shadowBlurRadius = newValue
            graphic?.setNeedsDisplay()
        }
    }

    // MARK: - DrawAspect

    open override func draw(_ path: AJRBezierPath, with priority: DrawAspectPriority) -> DrawGraphicCompletionBlock? {
        if let context = AJRGetCurrentContext(), let graphic {
            context.saveGState()
            shadow.set()
            context.beginTransparencyLayer(in: graphic.dirtyBounds, auxiliaryInfo: nil)
            return {
                context.endTransparencyLayer()
                context.restoreGState()
            }
        }
        return nil
    }

    open override func bounds(forGraphicBounds graphicBounds: NSRect) -> NSRect {
        var bounds = graphicBounds

        bounds = bounds.insetBy(dx: -(shadow.shadowBlurRadius + 2.0), dy: -(shadow.shadowBlurRadius + 2.0))
        bounds.origin.x += shadow.shadowOffset.width
        bounds.origin.y += shadow.shadowOffset.height

        return graphicBounds.union(bounds)
    }

    open override var boundsExpandsGraphicBounds: Bool {
        return true
    }

    open class override func defaultAspect(for graphic: DrawGraphic) -> DrawAspect? {
        return DrawShadow(graphic: graphic)
    }

    // MARK: - AJRXMLCoding

    open class override var ajr_nameForXMLArchiving: String {
        return "shadow"
    }

    open override func decode(with coder: AJRXMLCoder) {
        super.decode(with: coder)

        coder.decodeObject(forKey: "shadow") { value in
            self.shadow = value as? NSShadow ?? DrawShadow.createDefaultShadow()
        }
    }

    open override func encode(with coder: AJRXMLCoder) {
        super.encode(with: coder)
        coder.encode(shadow, forKey: "shadow")
    }

    // MARK: - NSCopying

    open override func copy(with zone: NSZone? = nil) -> Any {
        let new = super.copy(with: zone) as! DrawShadow
        new.shadow = shadow.copy(with: zone) as! NSShadow
        return new
    }

}
