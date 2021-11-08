/*
DrawStructureInspectors.swift
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
    static var selectedStructureInspector : AJRUserDefaultsKey<NSUserInterfaceItemIdentifier> {
        return AJRUserDefaultsKey<String>.key(named: "selectedStructureInspector", defaultValue: NSUserInterfaceItemIdentifier("layers"))
    }
}

@objcMembers
open class DrawStructureInspectors: DrawViewController {

    @IBOutlet open var managedView : NSView!
    @IBOutlet open var buttonBar : AJRButtonBar!

    open var inspectors = [DrawStructureInspector]()
    open var inspectorsByID = [NSUserInterfaceItemIdentifier:DrawStructureInspector]()
    open var selectedInspector : DrawStructureInspector?

    // MARK: - Creation

    @objc public init() {
        super.init(nibName: "DrawStructuresInspector", bundle: Bundle(for: Self.self))
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Inspectors

    open func inspector(for id: NSUserInterfaceItemIdentifier) -> DrawStructureInspector? {
        return inspectorsByID[id]
    }

    open func indexOfGroup(for id: NSUserInterfaceItemIdentifier) -> Int? {
        return inspectors.firstIndex { (group) -> Bool in
            return group.identifier == id
        }
    }
    
    // MARK: - DrawViewController
    
    open override func documentDidLoad(_ document: DrawDocument) {
        for inspector in inspectors {
            inspector.documentDidLoad(document)
        }
    }

    // MARK: - NSViewController
    
    open override func loadView() {
        Bundle(for: DrawStructureInspectors.self).loadNibNamed("DrawStructureInspectors", owner: self, topLevelObjects: nil)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        inspectors = DrawStructureInspector.createInspectors()
        for inspector in inspectors {
            // Force unwrap should be safe, since we require this parameter, even though NSViewController doesn't.
            inspectorsByID[inspector.identifier!] = inspector
        }
        buttonBar.numberOfButtons = inspectors.count
        buttonBar.spacing = 8.0
        buttonBar.alignment = .center
        buttonBar.trackingMode = .selectOne
        for (index, inspector) in inspectors.enumerated() {
            buttonBar.setImage(inspector.icon, for: index)
            buttonBar.setTarget(self, for: index)
            buttonBar.setAction(#selector(selectInspector(_:)), for: index)
        }

        if let selectedInspectorIndex = indexOfGroup(for: UserDefaults[.selectedStructureInspector]!) {
            selectInspector(at: selectedInspectorIndex)
        } else {
            selectInspector(at: 0)
        }
    }
    
    open func selectInspector(at index: Int) -> Void {
        AJRLog.info("selected: \(index)")
        buttonBar.setSelected(true, for: index)
        UserDefaults[.selectedStructureInspector] = inspectors[index].identifier

        if let selectedInspector = selectedInspector {
            selectedInspector.view.removeFromSuperview()
        }

        selectedInspector = inspectors[index]
        if let viewController = selectedInspector {
            let view = viewController.view
            view.frame = managedView.bounds
            managedView.addSubview(view)
            managedView.addConstraints([
                managedView.topAnchor.constraint(equalTo: view.topAnchor),
                managedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                view.bottomAnchor.constraint(equalTo: managedView.bottomAnchor),
                view.trailingAnchor.constraint(equalTo: managedView.trailingAnchor),
            ])
        }
    }
    
    @IBAction
    open func selectInspector(_ sender: Any?) -> Void {
        selectInspector(at: buttonBar.selectedButton)
    }
    
}
