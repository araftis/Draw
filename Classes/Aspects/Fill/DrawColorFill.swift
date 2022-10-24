/*
DrawColorFill.m
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

import AJRInterface

//NSString * const DrawColorFillIdentifier = @"DrawColorFillIdentifier";
public let DrawFillColorKey = "fillColor"

public extension AJRUserDefaultsKey {
    static var fillColor : AJRUserDefaultsKey<NSColor> {
        return AJRUserDefaultsKey<NSColor>.key(named: DrawFillColorKey, defaultValue: NSColor(srgbRed: 1.0, green: 0.7, blue: 1.0, alpha: 1.0))
    }
}

@objcMembers
open class DrawColorFill : DrawFill {

    // MARK: - Properties
    open var color : NSColor {
        didSet(newValue) {
            graphic?.setNeedsDisplay()
        }
    }

    // MARK: - Creation

    override class open func defaultAspect(for graphic: DrawGraphic) -> DrawAspect? {
        return DrawColorFill(graphic: graphic)
    }

    required public override init() {
        color = NSColor.black // Doesn't matter, it's going to be overwritten.
        super.init()
    }

    public override init(graphic: DrawGraphic?) {
        color = UserDefaults[.fillColor]!
        super.init(graphic: graphic)
    }

    // MARK: - DrawAspect

    override open func draw(_ path: AJRBezierPath, with priority: DrawAspectPriority) -> DrawGraphicCompletionBlock? {
        if let graphic = graphic {
            if graphic.isDescendant(of: graphic.document?.focusedGroup) {
                color.set()
            } else {
                NSColor.lightGray.set()
            }
            path.flatness = graphic.flatness
            path.windingRule = windingRule
            path.fill()
        }

        return nil
    }

    // MARK: - NSCopying

    open override func copy(with zone: NSZone?) -> Any {
        let aspect = super.copy(with: zone) as! DrawColorFill
        aspect.color = color
        return aspect
    }

    // MARK: - AJRXMLCoding

    open class override var ajr_nameForXMLArchiving: String {
        return "colorFill"
    }

    open override func decode(with coder: AJRXMLCoder) {
        super.decode(with: coder)

        coder.decodeObject(forKey: "color") { object in
            if let color = object as? NSColor {
                self.color = color
            }
        }
    }

    open override func encode(with coder: AJRXMLCoder) {
        super.encode(with: coder)
        coder.encode(color, forKey: "color")
    }

}
