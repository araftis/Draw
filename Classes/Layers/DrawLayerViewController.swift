//
//  DrawLayerViewController.swift
//  Draw
//
//  Created by AJ Raftis on 1/10/21.
//  Copyright © 2021 Apple, Inc. All rights reserved.
//

import Cocoa

public extension NSUserInterfaceItemIdentifier {

    static var layerNameColumn = NSUserInterfaceItemIdentifier("name")
    static var layerVisibleColumn = NSUserInterfaceItemIdentifier("visible")
    static var layerEditableColumn = NSUserInterfaceItemIdentifier("editable")
    static var layerPrintableColumn = NSUserInterfaceItemIdentifier("printable")

    static var layerNameCell = NSUserInterfaceItemIdentifier("nameCell")
    static var layerVisibleCell = NSUserInterfaceItemIdentifier("visibleCell")
    static var layerEditableCell = NSUserInterfaceItemIdentifier("editableCell")
    static var layerPrintableCell = NSUserInterfaceItemIdentifier("printableCell")

}

@objc open class DrawLayerViewController: DrawViewController, NSTableViewDataSource, NSTableViewDelegate {

    @objc @IBOutlet open var layersTable : NSTableView!

    open override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    @objc open func reload() -> Void {
        layersTable.reloadData()
    }

    open func numberOfRows(in tableView: NSTableView) -> Int {
        if let document = self.document {
            return document.layers.count
        } else {
            return 0
        }
    }

    open func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if let document = document {
            if tableColumn?.identifier == .layerNameColumn {
                return document.layers[row].name
            }
        }
        return ""
    }

    open func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let document = document {
            let layers = document.layers
            let bundle = Bundle(for: Self.self)
            if tableColumn?.identifier == .layerNameColumn {
                let cell = tableView.makeView(withIdentifier: .layerNameCell, owner: self) as! NSTableCellView
                cell.textField?.stringValue = layers[row].name
                return cell
            } else if tableColumn?.identifier == .layerVisibleColumn {
                let cell = tableView.makeView(withIdentifier: .layerVisibleCell, owner: self) as! DrawLayerTableCellView
                cell.button?.image = AJRImages.image(named: "layerHidden", in: bundle)
                cell.button?.alternateImage = AJRImages.image(named: "layerVisible", in: bundle)
                cell.button?.state = layers[row].visible ? .on : .off
                cell.button?.target = self
                cell.button?.action = #selector(toggleVisible(_:))
                cell.drawLayer = layers[row]
                return cell
            } else if tableColumn?.identifier == .layerEditableColumn {
                let cell = tableView.makeView(withIdentifier: .layerEditableCell, owner: self) as! DrawLayerTableCellView
                cell.button?.image = AJRImages.image(named: "layerUnlocked", in: bundle)
                cell.button?.alternateImage = AJRImages.image(named: "layerLocked", in: bundle)
                cell.button?.state = layers[row].locked ? .on : .off
                cell.button?.target = self
                cell.button?.action = #selector(toggleLocked(_:))
                cell.drawLayer = layers[row]
                return cell
            } else if tableColumn?.identifier == .layerPrintableColumn {
                let cell = tableView.makeView(withIdentifier: .layerPrintableCell, owner: self) as! DrawLayerTableCellView
                cell.button?.image = AJRImages.image(named: "layerUnprintable", in: bundle)
                cell.button?.alternateImage = AJRImages.image(named: "layerPrintable", in: bundle)
                cell.button?.state = layers[row].printable ? .on : .off
                cell.button?.target = self
                cell.button?.action = #selector(togglePrintable(_:))
                cell.drawLayer = layers[row]
                return cell
            }
        }
        return nil
    }

    @IBAction open func toggleVisible(_ sender : NSButton?) -> Void {
        if let view = sender?.superview as? DrawLayerTableCellView {
            let visible = sender?.state == .on
            view.drawLayer?.visible = visible
        }
    }

    @IBAction open func toggleLocked(_ sender : NSButton?) -> Void {
        if let view = sender?.superview as? DrawLayerTableCellView {
            let locked = sender?.state == .on
            view.drawLayer?.locked = locked
        }
    }

    @IBAction open func togglePrintable(_ sender : NSButton?) -> Void {
        if let view = sender?.superview as? DrawLayerTableCellView {
            let printable = sender?.state == .on
            view.drawLayer?.printable = printable
        }
    }

}
