/*
 DrawEvent.m
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

@objcMembers
open class DrawEvent : NSObject {
    
    // MARK: - Creation

    public init(originalEvent event: NSEvent, document: DrawDocument, page: DrawPage) {
        self.event = event
        self.document = document
        self.page = page
    }

    @objc(eventWithOriginalEvent:document:page:)
    open class func event(with event: NSEvent, document: DrawDocument, page: DrawPage) -> DrawEvent {
        return DrawEvent(originalEvent: event, document: document, page: page)
    }
    
    // MARK: - Properties
    
    open var event : NSEvent
    open var document : DrawDocument
    open var page : DrawPage
    open var layer : DrawLayer { return document.layer }

    // MARK: - Utilities
    
    open var locationOnPage : NSPoint {
        return page.convert(event.locationInWindow, from: nil)
    }
    
    open var locationOnPageSnappedToGrid : NSPoint {
        document.snapToGrid(point: locationOnPage)
    }
    
    open var characters : String? {
        return event.characters
    }
    
    open var modifierFlags : NSEvent.ModifierFlags {
        return event.modifierFlags
    }
    
    open var clickCount : Int {
        return event.clickCount
    }
    
    open var layerIsLockedOrNotVisible : Bool {
        return layer.locked || !layer.visible
    }
    
}
