/*
 DrawRulerAccessory.swift
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

@objcMembers
open class DrawRulerAccessory : NSViewController {

    open weak var document : DrawDocument? = nil

    @IBOutlet internal var gridColorWell : AJRColorWell!
    @IBOutlet internal var gridSpacingText : NSTextField!
    @IBOutlet internal var showGridSwitch : NSButton!
    @IBOutlet internal var showSnapLinesSwitch : NSButton!
    @IBOutlet internal var snapLineColorWell : AJRColorWell!
    @IBOutlet internal var snapToGridSwitch : NSButton!
    @IBOutlet internal var snapToSnapLinesSwitch : NSButton!

    internal var observerTokens = [AJRInvalidation]()

    public init(document: DrawDocument) {
        self.document = document

        super.init(nibName: "DrawRulerAccessory", bundle: Bundle(for: Self.self))
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        for token in observerTokens {
            token.invalidate()
        }
    }

    // TODO: Probably going to be obsolete when I add observers.
    open func update() {
        if let document {
            snapLineColorWell.color = document.markColor
            showSnapLinesSwitch.state = document.marksVisible ? .on : .off
            snapToSnapLinesSwitch.state = document.marksEnabled ? .on : .off

            gridColorWell.color = document.gridColor
            showGridSwitch.state = document.gridVisible ? .on : .off
            snapToGridSwitch.state = document.gridEnabled ? .on : .off
            gridSpacingText.doubleValue = document.gridSpacing
        }
    }

    open override func awakeFromNib() -> Void {
        if let document {
            weak var weakSelf = self
            observerTokens.append(document.add(observer: self, forKeyPath: "unitFormatter", options: .initial, block: { object, KeyPath, options in
                if let strongSelf = weakSelf,
                   let document = strongSelf.document {
                    strongSelf.gridSpacingText.formatter = document.unitFormatter
                }
            }))
            gridSpacingText.bind(.value, to: document, withKeyPath: "gridSpacing")

            gridColorWell.bind(.value, to: document, withKeyPath: "gridColor")
            showGridSwitch.bind(.value, to: document, withKeyPath: "gridVisible")
            snapToGridSwitch.bind(.value, to: document, withKeyPath: "gridEnabled")

            snapLineColorWell.bind(.value, to: document, withKeyPath: "markColor")
            showSnapLinesSwitch.bind(.value, to: document, withKeyPath: "marksVisible")
            snapToSnapLinesSwitch.bind(.value, to: document, withKeyPath: "marksEnabled")
        }
    }

}
