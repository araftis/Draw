/*
DrawReflection.m
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

import AJRFoundation

@objcMembers
open class DrawReflection : DrawAspect {

    // MARK: - Utilities

    open var fadeMask : CGImage = {
        var fadeMask : CGImage? = nil
        var width : size_t = 1
        var height : size_t = 256

        // Create a bitmap context (According to the docs, it's OK to pass CGImageAlphaInfo.alphaOnly here.
        if let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: CGColorSpace(name: CGColorSpace.linearGray)!, bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue) {
            var data = context.data
            // Set the blend mode to copy to avoid any alteration of the source data
            context.setBlendMode(.copy)
            // Draw the image to extract the alpha channel
            if var bytes = data?.bindMemory(to: UInt8.self, capacity: width * height) {
                for  y in 0 ..< height {
                    for x in 0 ..< width {
                        let value = AJRClamp((y + 25) * 2, min: 0, max: 255)
                        bytes[y * width + x] = uint8(value)
                    }
                }
                // Create a data provider for our data object (NSMutableData is tollfree bridged to CFMutableDataRef, which is compatible with CFDataRef)
                if let dataProvider = CGDataProvider(dataInfo: data, data: bytes, size: width * height, releaseData: { raw, ptr, value in }) {
                    // Create our new mask image with the same size as the original image
                    fadeMask = CGImage(maskWidth: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: width, provider: dataProvider, decode: nil, shouldInterpolate: true)
                }
            }
        }

        return fadeMask!
    }()

    // MARK: - DrawAspect

    override open func draw(_ path: AJRBezierPath, with priority: DrawAspectPriority) -> DrawGraphicCompletionBlock? {
        if let context = NSGraphicsContext.current?.cgContext {
            let bounds = path.bounds
            let transform = NSAffineTransform()

            context.drawWithSavedGraphicsState {
                context.scaleBy(x: 1.0, y: -1.0)
                context.translateBy(x: 0.0, y: (-2.0 * bounds.origin.y) + (-2.0 * bounds.size.height) - 2.0)
                transform.concat()
                context.clip(to: bounds.insetBy(dx: -10.0, dy: -10.0), mask: fadeMask)
                context.beginTransparencyLayer(auxiliaryInfo: nil)
                graphic?.draw() { aspect, priority in
                    if aspect == self || aspect is DrawShadow {
                        return false
                    }
                    return true
                }
                context.endTransparencyLayer()
            }
        }
        return nil
    }

    override open func bounds(for path: AJRBezierPath) -> NSRect {
        var bounds = path.bounds
        bounds.size.height += bounds.size.height / 2.0
        return bounds
    }

    override class open func defaultAspect(for graphic: DrawGraphic) -> DrawAspect? {
        let reflection = DrawReflection(graphic: graphic)
        reflection.isActive = false
        return reflection
    }

}
