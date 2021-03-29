/*
DrawPolygonTool.swift
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

import Cocoa

public extension AJRUserDefaultsKey {

    static var newPolygonSides : AJRUserDefaultsKey<Int> {
        return AJRUserDefaultsKey<Int>.key(named: "newPolygonSides", defaultValue: 5)
    }
    static var newPolygonStar : AJRUserDefaultsKey<CGFloat> {
        return AJRUserDefaultsKey<CGFloat>.key(named: "newPolygonStar", defaultValue: 0.0)
    }
    static var newPolygonOffset : AJRUserDefaultsKey<CGFloat> {
        return AJRUserDefaultsKey<CGFloat>.key(named: "newPolygonOffset", defaultValue: 0.0)
    }

}

@objcMembers
open class DrawPolygonTool: DrawTool {

    private var sidesObserverToken : Any? = nil
    private var starObserverToken : Any? = nil
    private var offsetObserverToken : Any? = nil
    private var _icon : NSImage? = nil

    public override init(toolSet: DrawToolSet) {
        super.init(toolSet: toolSet)

        weak var weakSelf = self
        sidesObserverToken = AJRUserDefaultsKey<Int>.newPolygonSides.addObserver {
            weakSelf?.updateIcon()
        }
        starObserverToken = AJRUserDefaultsKey<CGFloat>.newPolygonStar.addObserver {
            weakSelf?.updateIcon()
        }
        offsetObserverToken = AJRUserDefaultsKey<CGFloat>.newPolygonOffset.addObserver {
            weakSelf?.updateIcon()
        }
    }

    deinit {
        if let token = sidesObserverToken {
            AJRUserDefaultsKey<Int>.newPolygonSides.removeObserver(token)
        }
        if let token = starObserverToken {
            AJRUserDefaultsKey<CGFloat>.newPolygonStar.removeObserver(token)
        }
        if let token = offsetObserverToken {
            AJRUserDefaultsKey<CGFloat>.newPolygonOffset.removeObserver(token)
        }
    }

    open override func graphic(with point: NSPoint, document: DrawDocument, page: DrawPage) -> DrawGraphic {
        let graphic = DrawPolygon(frame: NSRect(origin: point, size: .zero))
        graphic.takeAspects(from: document.templateGraphic)
        return graphic
    }

    open func updateIcon() {
        willChangeValue(forKey: "icon")
        _icon = nil // We'll just rebuild this below.
        didChangeValue(forKey: "icon")
    }

    open override var icon: NSImage? {
        if _icon == nil {
            let size = NSSize(width: 25.0, height: 25.0)
            _icon = NSImage.ajr_image(with: size, scales: [1.0, 2.0, 3.0], flipped: true, colorSpace: nil, commands: { (scale) in
                let rect = CGRect(origin: .zero, size: size).insetBy(dx: 1.5, dy: 1.5)
                let path = AJRBezierPath(polygonIn: rect, sides: UserDefaults[.newPolygonSides]!, starPercent: UserDefaults[.newPolygonStar]!, offset: UserDefaults[.newPolygonOffset]!)
                NSColor.black.withAlphaComponent(0.15).set()
                path.fill()
                NSColor.black.set()
                path.stroke()
            })
            _icon?.isTemplate = true
        }
        return _icon!
    }

}
