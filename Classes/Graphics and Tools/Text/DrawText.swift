/*
 DrawText.swift
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

let DrawTextIdentifier = "text"

public extension AJRUserDefaultsKey {
    static var debugTextContainerFrames : AJRUserDefaultsKey<Bool> {
        return AJRUserDefaultsKey<Bool>.key(named: "debugTextContainerFrames", defaultValue: false)
    }
}

@objcMembers
open class DrawText : DrawAspect {

    @objc(DrawVerticalTextAlignment)
    public enum VerticalTextAlignment : Int, AJRXMLEncodableEnum {

        case top = 0
        case middle
        case bottom

        public var description: String {
            switch self {
            case .top: return "top"
            case .middle: return "middle"
            case .bottom: return "bottom"
            }
        }
    }

    open var textStorage = NSTextStorage()
    open var size = NSSize.zero
    open var lineFragmentPadding : CGFloat = 2.0 {
        willSet {
            let current = lineFragmentPadding
            graphic?.document?.registerUndo(withTarget: self, handler: { value in
                self.lineFragmentPadding = current
            })
        }
        didSet {
            if let textContainers = textStorage.layoutManagers.last?.textContainers {
                for container in textContainers {
                    container.lineFragmentPadding = lineFragmentPadding
                }
                graphic?.setNeedsDisplay()
            }
        }
    }
    open var verticalAlignment : VerticalTextAlignment = .top {
        didSet {
            graphic?.setNeedsDisplay()
        }
    }

    open var layoutManager : NSLayoutManager? {
        return textStorage.layoutManagers.last
    }

    open var textView : DrawTextView? {
        return layoutManager?.textContainers.last?.textView as? DrawTextView
    }

    open var textContainer : DrawTextContainer? {
        return layoutManager?.textContainers.last as? DrawTextContainer
    }

    open var editing : Bool = false
    open var ignoreGraphicShapeChange : Bool = false

    open override var graphic: DrawGraphic? {
        didSet {
            textContainer?.graphic = graphic
        }
    }
    
    // MARK: - Creation

    internal func initialize(from string: NSAttributedString?) {
        // Set up the NSTextStorage
        textStorage = NSTextStorage() // TODO: Maybe don't need this here.
        if let string {
            textStorage.setAttributedString(string)
        }

        // Now create and add the layout manager to the storage.
        let manager = NSLayoutManager()
        textStorage.addLayoutManager(manager)

        // And set up our primary contained.
        if let graphic {
            size = graphic.frame.size
            if size.width < 15.0 {
                size.width = 15.0
            }
            if size.height < 15.0 {
                size.height = 15.0
            }
        } else {
            size = NSSize(width: 15.0, height: 15.0)
        }
        let container = DrawTextContainer(size: size)
        container.lineFragmentPadding = lineFragmentPadding
        manager.addTextContainer(container)
        container.graphic = self.graphic
        container.heightTracksTextView = true
        container.widthTracksTextView = true

        // Finally, we'll create a text view, although we only use this when we're editing. As such, we could possibly defer the creation of it.
        let textView = DrawTextView(frame: NSRect(origin: NSPoint.zero, size: size), textContainer: container)
        textView.drawsBackground = false
        textView.isEditable = false
        textView.isSelectable = false
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = false

        // Not going to do this just yet. I will need to do this in the future, once we allow inline editing.
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewFrameDidChange:) name:NSViewFrameDidChangeNotification object:textView];
    }
    
    public required init() {
        super.init()
        initialize(from: nil)
    }

    public override init(graphic: DrawGraphic?) {
        super.init(graphic: graphic)
        initialize(from: nil)
    }

    public init(graphic: DrawGraphic, text: NSAttributedString) {
        super.init(graphic: graphic)
        initialize(from: text)
    }

    open func prepareTextInLayoutManager() {
        if let layoutManager, let textContainer {
            let range = layoutManager.glyphRange(for: textContainer)
            layoutManager.ensureLayout(forGlyphRange: range)
        }
    }

    @objc(yOffsetInTextFrame:)
    open func yOffset(in textFrame: NSRect) -> CGFloat {
        if let graphic {
            let frame = graphic.frame
            switch verticalAlignment {
            case .top:
                // Do nothing, we're automatically aligned to the top.
                return 0.0
            case .middle:
                return (frame.size.height - textFrame.size.height) / 2.0
            case .bottom:
                return frame.size.height - textFrame.size.height
            }
        }
        // Just in case we fallthrough, which we shouldn't, unless we change the enumeration and ignore warnings.
        return 0.0
    }

    open override func draw(_ path: AJRBezierPath, with priority: DrawAspectPriority) -> DrawGraphicCompletionBlock? {
        if !editing {
            if let layoutManager, let graphic, let textContainer {
                var point = graphic.frame.origin
                let range = layoutManager.glyphRange(for: textContainer)

                point.y += yOffset(in: layoutManager.usedRect(for: textContainer))

                layoutManager.drawBackground(forGlyphRange: range, at: point)
                layoutManager.drawGlyphs(forGlyphRange: range, at: point)
                
                if UserDefaults[.debugTextContainerFrames]! {
                    NSColor.red.set()
                    for container in layoutManager.textContainers {
                        NSRect(origin: point, size: container.containerSize).frame()
                    }
                }
            }
        }
        
        return nil
    }

    open var attributedString : NSAttributedString {
        get {
            return textStorage
        }
        set {
            let current = attributedString
            graphic?.document?.registerUndo(withTarget: self, handler: { object in
                self.attributedString = current
            })
            textStorage.setAttributedString(newValue)
            graphic?.setNeedsDisplay()
        }
    }

    internal func updateMaxSize() {
        if let graphic,
           let document = graphic.document,
           let textView {
            let paperSize = document.paper.size(for: document.orientation)
            let origin = graphic.frame.origin
            let textView = textView
            var maxSize = NSSize.zero

            maxSize.width = paperSize.width - document.margins.right - origin.x
            maxSize.height = paperSize.height - document.margins.bottom - origin.y
            AJRLog.debug("maxSize = \(maxSize)")
            textView.maxSize = maxSize
        }
    }

    open override func didAdd(to document: DrawDocument) {
        updateMaxSize()
        super.didAdd(to: document)
    }

    open override func willRemove(from document: DrawDocument) {
        super.willRemove(from: document)
    }

    open func updateContainerSize() {
        if let graphic,
           let textContainer {
            let graphicFrame = graphic.frame
            if let textView {
                let textFrame = textView.frame
                if textFrame != graphicFrame  {
                    textView.frame = graphicFrame
                    //[textContainer graphicDidChangeShape:aGraphic];
                }
            }
              
            if !textContainer.isSimpleRectangularTextContainer {
                textContainer.graphicDidChangeShape(graphic)
            }
            if textContainer.size != graphicFrame.size {
                var size = graphicFrame.size
                if size.width < 15.0 {
                    size.width = 15.0
                }
                if size.height < 15.0 {
                    size.height = 15.0
                }
                textContainer.containerSize = size
            }
            updateMaxSize()
        }
    }
    
    open override func graphicDidChangeShape(_ graphic: DrawGraphic) {
        if !ignoreGraphicShapeChange {
            updateContainerSize()
        }
    }
    
    open override func didAdd(to graphic: DrawGraphic) {
        updateContainerSize()
    }

    open override var aspectAcceptsEdit : Bool {
        return true
    }

    open func setupTextView(_ textView: NSTextView) {
        if let graphic,
           let container = textContainer {
            let frame = graphic.frame
            let bounds = frame

            textView.frame = frame
            textView.bounds = bounds
            textView.isEditable = true
            textView.isSelectable = true
            textView.isHorizontallyResizable = true
            textView.isVerticallyResizable = true
            container.heightTracksTextView = true
            container.widthTracksTextView = true
            updateMaxSize()
            textView.sizeToFit()
        }
    }

    open override func beginEditing(from event: DrawEvent) -> Bool {
        if let textView,
           let layoutManager,
           let graphic,
           let textContainer {
            var distance : CGFloat = 0.0
            var range = NSRange(location: 0, length: 0)

            setupTextView(textView)
            graphic.page?.addSubview(textView)
            textView.window?.makeFirstResponder(textView)
            let origin = graphic.frame.origin
            var point = event.locationOnPage
            point.x -= origin.x
            point.y -= origin.y
            range.location = layoutManager.glyphIndex(for: point, in: textContainer, fractionOfDistanceThroughGlyph: &distance)
            if distance > 0.5 {
                range.location += 1
            }
            textView.setSelectedRange(range)

            editing = true

            return true
        }
        return false
    }

    open override func endEditing() {
        if let textView, editing {
            textView.isEditable = false
            textView.isSelectable = false
            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = false
            textView.removeFromSuperview()

            editing = false

            NotificationCenter.default.post(name: .DrawObjectDidResignRuler, object: graphic?.document)
        }
    }

    open override func isPoint(_ point: NSPoint, in path: AJRBezierPath, with priority: DrawAspectPriority) -> Bool {
        if let manager = layoutManager,
           let graphic,
           let textContainer {
            // Make sure we're ready to use.
            prepareTextInLayoutManager()

            // Get the frame for our graphic, but remember to offset it by our frame.
            let graphicFrame = graphic.frame
            var rect = manager.usedRect(for: textContainer)
            rect.origin.x += graphicFrame.origin.x
            rect.origin.y += graphicFrame.origin.y + yOffset(in: rect)

            return NSMouseInRect(point, rect, false)
        }
        return false
    }

    // MARK: - DrawAspect

    open override class func defaultAspect(for graphic: DrawGraphic) -> DrawAspect? {
        return DrawText(graphic: graphic)
    }

    // MARK: - NSCopying

    internal func createTextStorage(with string: NSAttributedString) -> NSTextStorage {
        return finishInitializingTextStorage(NSTextStorage(), with: string)
    }

    internal func finishInitializingTextStorage(_ storage: NSTextStorage, with string: NSAttributedString) -> NSTextStorage {
        storage.setAttributedString(string)
        let manager = NSLayoutManager()
        storage.addLayoutManager(manager)
        let container = DrawTextContainer(containerSize: NSSize(width: 100, height: 100))
        container.lineFragmentPadding = lineFragmentPadding
        container.heightTracksTextView = true
        container.widthTracksTextView = true
        manager.addTextContainer(container)

        return storage
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        let new = super.copy(with: zone) as! DrawText

        // NOTE: Apparently copying an NSTextStorage produces an attributed string, not a text storage.
        new.textStorage = createTextStorage(with: textStorage.copy() as! NSAttributedString)
        new.editing = false
        new.lineFragmentPadding = lineFragmentPadding

        return new
    }

    // MARK: - AJRXMLArchiving

    class open override var ajr_nameForXMLArchiving: String {
        return "text"
    }

    open override func encode(with coder: AJRXMLCoder) {
        super.encode(with: coder)

        coder.encode(textStorage, forKey: "text")
        if editing {
            coder.encode(editing, forKey: "editing")
        }
        coder.encode(lineFragmentPadding, forKey:"lineFragmentPadding")
        if verticalAlignment != .top {
            coder.encode(verticalAlignment, forKey: "verticalAlignment")
        }
    }

    open override func decode(with coder: AJRXMLCoder) {
        super.decode(with: coder)

        coder.decodeObject(forKey: "text") { object in
            // Make sure the input is actually an attributed string, since it might not be if someone fiddled with the document.
            if let string = object as? NSAttributedString {
                self.textStorage = self.createTextStorage(with: string)
            } else {
                self.textStorage = self.createTextStorage(with: NSAttributedString())
            }
        }
        coder.decodeBool(forKey: "editing") { value in
            self.editing = value
        }
        coder.decodeCGFloat(forKey: "lineFragmentPadding") { value in
            self.lineFragmentPadding = value
        }
        coder.decodeEnumeration(forKey: "verticalAlignment") { (value : VerticalTextAlignment?) in
            self.verticalAlignment = value ?? .top
        }
    }

    open override func finalizeXMLDecoding() throws -> Any {
        let save = lineFragmentPadding

        initialize(from: textStorage)
        lineFragmentPadding = 0.0
        lineFragmentPadding = save
        
        return self
    }

}

// MARK: - Enumeration Functions

@_cdecl("DrawVerticalTextAlignmentFromString")
public func DrawVerticalTextAlignmentFromString(_ string: String) -> DrawText.VerticalTextAlignment {
    return DrawText.VerticalTextAlignment(string: string) ?? .top
}

@_cdecl("DrawStringFromVerticalTextAlignment")
func DrawStringFromVerticalTextAlignment(_ alignment: DrawText.VerticalTextAlignment) -> String {
    return alignment.description
}
