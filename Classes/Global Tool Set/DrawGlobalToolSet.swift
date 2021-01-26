//
//  DrawGlobalToolSet.swift
//  Draw
//
//  Created by AJ Raftis on 1/1/21.
//  Copyright © 2021 Apple, Inc. All rights reserved.
//

import Cocoa

public extension DrawToolSetId {
    static var global: DrawToolSetId {
        return DrawToolSetId("global")
    }
}

@objc open class DrawGlobalToolSet: DrawToolSet {

    public class var identifier : String { return "global" }

}
