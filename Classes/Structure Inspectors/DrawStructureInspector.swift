//
//  DrawStructureInspector.swift
//  Draw
//
//  Created by AJ Raftis on 11/1/21.
//  Copyright © 2021 Apple, Inc. All rights reserved.
//

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
