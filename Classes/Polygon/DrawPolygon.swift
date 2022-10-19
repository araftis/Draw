/*
DrawPolygon.swift
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

import Cocoa

public extension AJRInspectorIdentifier {
    static var polygon = AJRInspectorIdentifier("polygon")
}

@objcMembers
open class DrawPolygon: DrawGraphic {

    // MARK: - Properties

    internal var arcBounds : CGRect = .zero

    open class func keyPathsForValuesAffectingSides() -> Set<String> {
        return ["inspectedSides"]
    }

    open var sides : Int = UserDefaults[.newPolygonSides]! {
        willSet {
            let currentSides = sides
            document?.registerUndo(target: self, handler: { (target) in
                target.sides = currentSides
            })
        }
        didSet {
            createPath()
            setNeedsDisplay()
        }
    }

    open class func keyPathsForValuesAffectingInspectedSides() -> Set<String> {
        return ["sides"]
    }

    open var inspectedSides : Int {
        get {
            return sides
        }
        set {
            sides = newValue
            UserDefaults[.newPolygonSides] = sides
        }
    }

    open class func keyPathsForValuesAffectingStar() -> Set<String> {
        return ["inspectedStar"]
    }

    open var star : CGFloat = 0.0 {
        willSet {
            let currentStar = star
            document?.registerUndo(target: self, handler: { (target) in
                target.star = currentStar
            })
        }
        didSet {
            createPath()
            setNeedsDisplay()
        }
    }

    open class func keyPathsForValuesAffectingInspectedStar() -> Set<String> {
        return ["star"]
    }

    open var inspectedStar : CGFloat {
        get {
            return star
        }
        set {
            star = newValue
            UserDefaults[.newPolygonStar] = star
        }
    }

    open class func keyPathsForValuesAffectingOffset() -> Set<String> {
        return ["inspectedOffset"]
    }

    open var offset : CGFloat = 0.0 {
        willSet {
            let currentOffset = offset
            document?.registerUndo(target: self, handler: { (target) in
                target.offset = currentOffset
            })
        }
        didSet {
            createPath()
            setNeedsDisplay()
        }
    }

    open class func keyPathsForValuesAffectingInspectedOffset() -> Set<String> {
        return ["offset"]
    }

    open var inspectedOffset : CGFloat {
        get {
            return offset
        }
        set {
            offset = newValue
            UserDefaults[.newPolygonOffset] = offset
        }
    }

    // MARK: - Creation

    public required init() {
        super.init()
    }

    public override init(frame: NSRect) {
        arcBounds = frame
        super.init(frame: frame)
        createPath()
    }

    // MARK: - Path Construction

    internal func createPath() -> Void {
        path.removeAllPoints()
        path.appendPolygon(in: arcBounds, sides: sides, starPercent: star, offset: offset)
    }

    // MARK: - DrawGraphic

    open override var frame: NSRect {
        get {
            return super.frame
        }
        set(newValue) {
            let oldFrame = self.frame
            super.frame = newValue
            let newFrame = self.frame

            // This is probably wrong.
            arcBounds.origin.x -= (oldFrame.origin.x - newFrame.origin.x)
            arcBounds.origin.y -= (oldFrame.origin.y - newFrame.origin.y)
            arcBounds.size.width -= (oldFrame.size.width - newFrame.size.width)
            arcBounds.size.height -= (oldFrame.size.height - newFrame.size.height)

            createPath()
        }
    }

    // MARK: - AJRInspection

    open override var inspectorIdentifiers: [AJRInspectorIdentifier] {
        var ids = super.inspectorIdentifiers
        ids.append(.polygon)
        return ids
    }

    // MARK: - AJRXMLCoding

    open override class var ajr_nameForXMLArchiving: String {
        return "polygon"
    }

    open override func decode(with coder: AJRXMLCoder) {
        super.decode(with: coder)
        coder.decodeInteger(forKey: "sides") { (sides) in
            self.sides = sides
        }
        coder.decodeDouble(forKey: "star") { (star) in
            self.star = CGFloat(star)
        }
        coder.decodeDouble(forKey: "offset") { (offset) in
            self.offset = CGFloat(offset)
        }
        coder.decodeRect(forKey: "arcBounds") { (rect) in
            self.arcBounds = rect
        }
    }

    open override func encode(with coder: AJRXMLCoder) {
        super.encode(with: coder)
        coder.encode(sides, forKey: "sides")
        if star != 0 {
            coder.encode(star, forKey: "star")
        }
        if offset != 0 {
            coder.encode(offset, forKey: "offset")
        }
        if arcBounds != frame {
            coder.encode(arcBounds, forKey: "arcBounds")
        }
    }

    open override func finalizeXMLDecoding() throws -> Any {
        try super.finalizeXMLDecoding()
        if arcBounds == NSRect.zero {
            arcBounds = frame
        }
        createPath()
        return self
    }

}
