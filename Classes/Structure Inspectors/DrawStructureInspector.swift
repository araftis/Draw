/*
DrawStructureInspector.swift
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

@objcMembers
open class DrawStructureInspector: DrawViewController {

    // MARK: - Factory

    private static var inspectors = [[String:Any]]()

    @objc(registerStructureInspector:)
    open class func registerStructureInspector(_ properties: [String:Any]) {
        inspectors.append(properties)
        AJRLog.in(domain: DrawPlugInLogDomain, level: .debug, message: "Structure Inspector: \(properties["name"]!)")
    }

    open class func createInspectors() -> [DrawStructureInspector] {
        var newGroups = [DrawStructureInspector]()

        for properties in inspectors {
            if let name = properties["name"] as? String,
               let icon = properties["icon"] as? NSImage,
               let id = properties["id"] as? String,
               let priority = properties["priority"] as? Double,
               let inspectorClass = properties["inspectorClass"] as? DrawStructureInspector.Type {
                let inspectorGroup = inspectorClass.init(name: name, identifier: NSUserInterfaceItemIdentifier(id), icon: icon, priority: priority)
                newGroups.append(inspectorGroup)

                newGroups.sort { (left, right) -> Bool in
                    return left.priority < right.priority
                }
            }
        }
        newGroups.sort { (left, right) -> Bool in
            return left.priority < right.priority
        }

        return newGroups
    }

    // MARK: - Properties

    open var name : String
    open var icon : NSImage
    open var priority : Double

    // MARK: - Creation

    public required init(name: String, identifier: NSUserInterfaceItemIdentifier, icon: NSImage, priority: Double) {
        self.name = name
        self.icon = icon
        self.priority = priority
        super.init(nibName: AJRStringFromClassSansModule(Self.self), bundle: Bundle(for: Self.self))
        self.identifier = identifier
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - NSViewController

    open override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
