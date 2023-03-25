/*
 DrawRectangleTool.m
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
open class DrawRectangleTool : DrawTool {

    @objc(DrawRectangleToolTag)
    public enum Tag : Int {
        case rectangle
        case roundedRectangle
        case pill
    }

    open var tag : Tag {
        if let tag = Tag(rawValue: currentAction.tag) {
            return tag
        }
        preconditionFailure("Our action returned a tag (\(currentAction.tag)) that we don't understand.")
    }

    // MARK: - DrawTool

    open override func graphic(with point: NSPoint, document: DrawDocument, page: DrawPage) -> DrawGraphic {
        let graphic : DrawRectangle
        let frame = NSRect(origin: point, size: NSSize.zero)

        switch tag {
        case .rectangle:
            graphic = DrawRectangle(frame: frame)
        case .roundedRectangle:
            graphic = DrawRectangle(frame: frame)
            graphic.radius = UserDefaults[.rectangleRadius]!
        case .pill:
            graphic = DrawRectangle(frame: frame)
            graphic.radius = DrawRectangle.pillRadius
        }

        graphic.takeAspects(from: document.templateGraphic)

        return graphic
    }

}