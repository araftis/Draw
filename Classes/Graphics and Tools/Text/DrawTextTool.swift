/*
 DrawTextTool.m
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

import AJRInterface

public extension DrawToolIdentifier {
    static let text = DrawToolIdentifier(rawValue: "text")
}

@objcMembers
open class DrawTextTool : DrawTool, NSMenuItemValidation {

    @objc(DrawTextToolTag)
    public enum Tag : Int {
        case text
        case formEntry
    }

    open var tag : Tag {
        if let tag = Tag(rawValue: currentAction.tag) {
            return tag
        }
        preconditionFailure("Our action returned a tag (\(currentAction.tag)) that we don't understand.")
    }

    open var attributes : [NSAttributedString.Key:Any] {
        let selectedFont : NSFont = NSFontManager.shared.selectedFont ?? NSFont.userFont(ofSize: 12.0)!

        return [.font:selectedFont]
    }

    // MARK: - DrawTool

    open override func graphic(with point: NSPoint, document: DrawDocument, page: DrawPage) -> DrawGraphic {
        let text : DrawText
        let attributes = self.attributes
        let selectedFont = attributes[.font] as! NSFont
        var size = selectedFont.boundingRectForFont.size

        size.width *= 2.0
        size.height *= 2.0

        let graphic = DrawRectangle(frame: NSRect(origin: point, size: size))

        switch tag {
        case .text:
            text = DrawText(graphic: graphic)
        case .formEntry:
            text = DrawFormEntry(graphic: graphic)
        }

        graphic.takeAspects(from: document.templateGraphic)
        graphic.addAspect(text, with: .afterBackground)

        text.attributedString = NSAttributedString(string: "", attributes: attributes)

        return graphic
    }

    open override func mouseDown(_ event: DrawEvent) -> Bool {
        if event.layerIsLockedOrNotVisible {
            return false
        }

        if graphic != nil {
            self.graphic = nil
            return true
        }

        graphic = graphic(with: event.locationOnPageSnappedToGrid, document: event.document, page: event.page)
        if let graphic {
            event.page.add(graphic, select: true, byExtendingSelection: false)
            graphic.beginAspectEditing(from: event)
        }

        return true
    }

    open override var cursor: NSCursor {
        return NSCursor.iBeam
    }

    open override func menu(for event: DrawEvent) -> NSMenu? {
        var menu : NSMenu? = nil

        if event.document.selection.count > 0 {
            var menuItem : NSMenuItem

            menu = NSMenu(title: translator["Text"])
            
            menuItem = menu!.addItem(withTitle: translator["Add to Graphic"], action: #selector(addTextToGraphics(_:)),  keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = event
            menuItem = menu!.addItem(withTitle: translator["Make Form Entry"], action: #selector(makeFormEntry(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = event
            menuItem = menu!.addItem(withTitle: translator["Make Plain Text"], action: #selector(makePlainText(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = event
        }

        return menu
    }

    // MARK: - Actions

    @IBAction open func addTextToGraphics(_ sender: Any?) -> Void {
        if let event = (sender as? NSMenuItem)?.representedObject as? DrawEvent {
            for graphic in event.document.selection {
                let text = DrawText(graphic: graphic)
                graphic.addAspect(text, with: .beforeChildren)
                text.attributedString = NSAttributedString(string: "Text", attributes: attributes)
            }
        }
    }

    @IBAction open func makeFormEntry(_ sender: Any?) -> Void {
        AJRLog.info("Convert to form entry, someday")
    }

    @IBAction open func makePlainText(_ sender: Any?) -> Void {
        AJRLog.info("Convert to plain text, someday")
    }

    // MARK: - NSMenuValidation

    public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if let event = menuItem.representedObject as? DrawEvent {
            let selection = event.document.selection

            if menuItem.action == #selector(addTextToGraphics(_:)) {
                return selection.count != 0
            } else if menuItem.action == #selector(makeFormEntry(_:)) {
                return selection.count != 0
            } else if menuItem.action == #selector(makePlainText(_:)) {
                return selection.count != 0
            }
        }

        return false
    }

}
