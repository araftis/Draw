/*
 DrawRectangle.m
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

public extension AJRUserDefaultsKey {
    static var rectangleRadius : AJRUserDefaultsKey<CGFloat>  {
        return AJRUserDefaultsKey<CGFloat>(named: "DrawRectangleRadiusKey", defaultValue: 9.0)
    }
}

public extension AJRInspectorIdentifier {
    static var rectangle = AJRInspectorIdentifier("rectangle")
}

@objcMembers
open class DrawRectangle : DrawGraphic {

    public static let pillRadius : CGFloat = 1000000.0

    internal var prepillRadius : CGFloat = 0.0

    internal var _radius : CGFloat = 0.0
    open var radius : CGFloat {
        get {
            return _radius
        }
        set {
            if _radius != newValue {
                let capturedRadius = _radius
                document?.registerUndo(target: self) { target in
                    target.radius = capturedRadius
                }
                _radius = newValue
                if _radius >= DrawRectangle.pillRadius {
                    prepillRadius = _radius
                }
                updatePath()
                setNeedsDisplay()

                UserDefaults[.rectangleRadius] = _radius
            }
        }
    }
    open var isPill : Bool {
        get {
            return radius >= DrawRectangle.pillRadius
        }
        set {
            if newValue {
                prepillRadius = radius
                radius = DrawRectangle.pillRadius
            } else {
                radius = prepillRadius
            }
        }
    }

    // MARK: - Creation

    public required init() {
        super.init()
        radius = 0
        prepillRadius = 0
    }

    public override init(frame: NSRect) {
        super.init(frame: frame)
        radius = 0
        prepillRadius = 0
        updatePath()
    }

    // MARK: - Utilities

    internal func createCircle() {
        path.removeAllPoints()
        path.appendOval(in: frame)
    }

    internal func createRectangle() {
        path.removeAllPoints()
        path.appendRect(frame)
    }

    internal func createRoundedRectangle() {
        path.removeAllPoints()
        path.appendRoundedRect(frame, xRadius: radius, yRadius: radius)
    }

    open func updatePath() {
        var diameter = radius * 2.0

        if diameter > 0.0 {
            if (diameter > frame.width) || (diameter > frame.height) {
                if frame.width == frame.height {
                    createCircle()
                } else {
                    let temp = radius
                    if diameter > frame.width {
                        diameter = frame.width
                    }
                    if diameter > frame.height {
                        diameter = frame.height;
                    }
                    radius = diameter / 2.0
                    createRoundedRectangle()
                    radius = temp
                }
            } else {
                createRoundedRectangle()
            }
        } else {
            createRectangle()
        }
    }

    // MARK: - DrawTool

    open override var frame: NSRect {
        didSet {
            updatePath()
            updateBounds()
        }
    }

    open class func keyPathsForValuesAffectingIsPill() -> Set<String> {
        return ["radius"]
    }

    // MARK: - NSCopying

    open override func copy(with zone: NSZone? = nil) -> Any {
        let new = super.copy(with: zone) as! DrawRectangle
        new.radius = radius
        new.prepillRadius = prepillRadius
        return new;
    }

    // MARK: - AJRXMLCoding

    open override func decode(with coder: AJRXMLCoder) {
        super.decode(with: coder)
        coder.decodeBool(forKey: "isPill") { value in
            if value {
                self.radius = DrawRectangle.pillRadius
            }
        }
        coder.decodeCGFloat(forKey: "nonPillRadius") { value in
            self.prepillRadius = value
        }
        coder.decodeCGFloat(forKey: "radius") { value in
            self.radius = value
        }
    }

    open override func encode(with coder: AJRXMLCoder) {
        super.encode(with: coder)
        if isPill {
            coder.encode(true, forKey: "isPill")
            coder.encode(prepillRadius, forKey: "nonPillRadius")
        } else {
            coder.encode(radius, forKey: "radius")
        }
    }

    open override func finalizeXMLDecoding() throws -> Any {
        try super.finalizeXMLDecoding()
        self.updatePath()
        return self
    }

    open override class var ajr_nameForXMLArchiving: String {
        return "rectangle"
    }

    // MARK: - Equality

    open func isEqual(toRectangle other: DrawRectangle) -> Bool {
        return (super.isEqual(to: other)
                && radius == other.radius)
    }

    open override func isEqual(to object: Any?) -> Bool {
        if let object = object as? DrawRectangle {
            return isEqual(toRectangle: object)
        }
        return false
    }

    open override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? DrawRectangle {
            return isEqual(toRectangle: object)
        }
        return false
    }

    // MARK: - Inspectors

    open override func inspectorIdentifiers(forInspectorContent inspectorContentIdentifier: AJRInspectorContentIdentifier?) -> [AJRInspectorIdentifier] {
        var identifiers = super.inspectorIdentifiers(forInspectorContent: inspectorContentIdentifier)
        if inspectorContentIdentifier == .graphic {
            identifiers.append(.rectangle)
        }
        return identifiers
    }

}
