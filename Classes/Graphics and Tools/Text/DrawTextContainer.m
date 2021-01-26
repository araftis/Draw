/* DrawTextContainer.m created by alex on Sat 31-Oct-1998 */

#import "DrawTextContainer.h"

#import "DrawFill.h"
#import "DrawFillInspector.h"
#import "DrawFunctions.h"
#import "DrawGraphic.h"
#import "DrawRectangle.h"

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

@implementation DrawTextContainer

- (id)initWithGraphic:(DrawGraphic *)aGraphic {
    if ((self = [super initWithContainerSize:[aGraphic frame].size])) {
        [self setGraphic:aGraphic];
    }
    return self;
}

- (BOOL)isSimpleRectangularTextContainer {
    if ([_graphic isKindOfClass:[DrawRectangle class]]) {
        return [(DrawRectangle *)_graphic radius] == 0.0;
    }
    return NO;
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

- (void)updateExclusionRegions {
    [[self layoutManager] textContainerChangedGeometry:self];

    AJRBezierPath *path = _graphic.path;
    NSBezierPath *exclusionPath = [NSBezierPath bezierPathWithRect:path.bounds];
    [exclusionPath appendBezierPath:(NSBezierPath *)path];
    [exclusionPath setWindingRule:NSWindingRuleEvenOdd];
    self.exclusionPaths = @[exclusionPath];
}

- (void)setGraphic:(DrawGraphic *)graphic {
    if (_graphic != graphic) {
        _graphic = graphic;
        [self updateExclusionRegions];
    }
}

- (void)graphicDidChangeShape:(DrawGraphic *)graphic {
    [self updateExclusionRegions];
}

@end
