/*
DrawFill.swift
Draw

Copyright © 2021, AJ Raftis and AJRFoundation authors
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

//NSString * const DrawFillIdentifier = @"fill";
public let DrawFillWindingRuleKey = "fillWindingRule"

public extension AJRUserDefaultsKey {
    static var fillWindingRule : AJRUserDefaultsKey<AJRWindingRule> {
        return AJRUserDefaultsKey<AJRWindingRule>.key(named: DrawFillWindingRuleKey, defaultValue: AJRWindingRule.nonZero)
    }
}

@objcMembers
open class DrawFill : DrawAspect {
    
    // MARK: - Properties
    
    open var windingRule : AJRWindingRule = .nonZero
    
    required public override init() {
        super.init()
    }

    public override init(graphic: DrawGraphic?) {
        windingRule = UserDefaults[.fillWindingRule]!
        super.init(graphic: graphic)
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
        }
        return aspect
    }
    
    // MARK: - AJRXMLCoding

    open override func decode(with coder: AJRXMLCoder) {
        super.decode(with: coder)
 
        coder.decodeEnumeration(forKey: "windingRule") { (value: AJRWindingRule?) in
            self.windingRule = value ?? .nonZero
        }
    }
    
    open override func encode(with coder: AJRXMLCoder) {
        super.encode(with: coder)
        coder.encode(windingRule, forKey: "windingRule")
    }
    
}
