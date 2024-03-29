/*
 DrawTextContainer.swift
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
open class DrawTextContainer : NSTextContainer {

    public init(graphic: DrawGraphic?) {
        self.graphic = graphic
        super.init(size: graphic?.frame.size ?? NSSize(width: 15.0, height: 15.0))
    }

    public override init(size: NSSize) {
        super.init(size: size)
    }

    open override var isSimpleRectangularTextContainer : Bool {
        if let graphic = graphic as? DrawRectangle {
            return graphic.radius == 0.0
        }
        return false
    }

/*
- (BOOL)containsPoint:(NSPoint)aPoint {
    AJRBezierPath	*path = [_graphic path];

    for (DrawAspectPriority x = 0; x < DrawAspectPriorityLast; x++) {
        NSArray *subaspects = [[_graphic aspects] objectAtIndex:x];
        for (DrawAspect *aspect in subaspects) {
            if ([aspect isKindOfClass:[DrawFill class]]) {
                DrawFill		*fill = (DrawFill *)aspect;
                NSRect			frame = [_graphic frame];

                aPoint.x += frame.origin.x;
                aPoint.y += frame.origin.y;
                if (fill) {
                    if ([fill isPoint:aPoint inPath:path withPriority:x]) {
                        return YES;
                    }
                }
            }
        }
    }

    return [path isHitByPoint:aPoint];
}

- (NSRect)rectFromRectsInArray:(NSArray *)rectangles range:(NSRange)range {
    NSInteger		x;
    NSRect	rect;

    rect = [[rectangles objectAtIndex:range.location] rectValue];
    for (x = range.location + 1; x < range.length; x++) {
        rect = NSUnionRect(rect, [[rectangles objectAtIndex:range.location] rectValue]);
    }

    return rect;
}

- (NSRect)lineFragmentRectForProposedRect:(NSRect)proposedRect
                           sweepDirection:(NSLineSweepDirection)sweepDirection
                        movementDirection:(NSLineMovementDirection)movementDirection
                            remainingRect:(NSRect *)remainingRect {
    AJRBezierPath *path = [_graphic path];
    NSArray *rectangles;
    NSInteger count;
    NSRect bounds = [path controlPointBounds];
    NSRect returnRect;
    NSUInteger charIndex, glyphIndex;
    NSSize minSize;
    NSFont *font;
    NSLayoutManager *manager = [self layoutManager];
    CGFloat lineFragmentPadding = [self lineFragmentPadding];
    NSTextStorage *textStorage = [[self textView] textStorage];

    @try {
        if ([textStorage length]) {
            [manager getFirstUnlaidCharacterIndex:&charIndex glyphIndex:&glyphIndex];
            if (charIndex >= [textStorage length]) charIndex = [textStorage length] - 1;
            font = [textStorage attribute:NSFontAttributeName atIndex:charIndex effectiveRange:NULL];
            if (glyphIndex >= [manager numberOfGlyphs]) glyphIndex = [manager numberOfGlyphs] - 1;
            minSize = [font advancementForGlyph:[manager glyphAtIndex:glyphIndex]];
        } else {
            minSize = (NSSize){1.0, 1.0};
        }
    } @catch(NSException *localException) {
        minSize = (NSSize){1.0, 1.0};
    }

    minSize.width += (lineFragmentPadding * 2.0);
    minSize.height += (lineFragmentPadding * 2.0);

    //AJRPrintf(@"Size = %@\n", NSStringFromSize(minSize));

    proposedRect.origin.x += bounds.origin.x;
    proposedRect.origin.y += bounds.origin.y;
    rectangles = [path subrectanglesContainedInRect:proposedRect error:[_graphic flatness] lineSweep:sweepDirection minimumSize:minSize.width];
    count = [rectangles count];

    if (!count) {
        NSArray	*lastValidRectangles = nil;
        NSRect	graphicFrame = [_graphic frame];

        if (movementDirection != NSLineDoesntMove) {
            if ((sweepDirection == NSLineSweepLeft) || (sweepDirection == NSLineSweepRight)) {
                if (movementDirection == NSLineMovesDown) {
                    CGFloat delta = proposedRect.size.height;
                    while (proposedRect.origin.y <= graphicFrame.origin.y + graphicFrame.size.height) {
                        proposedRect.origin.y += delta;
                        rectangles = [path subrectanglesContainedInRect:proposedRect error:[_graphic flatness] lineSweep:sweepDirection minimumSize:minSize.width];
                        count = [rectangles count];
//                         {
//                         NSInteger		x;
//                         AJRPrintf(@"   count = %d, y = %.1f, delta = %.1f\n", count, proposedRect.origin.y, delta);
//                         for (x = 0; x < (const NSInteger)[rectangles count]; x++) {
//                         AJRPrintf(@"      %@\n", NSStringFromRect([[rectangles objectAtIndex:x] rectValue]));
//                         }
//                         }
                        if (count && (fabs(delta) <= 1.0)) {
                            lastValidRectangles = rectangles;
                            break;
                        }
                        if (fabs(delta) <= 1.0) {
                            if (proposedRect.size.height == 1.0) {
                                delta = 2.0;
                                if (proposedRect.origin.y > graphicFrame.origin.y + graphicFrame.size.height) {
                                    break;
                                }
                            } else {
                                break;
                            }
                        }
                        if (count) {
                            lastValidRectangles = rectangles;
                            delta = -rint(fabs(delta) / 2.0);
                        } else {
                            delta = rint(fabs(delta));
                            if (proposedRect.origin.y + delta > graphicFrame.origin.y + graphicFrame.size.height) {
                                break;
                            }
                        }
                    }
                } else {
                }
            } else {
            }
        }

        if (!lastValidRectangles) {
            *remainingRect = NSZeroRect;
            //AJRPrintf(@"Couldn't find valid rectangle!\n");
            return NSZeroRect;
        }

        rectangles = lastValidRectangles;
        count = [rectangles count];
    }

    if (count == 1) {
        *remainingRect = NSZeroRect;
        returnRect = [[rectangles objectAtIndex:0] rectValue];
        returnRect.origin.x -= bounds.origin.x;
        returnRect.origin.y -= bounds.origin.y;

        //AJRPrintf(@"Return %@\n", NSStringFromRect(returnRect));

        return returnRect;
    }

    if ((sweepDirection == NSLineSweepLeft) || (sweepDirection == NSLineSweepDown)) {
        *remainingRect = [self rectFromRectsInArray:rectangles range:(NSRange){0, [rectangles count] - 1}];
        returnRect = [[rectangles lastObject] rectValue];
        remainingRect->origin.x -= bounds.origin.x;
        remainingRect->origin.y -= bounds.origin.y;
        returnRect.origin.x -= bounds.origin.x;
        returnRect.origin.y -= bounds.origin.y;
    } else if ((sweepDirection == NSLineSweepRight) || (sweepDirection == NSLineSweepUp)) {
        *remainingRect = [self rectFromRectsInArray:rectangles range:(NSRange){1, [rectangles count] - 1}];
        returnRect = [[rectangles objectAtIndex:0] rectValue];
        remainingRect->origin.x -= bounds.origin.x;
        remainingRect->origin.y -= bounds.origin.y;
        returnRect.origin.x -= bounds.origin.x;
        returnRect.origin.y -= bounds.origin.y;
    }

    return returnRect;
}
*/

    public func updateExclusionRegions() {
        layoutManager?.textContainerChangedGeometry(self)

        if let graphic {
            // TODO: We need to experiment with this more.
//            let graphicPath = graphic.path
//            var path = NSBezierPath(rect: graphic.frame)
//            path.windingRule = NSBezierPath.WindingRule(rawValue: graphicPath.windingRule.rawValue)!
//            path = path.subtracting(with: graphicPath)
//            self.exclusionPaths = path.separateComponents
            self.exclusionPaths = []
        } else {
            self.exclusionPaths = []
        }
    }

    open var graphic : DrawGraphic? {
        didSet {
            updateExclusionRegions()
        }
    }

    open func graphicDidChangeShape(_ graphic: DrawGraphic) {
        updateExclusionRegions()
    }

    // MARK: - NSCoding

    // We have to implement this, but we don't actually allow ourself to code, or at least we won't encode our graphics.
    public required init(coder: NSCoder) {
        super.init(coder: coder)
    }

}
