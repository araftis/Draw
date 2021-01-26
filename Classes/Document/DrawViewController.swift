//
//  DrawViewController.swift
//  Draw
//
//  Created by AJ Raftis on 1/10/21.
//  Copyright © 2021 Apple, Inc. All rights reserved.
//

import Cocoa

/**
 Adds convenience methods to NSViewController.
 */
open class DrawViewController: NSViewController {

    open var document : DrawDocument? {
        if let window = view.window {
        }
        return nil
    }

    open override func loadView() {
        let bundle = Bundle(for: Self.self)
        var loaded = false
        if bundle.url(forResource: AJRStringFromClassSansModule(Self.self), withExtension: "nib") != nil {
            loaded = bundle.loadNibNamed(AJRStringFromClassSansModule(Self.self), owner: Self.self, topLevelObjects: nil)
        }

        if !loaded {
            super.loadView()
        }
    }

}
