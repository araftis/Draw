//
//  DrawDocument.swift
//  Draw
//
//  Created by AJ Raftis on 1/23/21.
//  Copyright © 2021 Apple, Inc. All rights reserved.
//

import Foundation

public extension DrawDocument {

    /**
     Adds generics for Swift. Makes using this a little nicer.
     */
    func registerUndo<TargetType>(target: TargetType, handler: @escaping (TargetType) -> Void) where TargetType : AnyObject {
        self.registerUndo(withTarget: target) { (target) in
            handler(target as! TargetType)
        }
    }

}
