/*
 DrawPathAnalysisAspect.swift
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

let DrawPathAnalysisIdentifier = "pathAnalysis"

@objcMembers
open class DrawPathAnalysisAspect : DrawAspect {

    open var analyzer : AJRPathAnalyzer

    // MARK: - Creation

    public required init() {
        self.analyzer = AJRPathAnalyzer(path: AJRBezierPath())
        super.init()
    }

    public override init(graphic: DrawGraphic?) {
        self.analyzer = AJRPathAnalyzer(path: graphic?.path ?? AJRBezierPath())
        super.init(graphic: graphic)
    }

    // MARK: - DrawAspect

    open override func draw(_ path: AJRBezierPath, with priority: DrawAspectPriority) -> DrawGraphicCompletionBlock? {
        let scale = NSAffineTransform.currentScale
        let thickPath = AJRBezierPath()
        let thinPath = AJRBezierPath()
        var previousPoint = NSPoint.zero

        for (index, contour) in analyzer.contours.enumerated() {
            for corner in contour.corners {
                if index == 0 {
                    previousPoint = corner.point
                } else {
                    thickPath.move(to: previousPoint)
                    thickPath.line(to: corner.point)
                    previousPoint = corner.point
                }
            }
        }

        thickPath.lineWidth = 4.0 / scale
        thickPath.stroke(color: NSColor.blue)

        thinPath.lineWidth = 1.0 / scale
        thinPath.stroke(color: NSColor.purple)

        return nil
    }

    // MARK: - NSCopying

    open override func copy(with zone: NSZone? = nil) -> Any {
        let aspect = super.copy(with: nil) as! DrawPathAnalysisAspect
        aspect.analyzer = AJRPathAnalyzer(path: analyzer.path)
        return aspect
    }

    // MARK: - NSCoding

    open override func decode(with coder: AJRXMLCoder) {
        super.decode(with: coder)
        coder.decodeObject(forKey: "width") { object in
            if let object = object as? AJRPathAnalyzer {
                self.analyzer = object
            } else {
                self.analyzer = AJRPathAnalyzer(path: AJRBezierPath())
            }
        }
    }

    open override func encode(with coder: AJRXMLCoder) {
        super.encode(with: coder)
        coder.encode(analyzer, forKey: "width")
    }

}
