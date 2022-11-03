//
//  DrawGraphic.swift
//  Draw
//
//  Created by AJ Raftis on 11/2/22.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import Foundation

public extension DrawGraphic {
    
    func firstAspect<T: DrawAspect>(of type: T.Type, priority: DrawAspectPriority? = nil, create: Bool = false) -> T? {
        let finalPriority = priority ?? type.defaultPriority
        return firstAspect(ofType: type, with: finalPriority, create: create) as? T
    }
    
}
