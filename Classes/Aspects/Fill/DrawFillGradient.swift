//
//  DrawFillGradient.swift
//  Draw
//
//  Created by AJ Raftis on 3/26/23.
//  Copyright © 2023 Apple, Inc. All rights reserved.
//

import AJRInterface

public extension DrawAspectId {
    static var fillGradient = DrawAspectId(rawValue: "fillGradient")
    static var fillGradientAdvanced = DrawAspectId(rawValue: "fillGradientAdvanced")
}

public extension AJRUserDefaultsKey {
    static var fillGradient : AJRUserDefaultsKey<NSGradient> {
        return AJRUserDefaultsKey<NSGradient>.key(named: "fillGradient", defaultValue: DrawFillGradient.defaultGradient)
    }
    static var fillAngle : AJRUserDefaultsKey<CGFloat> {
        return AJRUserDefaultsKey<CGFloat>.key(named: "fillAngle", defaultValue: 0.0)
    }
}

@objcMembers
open class DrawFillGradient : DrawFiller {

    // MARK: - Defaults

    static public var defaultGradient : NSGradient {
        return NSGradient(colorStops: defaultColorStops, colorSpace: defaultColorSpace)!
    }

    static public var defaultColorStops : [NSColorStop] {
        return [(color: .white, location: 0.0),
                (color: .cyan, location: 1.0)]
    }

    static public var defaultColorSpace : NSColorSpace { return .displayP3 }

    static public var defaultAngle : CGFloat { return 0.0 }

    // MARK: - Properties

    open var colorStops : [NSColorStop] {
        didSet {
            graphic?.setNeedsDisplay()
        }
    }
    open var colorSpace : NSColorSpace = .sRGB
    open var gradient : NSGradient? {
        return NSGradient(colorStops: colorStops, colorSpace: colorSpace)
    }
    open var angle : CGFloat {
        didSet {
            graphic?.setNeedsDisplay()
        }
    }

    // These are synthetic properties that make interaction easier.

    open class func keyPathsForValuesAffectingStartColor() -> Set<String> {
        return ["colorStops"]
    }
    open var startColor : NSColor {
        get {
            return colorStops[0].color
        }
        set {
            colorStops[0] = (color: newValue, location: 0.0)
            graphic?.setNeedsDisplay()
        }
    }

    open class func keyPathsForValuesAffectingEndColor() -> Set<String> {
        return ["colorStops"]
    }
    open var endColor : NSColor {
        get {
            return colorStops[1].color
        }
        set {
            colorStops[1] = (color: newValue, location: 1.0)
            graphic?.setNeedsDisplay()
        }
    }

    // MARK: - Creation

    public required init() {
        colorStops = []
        colorSpace = DrawFillGradient.defaultColorSpace
        angle = UserDefaults[.fillAngle]!
        super.init()
    }

    public init(gradient: NSGradient, angle: CGFloat) {
        self.colorStops = gradient.colorStops
        self.colorSpace = gradient.colorSpace
        self.angle = angle
        super.init()
    }

    public init(startColor: NSColor,
                endColor: NSColor,
                angle: CGFloat = DrawFillGradient.defaultAngle,
                colorSpace: NSColorSpace = DrawFillGradient.defaultColorSpace) {
        self.colorStops = [(color: startColor, location: 0.0), (color: endColor, location: 1.0)]
        self.colorSpace = colorSpace
        self.angle = 0.0
        super.init()
    }

    open override class func createDefaultFiller() -> DrawFiller {
        return DrawFillGradient(gradient: UserDefaults[.fillGradient]!,
                                angle: UserDefaults[.fillAngle]!)
    }

    // MARK: - DrawFiller

    open override func draw(_ path: AJRBezierPath, with priority: DrawAspectPriority) -> DrawGraphicCompletionBlock? {
        if let gradient {
            gradient.draw(in: path, angle: angle)
        }
        return nil
    }

    // MARK: - AJRXMLCoding

    open override func encode(with coder: AJRXMLCoder) {
        super.encode(with: coder)
        coder.encode(colorSpace.ajr_name, forKey: "colorSpace")
        coder.encode(angle, forKey: "angle")
        for stop in colorStops {
            coder.encodeGroup(forKey: "stop") {
                coder.encode(stop.location, forKey: "location")
                coder.encode(stop.color, forKey: "color")
            }
        }
    }

    public override func decode(with coder: AJRXMLCoder) {
        super.decode(with: coder)
        coder.decodeString(forKey: "colorSpace") { object in
            if let colorSpace = NSColorSpace.ajr_colorSpace(withName: object) {
                self.colorSpace = colorSpace
            } else {
                AJRLog.in(domain: .plugInManager, level: .warning, message: "Failed to create a color space when unarchiving a DrawFillGradient.")
                self.colorSpace = .sRGB
            }
        }
        coder.decodeCGFloat(forKey: "angle") { angle in
            self.angle = angle
        }

        var color : NSColor?
        var location : CGFloat?
        coder.decodeGroup(forKey: "stop") {
            coder.decodeObject(forKey: "color") { value in
                if let value = value as? NSColor {
                    color = value
                } else {
                    AJRLog.in(domain: .xmlDecoding, message: "Gradient color failed to decode as a color.")
                }
            }
            coder.decodeCGFloat(forKey: "location") { value in
                location = value
            }
        } setter: {
            if let color, let location {
                self.colorStops.append((color: color, location: location))
            } else {
                AJRLog.in(domain: .xmlDecoding, message: "When decoding a DrawFillGradient, we encountered a different number of colors than locations, which indicates a corrupt file.")
            }
        }
    }

    open class override var ajr_nameForXMLArchiving: String {
        return "fillGradient"
    }

    // MARK: - NSCopying

    public override func copy(with zone: NSZone? = nil) -> Any {
        // Gradients are immutable, so copy accordingly...
        let copy = super.copy(with: zone) as! DrawFillGradient
        copy.colorStops = colorStops
        copy.angle = angle
        return copy
    }

    // MARK: - AJREquatable

    open override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? DrawFillGradient {
            print("DrawFillGradient.isEqual():")
            print("  colorSpace: \(AJRAnyEquals(colorSpace, object.colorSpace))")
            print("  angle: \(AJRAnyEquals(angle, object.angle))")
            if colorStops.count != object.colorStops.count {
                return false
            }
            for x in 0 ..< colorStops.count {
                print("  stop[\(x)]: \(AJRAnyEquals(colorStops[x].color, object.colorStops[x].color)) \(AJRAnyEquals(colorStops[x].location, object.colorStops[x].location))")
                if !AJRAnyEquals(colorStops[x].color, object.colorStops[x].color)
                    || !AJRAnyEquals(colorStops[x].location, object.colorStops[x].location) {
                    return false
                }
            }
            return (AJRAnyEquals(colorSpace, object.colorSpace)
                    && AJRAnyEquals(angle, object.angle))
        }
        return false
    }

}
