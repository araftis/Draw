/*
DrawLayerViewController.swift
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

@objcMembers
open class DrawLayerViewController: DrawStructureInspector, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet open var layersTable : NSTableView!

    open override func documentDidLoad(_ document: DrawDocument) {
        reload()
    }
    
    open override func viewDidLayout() {
        // I'm not sure why this doesn't happen automatically, but...
        layersTable.sizeLastColumnToFit()
    }

    open func reload() -> Void {
        layersTable?.reloadData()
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
