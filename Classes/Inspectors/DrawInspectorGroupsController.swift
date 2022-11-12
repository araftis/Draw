/*
 DrawInspectorGroupsController.swift
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

import AJRFoundation
import AJRInterfaceFoundation
import AJRInterface

public extension AJRUserDefaultsKey {
    static var selectedInspectorGroup : AJRUserDefaultsKey<AJRInspectorContentIdentifier> {
        return AJRUserDefaultsKey<String>.key(named: "selectedInspectorGroup", defaultValue: .document)
    }
}

@objcMembers
open class DrawInspectorGroupsController : NSViewController {

    // MARK: - Properties

    @IBOutlet open var managedView : NSView!
    @IBOutlet open var buttonBar : AJRButtonBar!
    open var groups = [DrawInspectorGroup]()
    open var groupsByID = [AJRInspectorContentIdentifier:DrawInspectorGroup]()
    open var selectedGroup : DrawInspectorGroup?

    // MARK: - Creation

    @objc public init() {
        super.init(nibName: "DrawInspectorGroupsController", bundle: Bundle(for: Self.self))
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Groups

    open func inspectorGroup(for id: AJRInspectorContentIdentifier) -> DrawInspectorGroup? {
        return groupsByID[id]
    }

    open func indexOfGroup(for id: AJRInspectorContentIdentifier) -> Int? {
        return groups.firstIndex { (group) -> Bool in
            return group.identifier == id
        }
    }

    // MARK: - Selection Change

    open func update() -> Void {
        // We shouldn't need to do this. We will need to update the selected objects, though.
//        for group in DrawInspectorGroup.groups {
//            group.viewController.update()
//        }
    }

    open func matchingObjects(in group: DrawInspectorGroup, from objects: [AnyObject]) -> [AnyObject] {
        var matchingObjects = [AnyObject]()
        for object in objects {
            if group.inspectedClasses.contains(where: { (possible) -> Bool in
                return object.isKind(of: possible)
            }) {
                matchingObjects.append(object)
            }
        }
        return matchingObjects
    }

    open func push(_ objects: [AnyObject], for identifier: AJRInspectorContentIdentifier) -> Void {
        for group in groups {
            let matchingObjects = self.matchingObjects(in: group, from: objects)
            if matchingObjects.count > 0 {
                group.push(content: matchingObjects)
            }
        }
    }

    open func pop(_ objects: [NSObject], for identifier: AJRInspectorContentIdentifier) -> Void {
        for group in groups {
            let matchingObjects = self.matchingObjects(in: group, from: objects)
            if matchingObjects.count > 0 {
                group.pop(content: matchingObjects)
            }
        }
    }

    // MARK: - NSViewController

    open override func viewDidLoad() {
        super.viewDidLoad()

        groups = DrawInspectorGroup.createGroups()
        for group in groups {
            groupsByID[group.identifier] = group
        }
        buttonBar.numberOfButtons = groups.count
        buttonBar.spacing = 8.0
        buttonBar.alignment = .center
        buttonBar.trackingMode = .selectOne
        for (index, group) in groups.enumerated() {
            buttonBar.setImage(group.icon, for: index)
            buttonBar.setTarget(self, for: index)
            buttonBar.setAction(#selector(selectInspectorGroup(_:)), for: index)
        }

        if let selectedGroupIndex = indexOfGroup(for: UserDefaults[.selectedInspectorGroup]!) {
            selectInspectorGroup(at: selectedGroupIndex)
        } else {
            selectInspectorGroup(at: 0)
        }
    }

    open override func loadView() {
        Bundle(for: DrawInspectorGroupsController.self).loadNibNamed("DrawInspectorGroupsController", owner: self, topLevelObjects: nil)
    }

    open func selectInspectorGroup(at index: Int) -> Void {
        buttonBar.setSelected(true, for: index)
        UserDefaults[.selectedInspectorGroup] = groups[index].identifier

        if let selectedGroup = selectedGroup {
            let viewController = selectedGroup.viewController
            viewController.view.removeFromSuperview()
        }

        selectedGroup = groups[index]
        let viewController = selectedGroup!.viewController
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

    @IBAction open func selectInspectorGroup(_ sender: Any?) -> Void {
        selectInspectorGroup(at: buttonBar.selectedButton)
    }

}
