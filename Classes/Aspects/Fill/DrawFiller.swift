//
//  DrawFiller.swift
//  Draw
//
//  Created by AJ Raftis on 3/26/23.
//  Copyright © 2023 Apple, Inc. All rights reserved.
//

import AJRInterfaceFoundation

@objcMembers
open class DrawFiller : NSObject, AJRXMLCoding, NSCopying {

    // MARK: - Properties

    open weak var fill : DrawFill?
    open var graphic : DrawGraphic? {
        return fill?.graphic
    }
    open var windingRule : AJRWindingRule {
        return fill?.windingRule ?? .evenOdd
    }

    // MARK: - Creation

    required public override init() {
    }

    open class func createDefaultFiller() -> DrawFiller {
        return self.init()
    }

    // MARK: - Drawing

    open func draw(_ path: AJRBezierPath, with priority: DrawAspectPriority) -> DrawGraphicCompletionBlock? {
        return nil
    }

    // MARK: - AJRXMLCoding

    public func encode(with coder: AJRXMLCoder) {
    }

    public func decode(with coder: AJRXMLCoder) {
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let new = type(of: self).init()

        return new
    }

}
