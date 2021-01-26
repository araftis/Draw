//
//  DrawInspectorGroup.swift
//  Draw
//
//  Created by AJ Raftis on 1/13/21.
//  Copyright © 2021 Apple, Inc. All rights reserved.
//

import Cocoa

open class DrawInspectorGroup: NSObject {

    // MARK: - Factory

    private static var groups = [[String:Any]]()
    private var _viewController : AJRInspectorViewController?
    open var viewController : AJRInspectorViewController {
        if _viewController == nil {
            _viewController = AJRInspectorViewController()
        }
        return _viewController!
    }

    @objc(registerInspectorGroupWithProperties:)
    open class func registerInspectorGroup(properties: [String:Any]) {
        groups.append(properties)
        AJRLog.in(domain: DrawPlugInLogDomain, level: .debug, message: "Inspector Group: \(properties["name"]!)")
    }

    open class func createGroups() -> [DrawInspectorGroup] {
        var newGroups = [DrawInspectorGroup]()

        for properties in groups {
            if let name = properties["name"] as? String,
               let icon = properties["icon"] as? NSImage,
               let id = properties["id"] as? String,
               let priority = properties["priority"] as? Double,
               let classes = properties["inspectedClasses"] as? [[String:Any]] {
                let filteredClasses : [NSObject.Type] = classes.map { (input) -> NSObject.Type in
                    return input["class"] as! NSObject.Type
                }
                let inspectorGroup = DrawInspectorGroup(name: name, identifier: id, inspectedClasses: filteredClasses, icon: icon, priority: priority)
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
    open var identifier : String
    open var inspectedClasses : [NSObject.Type]
    open var icon : NSImage
    open var priority : Double

    // MARK: - Creation

    public required init(name: String, identifier: String, inspectedClasses: [NSObject.Type], icon: NSImage, priority: Double) {
        self.name = name
        self.inspectedClasses = inspectedClasses
        self.identifier = identifier;
        self.icon = icon
        self.priority = priority
        super.init()
    }

}
