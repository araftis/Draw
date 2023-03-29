/*
 DrawFill.swift
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

public typealias DrawFillId = DrawAspectId

public extension DrawFillId {
    static var fill = DrawFillId(rawValue: "fill")
}

public extension AJRUserDefaultsKey {
    static var fillWindingRule : AJRUserDefaultsKey<AJRWindingRule> {
        return AJRUserDefaultsKey<AJRWindingRule>.key(named: "fillWindingRule", defaultValue: AJRWindingRule.nonZero)
    }
    static var fillFiller : AJRUserDefaultsKey<DrawFillId> {
        return AJRUserDefaultsKey<DrawFillId>.key(named: "fillWindingRule", defaultValue: .fillColor)
    }
}

@objcMembers
open class DrawFill : DrawAspect, AJREquatable {

    // MARK: - Factory

    internal static var fillsById = [DrawFillId:Placeholder]()

    @objc(registerFill:properties:)
    open class func register(fill: DrawFiller.Type, properties: [String:Any]) -> Void {
        if let fillClass = properties["class"] as? DrawFiller.Type,
           let rawId = properties["id"] as? String,
           let name = properties["name"] as? String,
           let priority = properties["priority"] as? Double {
            let identifier = DrawFillId(rawValue: rawId)
            let placeholder = Placeholder(fillClass: fillClass, name: name, id: identifier, priority: CGFloat(priority))
            fillsById[identifier] = placeholder
            AJRLog.in(domain: .drawPlugIn, level: .debug, message: "Fill: \(name) (\(fillClass))")
        } else {
            AJRLog.in(domain: .drawPlugIn, level: .error, message: "Received nonsense properties: \(properties)")
        }
    }

    open class var allFillers : [Placeholder] {
        return fillsById.values.sorted { left, right in
            if left.priority == right.priority {
                return left.name < right.name
            }
            return left.priority < right.priority
        }
    }

    open class func filler(forId id: DrawFillId) -> Placeholder? {
        return fillsById[id]
    }

    open class func filler(forClass class: DrawFiller.Type) -> Placeholder? {
        for (_, value) in fillsById {
            if value.fillerClass == `class` {
                return value
            }
        }
        return nil
    }

    open class func fillerId(forClass class: DrawFiller.Type) -> DrawFillId? {
        if let placeholder = filler(forClass: `class`) {
            return placeholder.id
        }
        return nil
    }

    // MARK: - Properties
    
    open var windingRule : AJRWindingRule = .nonZero
    open var filler : DrawFiller {
        willSet {
            filler.fill = nil
        }
        didSet {
            filler.fill = self
            graphic?.setNeedsDisplay()
        }
    }
    public static var defaultFillColor = NSColor(calibratedWhite: 0.0, alpha: 0.9)

    public var inspectedAllFillers : [Placeholder] {
        return DrawFill.allFillers
    }

    public var inspectedFiller : Placeholder? {
        get {
            return DrawFill.filler(forClass: type(of: filler))
        }
        set {
            if let newValue {
                filler = newValue.fillerClass.createDefaultFiller()
            }
        }
    }

    // MARK: - Creation

    override class open func defaultAspect(for graphic: DrawGraphic) -> DrawAspect? {
        return DrawFill(graphic: graphic)
    }
    
    required public init() {
        self.filler = DrawFillColor(color: DrawFill.defaultFillColor)
        super.init()
    }

    public init(graphic: DrawGraphic?, color: NSColor) {
        self.windingRule = UserDefaults[.fillWindingRule]!

        let filler = DrawFillColor()
        filler.color = color
        self.filler = filler

        super.init(graphic: graphic)

        self.filler.fill = self
    }

    public init(graphic: DrawGraphic?, gradient: NSGradient, angle: CGFloat = 0.0) {
        self.windingRule = UserDefaults[.fillWindingRule]!
        self.filler = DrawFillGradient(gradient: gradient, angle: angle)

        super.init(graphic: graphic)

        self.filler.fill = self
    }

    public init(graphic: DrawGraphic?, startColor: NSColor, endColor: NSColor, angle: CGFloat = 0.0, colorSpace: NSColorSpace = DrawFillGradient.defaultColorSpace) {
        self.windingRule = UserDefaults[.fillWindingRule]!
        self.filler = DrawFillGradient(startColor: startColor, endColor: endColor, angle: angle, colorSpace: colorSpace)

        super.init(graphic: graphic)

        self.filler.fill = self
    }

    public init(graphic: DrawGraphic?, image: NSImage, sizing: DrawFillImage.Sizing = .tile, scale: CGFloat = 1.0) {
        self.windingRule = UserDefaults[.fillWindingRule]!

        let filler = DrawFillImage()
        filler.image = image
        filler.sizing = sizing
        filler.scale = scale
        self.filler = filler

        super.init(graphic: graphic)

        self.filler.fill = self
    }

    public override init(graphic: DrawGraphic?) {
        windingRule = UserDefaults[.fillWindingRule]!
        if let placeholder = DrawFill.filler(forId: UserDefaults[.fillFiller]!) {
            self.filler = placeholder.fillerClass.init()
        } else {
            self.filler = DrawFillColor()
        }
        super.init(graphic: graphic)

        self.filler.fill = self
    }
    
    // MARK: - DrawAspect
    
    open override func isPoint(_ point: NSPoint, in path: AJRBezierPath, with priority: DrawAspectPriority) -> Bool {
        if let graphic = graphic {
            path.flatness = graphic.flatness
            path.windingRule = windingRule
            return path.isHit(by: point)
        }
        return false
    }
    
    open override func copy(with zone: NSZone? = nil) -> Any {
        let aspect = super.copy(with: zone)
        if let aspect = aspect as? DrawFill {
            aspect.windingRule = windingRule
            aspect.filler = (filler.copy() as? DrawFiller) ?? DrawFillColor()
        }
        return aspect
    }

    open override func draw(_ path: AJRBezierPath, with priority: DrawAspectPriority) -> DrawGraphicCompletionBlock? {
        return filler.draw(path, with: priority)
    }

    // MARK: - AJRXMLCoding

    internal class DrawFillError : DrawFiller {

        var elementName : String

        required public init() {
            self.elementName = "*unknown*"
        }

        init(elementName: String?) {
            self.elementName = elementName ?? "*unknown*"
        }

        override func decode(with coder: AJRXMLCoder) {
            AJRLog.in(domain: .xmlDecoding, message: "Failed to decode a fill via element: \(elementName)")
        }

    }

    open override func decode(with coder: AJRXMLCoder) {
        super.decode(with: coder)

        coder.decodeEnumeration(forKey: "windingRule") { (value: AJRWindingRule?) in
            self.windingRule = value ?? .nonZero
        }

        coder.decodeObject { object in
            if let object = object as? DrawFiller {
                self.filler = object
            } else {
                self.filler = DrawFillColor(color: DrawFill.defaultFillColor)
            }
        }
    }

    open override func encode(with coder: AJRXMLCoder) {
        super.encode(with: coder)
        coder.encode(windingRule, forKey: "windingRule")
        coder.encode(filler)
    }

    open override class var ajr_nameForXMLArchiving: String {
        return "fill"
    }

    /**
     Part of object inspection, this contains an array of fills that can be selected by the user.
     */
    @objcMembers
    public class Placeholder : NSObject, AJRInspectorContentProvider {

        var fillerClass: DrawFiller.Type
        var name: String
        var id: DrawFillId
        var localizedName : String {
            // TODO: If we ever get around to localizing, localize this.
            return name
        }
        var priority : CGFloat

        public init(fillClass: DrawFiller.Type, name: String, id: DrawFillId, priority: CGFloat) {
            self.fillerClass = fillClass
            self.name = name
            self.id = id
            self.priority = priority
        }

        public var inspectorFilename: String? {
            return AJRStringFromClassSansModule(fillerClass)
        }

        public var inspectorBundle: Bundle? {
            return Bundle(for: fillerClass)
        }

    }

    // MARK: - AJREquatable

    open override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? DrawFill {
            return (AJRAnyEquals(windingRule, object.windingRule)
                    && AJRAnyEquals(filler, object.filler))
        }
        return false
    }

}

// This class is internal, because it is solely here for backwards compatibility when decoding the document.

internal class DrawOldColorFill : NSObject, AJRXMLCoding {

    internal var windingRule : AJRWindingRule = .evenOdd
    internal var color : NSColor? = nil

    required override init() {
    }

    func encode(with coder: AJRXMLCoder) {
        preconditionFailure("We reached a method we should have never reached. This class can only decode!")
    }

    func decode(with coder: AJRXMLCoder) {
        coder.decodeEnumeration(forKey: "windingRule") { (value: AJRWindingRule?) in
            self.windingRule = value ?? .evenOdd
        }
        coder.decodeObject(forKey: "color") { color in
            if let color = color as? NSColor {
                self.color = color
            }
        }
    }

    func finalizeXMLDecoding() throws -> Any {
        let fill = DrawFill(graphic: nil, color: color ?? DrawFill.defaultFillColor)
        fill.windingRule = windingRule
        return fill
    }

    override class var ajr_nameForXMLArchiving: String {
        return "colorFill"
    }

}
