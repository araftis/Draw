//
//  DrawPolygon.swift
//  Draw
//
//  Created by AJ Raftis on 1/23/21.
//  Copyright © 2021 Apple, Inc. All rights reserved.
//

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

    public override init() {
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
