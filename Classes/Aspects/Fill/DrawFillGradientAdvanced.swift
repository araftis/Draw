//
//  DrawFillGradientAdvanced.swift
//  Draw
//
//  Created by AJ Raftis on 3/28/23.
//  Copyright © 2023 Apple, Inc. All rights reserved.
//

import AJRInterfaceFoundation

public extension AJRUserDefaultsKey {
    static var fillStartPoint : AJRUserDefaultsKey<CGPoint> {
        return AJRUserDefaultsKey<CGPoint>.key(named: "fillStartPoint", defaultValue: .zero)
    }
    static var fillEndPoint : AJRUserDefaultsKey<CGPoint> {
        return AJRUserDefaultsKey<CGPoint>.key(named: "fillEndPoint", defaultValue: .zero)
    }
    static var fillType : AJRUserDefaultsKey<DrawFillGradientAdvanced.GradientType> {
        return AJRUserDefaultsKey<DrawFillGradientAdvanced.GradientType>.key(named: "fillGradientType", defaultValue: .linear)
    }
}

@objcMembers
open class DrawFillGradientAdvanced : DrawFillGradient {

    public enum GradientType : AJRXMLEncodableEnum, AJRUserDefaultProvider {

        case linear
        case radial

        public var description: String {
            switch self {
            case .linear: return "linear"
            case .radial: return "radial"
            }
        }

        public static func userDefault(forKey key: String, from userDefaults: UserDefaults) -> DrawFillGradientAdvanced.GradientType? {
            if let raw = userDefaults.string(forKey: key) {
                return GradientType(string: raw)
            }
            return nil
        }

        public static func setUserDefault(_ value: DrawFillGradientAdvanced.GradientType?, forKey key: String, into userDefaults: UserDefaults) {
            userDefaults.set(value?.description, forKey: key)
        }

    }

    open var startPoint : CGPoint
    open var endPoint : CGPoint
    open var type : GradientType

    public required init() {
        startPoint = UserDefaults[.fillStartPoint]!
        endPoint = UserDefaults[.fillStartPoint]!
        type = UserDefaults[.fillType]!
        super.init()
    }

    // MARK: - AJRXMLCoding

    open override func encode(with coder: AJRXMLCoder) {
        super.encode(with: coder)
        coder.encode(startPoint, forKey: "start")
        coder.encode(endPoint, forKey: "end")
        coder.encode(type, forKey: "type")
    }

    public override func decode(with coder: AJRXMLCoder) {
        super.decode(with: coder)
        coder.decodePoint(forKey: "start") { point in
            self.startPoint = point
        }
        coder.decodePoint(forKey: "end") { point in
            self.endPoint = point
        }
        coder.decodeEnumeration(forKey: "type") { (value: GradientType?) in
            if let value {
                self.type = value
            }
        }
    }

    open class override var ajr_nameForXMLArchiving: String {
        return "fillAdvancedGradient"
    }

    // MARK: - NSCopying

    public override func copy(with zone: NSZone? = nil) -> Any {
        // Gradients are immutable, so copy accordingly...
        let copy = super.copy(with: zone) as! DrawFillGradientAdvanced
        copy.startPoint = startPoint
        copy.endPoint = endPoint
        copy.type = type
        return copy
    }

}
