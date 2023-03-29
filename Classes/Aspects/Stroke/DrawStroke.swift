/*
 DrawStroke.swift
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

@propertyWrapper
public struct ClampedValue<T: BinaryFloatingPoint> {
    
    private var value: T = T(0.0)
    private var minValue: T = -T.infinity
    private var maxValue: T = T.infinity
    
    public init(wrappedValue: T, min: T = -T.infinity, max: T = T.infinity) {
        self.minValue = min
        self.maxValue = max
        self.wrappedValue = wrappedValue
    }
    
    public var wrappedValue: T {
        get { return value }
        set {
            value = AJRClamp(value, min: minValue, max: maxValue)
        }
    }
}

public let DrawStrokeColorKey = "strokeColor"
public let DrawStrokeWidthKey = "strokeWidth"
public let DrawStrokeMiterLimitKey = "strokeMiterLimit"
public let DrawStrokeLineJoinKey = "strokeLineJoin"
public let DrawStrokeLineCapKey = "strokeLineCap"
public let DrawStrokeAspectKey = "strokeAspect"
public let DrawStrokeDashKey = "strokeDash"

public extension AJRUserDefaultsKey {
    static var strokeColor : AJRUserDefaultsKey<AJRColor> {
        return AJRUserDefaultsKey<AJRColor>.key(named: DrawStrokeColorKey, defaultValue: AJRColor.black)
    }
    static var strokeWidth : AJRUserDefaultsKey<CGFloat> {
        return AJRUserDefaultsKey<CGFloat>.key(named: DrawStrokeWidthKey, defaultValue: 1.0)
    }
    static var strokeMiterLimit : AJRUserDefaultsKey<CGFloat> {
        return AJRUserDefaultsKey<CGFloat>.key(named: DrawStrokeMiterLimitKey, defaultValue: 10.0)
    }
    static var strokeLineJoin : AJRUserDefaultsKey<AJRLineJoinStyle> {
        return AJRUserDefaultsKey<AJRLineJoinStyle>.key(named: DrawStrokeLineJoinKey, defaultValue: AJRLineJoinStyle.mitered)
    }
    static var strokeLineCap : AJRUserDefaultsKey<AJRLineCapStyle> {
        return AJRUserDefaultsKey<AJRWindingRule>.key(named: DrawStrokeLineCapKey, defaultValue: AJRLineCapStyle.square)
    }
    static var strokeDash : AJRUserDefaultsKey<DrawStrokeDash> {
        return AJRUserDefaultsKey<DrawStrokeDash>.key(named: DrawStrokeDashKey)
    }
}

@objcMembers
open class DrawStroke : DrawAspect, AJREquatable {
    
    //+ (void)initialize {
    //    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
    //                                // The Compose Defaults
    //                                @"NSCalibratedWhiteColorSpace 0 1", DrawStrokeColorKey,
    //                                @"1.0", DrawStrokeWidthKey,
    //                                @"10.0", DrawStrokeMiterLimitKey,
    //                                @"0", DrawStrokeLineJoinKey,
    //                                @"0", DrawStrokeLineCapKey,
    //                                [NSArray arrayWithObjects:
    //                                 @"",
    //                                 @"1.000000 3.000000",
    //                                 @"3.000000 4.000000",
    //                                 @"3.000000 6.000000",
    //                                 @"4.000000 3.000000 1.000000 3.000000",
    //                                 @"4.000000 3.000000 2.000000 3.000000",
    //                                 @"4.000000 3.000000 1.000000 3.000000 1.000000 3.000000",
    //                                 nil], DrawStrokeDashesKey,
    //                                @"", DrawStrokeDashKey,
    //                                nil
    //                                ]
    //    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary]
    //}
    
    // MARK: - Properties
    
    open var width: CGFloat {
        didSet {
            graphic?.updateBounds()
            graphic?.setNeedsDisplay()
        }
    }
    open var color: NSColor {
        didSet {
            graphic?.setNeedsDisplay()
        }
    }
    @ClampedValue(wrappedValue: 1.0, min: 1.0) open var miterLimit: CGFloat {
        didSet {
            graphic?.updateBounds()
            graphic?.setNeedsDisplay()
        }
    }
    open var dash: DrawStrokeDash? {
        didSet {
            graphic?.setNeedsDisplay()
        }
    }
    open var lineJoin: AJRLineJoinStyle {
        didSet {
            graphic?.updateBounds()
            graphic?.setNeedsDisplay()
        }
    }
    open var lineCap: AJRLineCapStyle {
        didSet {
            graphic?.updateBounds()
            graphic?.setNeedsDisplay()
        }
    }
    
    // MARK: - Creation
    
    required public init() {
        width = UserDefaults[.strokeWidth]!
        color = UserDefaults[.strokeColor]!
        lineJoin = UserDefaults[.strokeLineJoin]!
        lineCap = UserDefaults[.strokeLineCap]!
        super.init()
        miterLimit = UserDefaults[.strokeMiterLimit]!
    }
    
    required public override init(graphic: DrawGraphic?) {
        width = UserDefaults[.strokeWidth]!
        color = UserDefaults[.strokeColor]!
        lineJoin = UserDefaults[.strokeLineJoin]!
        lineCap = UserDefaults[.strokeLineCap]!
        dash = UserDefaults[.strokeDash]
        super.init(graphic: graphic)
        miterLimit = UserDefaults[.strokeMiterLimit]!
    }
    
    open override class func defaultAspect(for graphic: DrawGraphic) -> DrawAspect? {
        return self.init(graphic: graphic)
    }
    
    // MARK: - Properties
    
    internal func configurePath(_ path: AJRBezierPath) -> AJRBezierPath {
        if let graphic, let page = graphic.page {
            let error = page.error
            
            path.lineJoinStyle = lineJoin
            path.lineCapStyle = lineCap
            path.miterLimit = miterLimit
            path.flatness = graphic.flatness
            path.lineWidth = width < error ? error : width
            if let dash {
                dash.add(to: path)
            }
        }
        
        return path
    }
    
    open override func draw(_ path: AJRBezierPath, with priority: DrawAspectPriority) -> DrawGraphicCompletionBlock? {
        if let graphic {
            let focused = graphic.document?.focusedGroup
            
            if graphic.isDescendant(of: focused) {
                color.set()
            } else {
                NSColor.darkGray.set()
            }
            configurePath(path).stroke()
        }
        
        return nil
    }
    
    open override func renderPath(for path: AJRBezierPath, with priority: DrawAspectPriority) -> AJRBezierPath {
        return configurePath(path).fromStroked()
    }
    
    open override func isPoint(_ point: NSPoint, in path: AJRBezierPath, with priority: DrawAspectPriority) -> Bool {
        let path = configurePath(path)
        let savedLineWidth = path.lineWidth
        if savedLineWidth < 5.0 {
            path.lineWidth = 5.0
        }
        let hit = path.isStrokeHit(by: point)
        path.lineWidth = savedLineWidth
        return hit
    }
    
    open override func doesRect(_ rect: NSRect, intersect path: AJRBezierPath, with priority: DrawAspectPriority) -> Bool {
        return configurePath(path).isStrokeHit(by: rect)
    }
    
    open override var boundsAdjustment: AJRRectAdjustment {
        return AJRRectAdjustment(minX: width, maxX: width, minY: width, maxY: width)
    }
    
    open override func bounds(for path: AJRBezierPath) -> NSRect {
        return configurePath(path).strokeBounds().integral
    }
    
    open override class var image : NSImage? {
        return AJRImage.image(named: "strokeLine", forClass: self)
    }
    
    // MARK: - NSCopying
    
    open override func copy(with zone: NSZone? = nil) -> Any {
        let aspect = super.copy(with: zone)
        
        if let aspect = aspect as? DrawStroke {
            aspect.width = width
            aspect.color = color
            aspect.miterLimit = miterLimit
            aspect.lineJoin = lineJoin
            aspect.lineCap = lineCap
            aspect.dash = dash?.copy(with: zone) as? DrawStrokeDash
        }
        
        return aspect
    }
    
    // MARK: - NSCoding
    
    open override func encode(with coder: AJRXMLCoder) {
        super.encode(with: coder)
        
        coder.encode(width, forKey: "width")
        coder.encode(color, forKey: "color")
        coder.encode(miterLimit, forKey: "miterLimit")
        coder.encode(lineJoin, forKey: "lineJoin")
        coder.encode(lineCap, forKey: "lineCap")
        coder.encode(dash, forKey: "dash")
    }
    
    open override func decode(with coder: AJRXMLCoder) {
        super.decode(with: coder)
        
        coder.decodeDouble(forKey: "width") { value in
            self.width = CGFloat(value)
        }
        coder.decodeObject(forKey: "color") { color in
            if let color = color as? AJRColor {
                self.color = color
            }
        }
        coder.decodeDouble(forKey: "miterLimit") { value in
            self.miterLimit = value
        }
        coder.decodeEnumeration(forKey: "lineJoin") { (value: AJRLineJoinStyle?) in
            self.lineJoin = value ?? .mitered
        }
        coder.decodeEnumeration(forKey: "lineCap") { (value: AJRLineCapStyle?) in
            self.lineCap = value ?? .square
        }
        coder.decodeTypedObject(forKey: "dash") { (value: DrawStrokeDash?) in
            self.dash = value
        }
    }
    
    open class override var ajr_nameForXMLArchiving: String {
        return "stroke"
    }
    
    // MARK: - AJREquatable
    
    open override func isEqual(_ stroke: Any?) -> Bool {
        if let stroke = stroke as? DrawStroke {
            return (super.isEqual(stroke)
                    && AJRAnyEquals(width, stroke.width)
                    && AJRAnyEquals(color, stroke.color)
                    && AJRAnyEquals(miterLimit, stroke.miterLimit)
                    && AJRAnyEquals(lineJoin, stroke.lineJoin)
                    && AJRAnyEquals(lineCap, stroke.lineCap)
                    && AJRAnyEquals(dash, stroke.dash))
        }
        return false
    }
    
}
