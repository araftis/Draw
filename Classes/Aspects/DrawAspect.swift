//
//  DrawAspect.swift
//  Draw
//
//  Created by AJ Raftis on 3/26/23.
//  Copyright © 2023 Apple, Inc. All rights reserved.
//

import Foundation

extension DrawAspectId : AJRUserDefaultProvider {

    public static func userDefault(forKey key: String, from userDefaults: UserDefaults) -> DrawAspectId? {
        if let raw = userDefaults.string(forKey: key) {
            return DrawAspectId(rawValue: raw)
        }
        return nil
    }

    public static func setUserDefault(_ value: DrawAspectId?, forKey key: String, into userDefaults: UserDefaults) {
        userDefaults.set(value?.rawValue, forKey: key)
    }

}
