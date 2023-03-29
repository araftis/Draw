//
//  DrawFillImage.swift
//  Draw
//
//  Created by AJ Raftis on 3/26/23.
//  Copyright © 2023 Apple, Inc. All rights reserved.
//

import Cocoa

import AJRInterface

public extension DrawAspectId {
    static var fillImage = DrawAspectId(rawValue: "fillImage")
}

public extension AJRUserDefaultsKey {
    static var fillImageSizing : AJRUserDefaultsKey<DrawFillImage.Sizing> {
        return AJRUserDefaultsKey<DrawFillImage.Sizing>.key(named: "fillImageSizing", defaultValue: .tile)
    }
    static var fillImageScale : AJRUserDefaultsKey<CGFloat> {
        return AJRUserDefaultsKey<CGFloat>.key(named: "fillImageScale", defaultValue: 1.0)
    }
}

@objcMembers
open class DrawFillImage: DrawFiller {

    public enum Sizing : AJRXMLEncodableEnum, AJRUserDefaultProvider {

        case original
        case stretch
        case tile
        case scaleToFill
        case scaleToFit

        public var description: String {
            switch self {
            case .original: return "original"
            case .stretch: return "stretch"
            case .tile: return "tile"
            case .scaleToFill: return "scaleToFill"
            case .scaleToFit: return "scaleToFit"
            }
        }

        public static func userDefault(forKey key: String, from userDefaults: UserDefaults) -> DrawFillImage.Sizing? {
            if let raw = userDefaults.string(forKey: key) {
                return Sizing(string: raw)
            }
            return nil
        }

        public static func setUserDefault(_ value: DrawFillImage.Sizing?, forKey key: String, into userDefaults: UserDefaults) {
            userDefaults.set(value?.description, forKey: key)
        }

    }

    open var image : NSImage? = nil
    open var sizing : Sizing = .tile
    open var scale : CGFloat = 1.0

    // MARK: - Creation

    public required init() {
        self.image = nil
        self.sizing = UserDefaults[.fillImageSizing]!
        self.scale = UserDefaults[.fillImageScale]!

        super.init()
    }

    // MARK: AJRXMLCoding

    open override func encode(with coder: AJRXMLCoder) {
        super.encode(with: coder)

        coder.encode(image, forKey: "image")
        coder.encode(sizing, forKey: "sizing")
        coder.encode(scale, forKey: "scale")
    }

    public override func decode(with coder: AJRXMLCoder) {
        super.decode(with: coder)

        coder.decodeObject(forKey: "image") { value in
            if let image = value as? NSImage {
                self.image = image
            }
        }
        coder.decodeEnumeration(forKey: "sizing") { (value : Sizing?) in
            self.sizing = value ?? .tile
        }
        coder.decodeCGFloat(forKey: "scale") { value in
            self.scale = value
        }
    }

    open class override var ajr_nameForXMLArchiving: String {
        return "fillImage"
    }

    // MARK: - NSCopying

    public override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! DrawFillImage
        copy.image = image?.copy() as? NSImage
        copy.sizing = sizing
        copy.scale = scale
        return copy
    }

    // MARK: - AJREquatable

    open override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? DrawFillImage {
            return (AJRAnyEquals(image, object.image)
                    && AJRAnyEquals(sizing, object.sizing)
                    && AJRAnyEquals(scale, object.scale))
        }
        return false
    }

}
