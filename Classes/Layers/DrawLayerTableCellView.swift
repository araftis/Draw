//
//  DrawLayerTableCellView.swift
//  Draw
//
//  Created by AJ Raftis on 1/10/21.
//  Copyright © 2021 Apple, Inc. All rights reserved.
//

import Cocoa

@objc open class DrawLayerTableCellView: NSTableCellView {

    @objc @IBOutlet var button : NSButton!
    var drawLayer : DrawLayer?

}
