/*
 DrawToolAccessoryViewController.swift
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

import Cocoa


public extension AJRUserDefaultsKey {
    static var selectedAccessoryView : AJRUserDefaultsKey<String> {
        return AJRUserDefaultsKey<String>.key(named: "selectedAccessoryView")
    }
}

@objcMembers
open class DrawToolAccessoryViewController: DrawViewController {

    // MARK: - Properties

    @IBOutlet open var accessorySelector : NSSegmentedControl!
    @IBOutlet open var accessoryView : NSView!
    open var accessories = [DrawToolAccessory]()
    open var currentAccessory : DrawToolAccessory?

    // MARK: - Creation

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - NSViewController

    override open func viewDidLoad() {
        // Don't do set up here. It's too early for us, as the document won't yet be set.
        super.viewDidLoad()
    }

    override open func documentDidLoad(_ document: DrawDocument) {
        for toolSet in DrawToolSet.toolSets {
            accessories.append(contentsOf: toolSet.accessories)
        }
        children = accessories

        var indexToSelect = 0
        let selectedAccessory = UserDefaults[.selectedAccessoryView]

        accessorySelector.segmentCount = accessories.count
        if accessories.count > 0 {
            for (index, accessory) in accessories.enumerated() {
                if let title = accessory.title {
                    accessorySelector.setLabel(title, forSegment: index)
                }
                accessorySelector.setImage(accessory.icon, forSegment: index)
                if let selectedAccessory = selectedAccessory {
                    if NSUserInterfaceItemIdentifier(selectedAccessory) == accessory.identifier {
                        indexToSelect = index
                    }
                }
            }
            accessorySelector.sizeToFit()
            accessorySelector.setSelected(true, forSegment: indexToSelect)
            self.selectAccessory(accessorySelector)
        } else {
            // Make us zero height.
            if let split = self.view.enclosingView(type: NSSplitView.self) {
                // NOTE: This is a little dangerous, because we don't absolutely know our position in the split view, but the NSSplitView API doesn't allow us to determine our position. As such, if we ever add additional views to the central split, we could wind up collapsing the wrong split. That being said, we're going to maybe be a little safer, because we're unlikely to be anything other than the last view. Famous last words and all.
                let index = split.arrangedSubviews.count - 2
                if index >= 0 {
                    split.setPosition(split.maxPossiblePositionOfDivider(at: index), ofDividerAt: index)
                }
            }
        }
    }

    // MARK: - Actions

    @IBAction open func selectAccessory(_ sender: Any?) -> Void {
        let index = accessorySelector.selectedSegment
        let accessory = accessories[index]

        UserDefaults[.selectedAccessoryView] = accessory.identifier?.rawValue

        if let currentAccessory = currentAccessory {
            currentAccessory.view.removeFromSuperview()
        }

        currentAccessory = accessory
        if let currentAccessory = currentAccessory {
            accessoryView.translatesAutoresizingMaskIntoConstraints = false
            currentAccessory.view.translatesAutoresizingMaskIntoConstraints = false
            accessoryView.addSubview(currentAccessory.view)
            accessoryView.addConstraints([
                accessoryView.leadingAnchor.constraint(equalTo: currentAccessory.view.leadingAnchor),
                accessoryView.trailingAnchor.constraint(equalTo: currentAccessory.view.trailingAnchor),
                accessoryView.topAnchor.constraint(equalTo: currentAccessory.view.topAnchor),
                accessoryView.bottomAnchor.constraint(equalTo: currentAccessory.view.bottomAnchor),
            ])
        }
    }
    
}
