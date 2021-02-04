//
//  DrawToolAccessory.swift
//  Draw
//
//  Created by AJ Raftis on 2/1/21.
//  Copyright © 2021 Apple, Inc. All rights reserved.
//

import Cocoa

@objcMembers
open class DrawToolAccessory: DrawViewController {

    var icon : NSImage

    public required init(identifier: NSUserInterfaceItemIdentifier, title: String, icon: NSImage) {
        self.icon = icon
        super.init(nibName: AJRStringFromClassSansModule(type(of: self)), bundle: Bundle(for: type(of: self)))
        self.identifier = identifier
        self.title = title
    }

    required public init?(coder: NSCoder) {
        self.icon = NSImage(named: NSImage.cautionName)!
        super.init(coder: coder)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
