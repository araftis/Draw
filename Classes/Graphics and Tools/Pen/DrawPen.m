/*
 DrawPen.m
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

#import "DrawPen.h"

#import "DrawEvent.h"
#import "DrawFunctions.h"
#import "DrawPage.h"
#import "DrawPenBezierAspect.h"
#import "DrawDocument.h"
#import "AJRBezierPath-DrawExtensions.h"

#import <AJRFoundation/AJRFoundation.h>
#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>
#import <AJRInterface/AJRInterface.h>

const AJRInspectorIdentifier AJRInspectorIdentifierPen = @"pen";

@implementation DrawPen {
    _DrawPolyPos _position;
     BOOL _frameAndBoundsAreDirty;
 }

#define DrawPenGetCursor(n,p) \
static NSCursor *cursor = nil; \
    if (!cursor) { \
        cursor = [[NSCursor alloc] initWithImage:[AJRImages imageNamed:n forClass:self] hotSpot:p]; \
    } \
    return cursor

+ (NSCursor *)cursorArrowAdd {
    DrawPenGetCursor(@"cursorArrowAdd", NSMakePoint(4.0, 4.0));
}

+ (NSCursor *)cursorArrowAddCurveTo {
    DrawPenGetCursor(@"cursorArrowAddCurve", NSMakePoint(4.0, 4.0));
}

+ (NSCursor *)cursorArrowRemove {
    DrawPenGetCursor(@"cursorArrowRemove", NSMakePoint(4.0, 4.0));
}

+ (NSCursor *)cursorArrowAddMoveTo {
    DrawPenGetCursor(@"cursorArrowAdd", NSMakePoint(4.0, 4.0));
}

+ (NSCursor *)cursorCrossAdd {
    DrawPenGetCursor(@"cursorCrossAdd", NSMakePoint(7.0, 7.0));
}

+ (NSCursor *)cursorCrossRemove {
    DrawPenGetCursor(@"cursorCrossRemove", NSMakePoint(7.0, 7.0));
}

+ (NSCursor *)cursorCrossAddMoveTo {
    DrawPenGetCursor(@"cursorCrossAdd", NSMakePoint(7.0, 7.0));
}

+ (NSCursor *)cursorCrossAddCurveTo {
    DrawPenGetCursor(@"cursorCrossAddCurve", NSMakePoint(7.0, 7.0));
}

- (id)initWithFrame:(NSRect)aFrame {
    if ((self = [super initWithFrame:aFrame])) {
        [_path removeAllPoints];
        [_path moveToPoint:aFrame.origin];
        [self addAspect:[[DrawPenBezierAspect alloc] initWithGraphic:self] withPriority:DrawAspectPriorityAfterForeground];

        [self updateBounds];
    }
    return self;
}

- (id)initWithFrame:(NSRect)aFrame path:(AJRBezierPath *)aPath {
    if ((self = [super initWithFrame:aFrame])) {
        _path = [aPath copyWithZone:nil];
        _closed = [_path elementAtIndex:[_path elementCount] - 1] == AJRBezierPathElementClose;
        [self addAspect:[[DrawPenBezierAspect alloc] initWithGraphic:self] withPriority:DrawAspectPriorityAfterForeground];
    }
    return self;
}

// MARK: - Path Modifiers

- (BOOL)appendLineToPoint:(NSPoint)point {
    [_path lineToPoint:point];
    return YES;
}

- (BOOL)canAppendMoveToPoint:(NSPoint)point {
    return YES;
}

- (BOOL)appendMoveToPoint:(NSPoint)point {
    if ([self canAppendMoveToPoint:point]) {
        [_path moveToPoint:point];
        return YES;
    }
    return NO;
}

- (BOOL)appendBezierCurve:(AJRBezierCurve)curve {
    return [self appendBezierCurveToPoint:curve.end controlPoint1:curve.handle1 controlPoint2:curve.handle2];
}

- (BOOL)appendBezierCurveToPoint:(NSPoint)point controlPoint1:(NSPoint)controlPoint1 controlPoint2:(NSPoint)controlPoint2 {
    [_path curveToPoint:point controlPoint1:controlPoint1 controlPoint2:controlPoint2];
    return YES;
}

- (BOOL)insertPoint:(NSPoint)point atIndex:(NSUInteger)index {
    [_path insertLineToPoint:point atIndex:index];
    return YES;
}

- (BOOL)insertPoint:(NSPoint)point {
    CGFloat t;
    CGFloat width = 6.0;
    NSUInteger elementIndex;
    
    if (width < 6.0) {
        width = 6.0;
    }
    
    elementIndex = [_path elementIndexOfElementHitByPoint:point atTValue:&t width:width];
    
    if (elementIndex != NSNotFound) {
        if ([_path elementAtIndex:elementIndex] == AJRBezierPathElementCurveTo) {
            [_path splitElementAtIndex:elementIndex atTValue:t];
            return YES;
        } else {
            return [self insertPoint:point atIndex:elementIndex];
        }
    } else {
        return [self appendLineToPoint:point];
    }

    return NO;
}

- (BOOL)removePointAtIndex:(NSUInteger)index {
    [_path removeElementAtIndex:index];
    return YES;
}

- (BOOL)removePoint:(NSPoint)point {
    if ([_path pointCount] > 2) {
        DrawHandle hitHandle = [_path drawHandleForPoint:point error:[self.page error]];
        if (hitHandle.type == DrawHandleTypeIndexed) {
            return [self removePointAtIndex:hitHandle.elementIndex];
        }
    }
    return NO;
}

- (BOOL)insertCurveToPoint:(NSPoint)point {
    CGFloat t;
    CGFloat width = 6.0;
    NSUInteger elementIndex;

    if (width < 6.0) {
        width = 6.0;
    }

    elementIndex = [_path elementIndexOfElementHitByPoint:point atTValue:&t width:width];

    if (elementIndex != NSNotFound) {
        if ([_path elementAtIndex:elementIndex] == AJRBezierPathElementCurveTo) {
            [_path splitElementAtIndex:elementIndex atTValue:t];
        } else {
            NSPoint start;
            NSPoint handle1, handle2;
            NSPoint end;

            if ([_path elementAtIndex:elementIndex - 1] == AJRBezierPathElementCurveTo) {
                start = [_path pointAtIndex:[_path pointIndexForPathElementIndex:elementIndex - 1] + 2];
            } else {
                start = [_path pointAtIndex:[_path pointIndexForPathElementIndex:elementIndex - 1]];
            }
            end = [_path pointAtIndex:[_path pointIndexForPathElementIndex:elementIndex]];

            if (t <= 0.5) {
                handle1 = point;
                handle2.x = end.x - (end.x - start.x) * t;
                handle2.y = end.y - (end.y - start.y) * t;
            } else {
                handle2 = point;
                handle1.x = end.x - (end.x - start.x) * t;
                handle1.y = end.y - (end.y - start.y) * t;
            }

            [_path changeToCurveToWithControlPoint1:handle1 controlPoint2:handle2 elementAtIndex:elementIndex];
        }
        return YES;
    }

    return NO;
}

- (void)updateBounds {
    NSRect frame = [_path controlPointBounds];

    _frameAndBoundsAreDirty = NO;

    if (frame.size.width < 0.01) {
        frame.size.width = 0.01;
    }
    if (frame.size.height < 0.01) {
        frame.size.height = 0.01;
    }

    // So, from what I can tell, this actually needs to be called always. I'm not sure why I was only calling it when I was changing the minimum width or height of the frame. Basically, if you don't call this all the time, then the frame doesn't update when handles get moved, which cases strange behavior, especially with link graphics.
    [self setFrameWithoutNotification:frame];

    //[self informAspectsOfShapeChange];
    [super updateBounds];
}

- (BOOL)isLine {
    if (([_path elementCount] == 2) && ([_path elementAtIndex:0] == AJRBezierPathElementMoveTo) && ([_path elementAtIndex:1] == AJRBezierPathElementLineTo)) {
        return YES;
    }
    if (([_path elementCount] == 3) && ([_path elementAtIndex:0] == AJRBezierPathElementMoveTo) && ([_path elementAtIndex:1] == AJRBezierPathElementLineTo) && ([_path elementAtIndex:2] == AJRBezierPathElementClose)) {
        return YES;
    }
    return NO;
}

- (void)drawHandles {
    if (!self.editing && ![self isLine]) {
        return [super drawHandles];
    }
    
    if (!self.ignore) {
        NSPoint points[3];
        AJRBezierPathElementType elementType;
        
        for (NSInteger x = 0; x < (const NSInteger)[_path elementCount]; x++) {
            elementType = [_path elementAtIndex:x associatedPoints:points];
            switch (elementType) {
                case AJRBezierPathElementMoveTo:
                case AJRBezierPathElementLineTo:
                    [self drawHandleAtPoint:points[0]];
                    break;
                case AJRBezierPathElementCurveTo:
                    [self drawHandleAtPoint:points[0]];
                    [self drawHandleAtPoint:points[1]];
                    [self drawHandleAtPoint:points[2]];
                    break;
                default:
                    break;
            }
        }
    }
}

- (DrawHandle)initializePositionForHandle:(DrawHandle)handle {
    if (handle.type != DrawHandleTypeMissed) {
        _position = [self _positionInformationForHandle:handle];
    }
    return handle;
}

- (_DrawPolyPos)_positionInformationForHandle:(DrawHandle)handle {
    _DrawPolyPos position;

    if (handle.type == DrawHandleTypeIndexed) {
        position.currentOp = [_path elementAtIndex:handle.elementIndex];
        position.currentOffset = [_path pointIndexForPathElementIndex:handle.elementIndex] + handle.subindex;
        if (handle.elementIndex > 0) {
            position.previousOp = [_path elementAtIndex:handle.elementIndex - 1];
            position.previousOffset = [_path pointIndexForPathElementIndex:handle.elementIndex - 1];
        } else {
            position.previousOp = -1;
            position.previousOffset = -1;
        }
        if (handle.elementIndex == ([_path elementCount] - (_closed ? 2 : 1))) {
            position.nextOp = -1;
            position.nextOffset = -1;
        } else {
            position.nextOp = [_path elementAtIndex:handle.elementIndex + 1];
            position.nextOffset = [_path pointIndexForPathElementIndex:handle.elementIndex + 1];
        }
    }
    
    position.handle = handle;
    
    return position;
}

- (DrawHandle)handleForPoint:(NSPoint)point {
    if (self.editing) {
        DrawHandle handle = [_path drawHandleForPoint:point error:[self.page error]];

        if (DrawHandleIsBase(handle)) {
            return handle;
        }

        return [self initializePositionForHandle:handle];
    }
    
    if (![self isLine]) {
        return [super handleForPoint:point];
    }
    
    if ([self isPoint:point inHandleAt:[_path pointAtIndex:0]]) {
        _position.currentOp = AJRBezierPathElementMoveTo;
        _position.previousOp = -1;
        _position.nextOp = AJRBezierPathElementLineTo;
        _position.handle = DrawHandleMake(DrawHandleTypeIndexed, 0, 0);
        _position.currentOffset = 0;
        _position.previousOffset = -1;
        _position.nextOffset = 1;
        return _position.handle;
    }
    if ([self isPoint:point inHandleAt:[_path pointAtIndex:1]]) {
        _position.currentOp = AJRBezierPathElementLineTo;
        _position.previousOp = AJRBezierPathElementMoveTo;
        _position.nextOp = -1;
        _position.handle = DrawHandleMake(DrawHandleTypeIndexed, 1, 0);
        _position.currentOffset = 1;
        _position.previousOffset = 0;
        _position.nextOffset = -1;
        return _position.handle;
    }
    
    return DrawHandleMake(DrawHandleTypeMissed, 0, 0);
}

- (void)_updateBezierHandleForLeftPoint:(NSPoint)point atLeftIndex:(NSInteger)leftIndex centerIndex:(NSInteger)centerIndex rightIndex:(NSInteger)rightIndex {
    CGFloat deltaRadius;
    CGFloat deltaAngle;
    NSPoint center;
    NSPoint handleLeft, handleRight;

    center = [_path pointAtIndex:centerIndex];
    handleLeft = [_path pointAtIndex:leftIndex];
    handleRight = [_path pointAtIndex:rightIndex];

    deltaAngle = AJRArctan(handleLeft.y - center.y, handleLeft.x - center.x) - AJRArctan(point.y - center.y, point.x - center.x);
    deltaRadius = AJRDistanceBetweenPoints(point, center) - AJRDistanceBetweenPoints(handleLeft, center);

    handleRight = AJRPolarToEuclidean(center, AJRArctan(handleRight.y - center.y, handleRight.x - center.x) - deltaAngle, AJRDistanceBetweenPoints(center, handleRight) + deltaRadius);
    [_path setPointAtIndex:rightIndex toPoint:handleRight];
}

- (DrawHandle)setHandle:(DrawHandle)handle toLocation:(NSPoint)point {
    if (DrawHandleIsBase(handle)) {
        return [super setHandle:handle toLocation:point];
    }
    
    if (_creating) {
        if (handle.elementIndex == [_path elementCount] - (_closed ? 1 : 0)) {
            [self appendLineToPoint:point];
        } else {
            [_path setPointAtIndex:[_path pointIndexForPathElementIndex:handle.elementIndex] toPoint:point];
        }
    } else {
        NSPoint delta;
        NSPoint pathPoint;
        NSInteger pointIndex;
        
        pointIndex = [_path pointIndexForPathElementIndex:handle.elementIndex] + handle.subindex;
        pathPoint = [_path pointAtIndex:pointIndex];
        
        delta.x = point.x - pathPoint.x;
        delta.y = point.y - pathPoint.y;
        
        if (!([[NSApp currentEvent] modifierFlags] & NSEventModifierFlagOption)) {
            if (_position.currentOp == AJRBezierPathElementCurveTo) {
                if (_position.handle.subindex == 2) {
                    [_path movePointAtIndex:_position.currentOffset - 1 byDelta:delta];
                    if (_position.nextOp == AJRBezierPathElementCurveTo) {
                        [_path movePointAtIndex:_position.currentOffset + 1 byDelta:delta];
                    }
                } else if (_position.handle.subindex == 1) {
                    if (_position.nextOp == AJRBezierPathElementCurveTo) {
                        [self _updateBezierHandleForLeftPoint:point
                                                  atLeftIndex:_position.currentOffset + 0
                                                  centerIndex:_position.currentOffset + 1
                                                   rightIndex:_position.currentOffset + 2];
                    } else if ((_position.handle.elementIndex == [_path lastDrawingElementIndex]) &&
                               NSEqualPoints([_path pointAtIndex:0], [_path lastPoint]) &&
                               ([_path elementAtIndex:1] == AJRBezierPathElementCurveTo)) {
                        [self _updateBezierHandleForLeftPoint:point
                                                  atLeftIndex:_position.currentOffset
                                                  centerIndex:0
                                                   rightIndex:1];
                    }
                } else if (_position.handle.subindex == 0) {
                    if (_position.previousOp == AJRBezierPathElementCurveTo) {
                        [self _updateBezierHandleForLeftPoint:point
                                                  atLeftIndex:_position.currentOffset + 0
                                                  centerIndex:_position.currentOffset - 1
                                                   rightIndex:_position.currentOffset - 2];
                    } else if ((_position.handle.elementIndex == 1) &&
                               NSEqualPoints([_path pointAtIndex:0], [_path lastPoint]) &&
                               ([_path lastDrawingElementType] == AJRBezierPathElementCurveTo)) {
                        [self _updateBezierHandleForLeftPoint:point
                                                  atLeftIndex:_position.currentOffset
                                                  centerIndex:0
                                                   rightIndex:[_path pointCount] - 2];
                    }
                }
            } else if ((_position.currentOp == AJRBezierPathElementLineTo) || (_position.currentOp == AJRBezierPathElementMoveTo)) {
                if (_position.nextOp == AJRBezierPathElementCurveTo) {
                    [_path movePointAtIndex:_position.currentOffset + 1 byDelta:delta];
                }
            }
            
            if (_position.previousOp == -1) {
                if (NSEqualPoints([_path pointAtIndex:_position.currentOffset], [_path lastPoint])) {
                    [_path movePointAtIndex:[_path pointCount] - 1 byDelta:delta];
                    if ([_path lastDrawingElementType] == AJRBezierPathElementCurveTo) {
                        [_path movePointAtIndex:[_path pointCount] - 2 byDelta:delta];
                    }
                }
            }
        }
        [_path setPointAtIndex:_position.currentOffset toPoint:point];
    }
    
    [self updateBounds];
    
    return handle;
}

- (NSRect)bounds {
    if (_frameAndBoundsAreDirty) {
        [self updateBounds];
    }
    return [super bounds];
}

- (NSRect)frame {
    if (_frameAndBoundsAreDirty) {
        [self updateBounds];
    }
    return [super frame];
}

- (void)draw {
    if (_frameAndBoundsAreDirty) {
        [self updateBounds];
    }
    [super draw];
}

- (void)setClosed:(BOOL)flag {
    if (flag != _closed) {
        [[self.document prepareWithInvocationTarget:self] setClosed:_closed];
        _closed = flag;
        if (flag) {
            [_path closePath];
        } else {
            [_path openPath];
        }
        [self setNeedsDisplay];
    }
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    DrawPen *new = [super copyWithZone:zone];
    
    new->_closed = _closed;
    
    return new;
}

#pragma mark - AJRXMLCoding

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super decodeWithXMLCoder:coder];
    [coder decodeBoolForKey:@"closed" setter:^(BOOL value) {
        self->_closed = value;
    }];
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)encoder {
    [super encodeWithXMLCoder:encoder];

    [encoder encodeBool:_closed forKey:@"closed"];
}

- (BOOL)isEqualToPen:(DrawPen *)other {
    return (self.class == other.class
            && [super isEqualToGraphic:other]
            && _closed == other->_closed);
}

- (BOOL)isEqual:(id)other {
    return self == other || ([other isKindOfClass:DrawPen.class] && [self isEqualToPen:other]);
}

- (BOOL)shouldEncodePath {
    return YES;
}

+ (NSString *)ajr_nameForXMLArchiving {
    return @"pen";
}

#pragma mark - Path Editing

- (void)setEditing:(BOOL)flag {
    if (!flag && self.editing) {
        [[self.page enclosingScrollView] setDocumentCursor:[[[self document] currentTool] cursor]];
    }
    if (!flag && _creating) {
        [self setCreating:NO];
    }
    [super setEditing:flag];
}

- (BOOL)flagsChanged:(DrawEvent *)event {
    NSInteger flags = [event modifierFlags];
    NSCursor *cursor = nil;
    
    if (!self.editing) {
        return NO;
    }
    
    if ((flags & NSEventModifierFlagShift) && (flags & NSEventModifierFlagOption)) {
        cursor = _creating ? [DrawPen cursorCrossAddCurveTo] : [DrawPen cursorArrowAddCurveTo];
    } else if (flags & NSEventModifierFlagShift) {
        cursor = _creating ? [DrawPen cursorCrossAdd] : [DrawPen cursorArrowAdd];
    } else if (flags & NSEventModifierFlagCommand) {
        cursor = _creating ? [DrawPen cursorCrossRemove] : [DrawPen cursorArrowRemove];
    } else if (flags & NSEventModifierFlagOption) {
        cursor = _creating ? [DrawPen cursorCrossAddMoveTo] : [DrawPen cursorArrowAddMoveTo];
    } else {
        cursor = [[[self document] currentTool] cursor];
    }

    [[self.page enclosingScrollView] setDocumentCursor:cursor];
    //AJRLogInfo(@"cursor: %@, %@", cursor, [[cursor image] name]);
    
    return YES;
}

- (BOOL)mouseDown:(DrawEvent *)event {
    NSInteger flags = [event modifierFlags];
    BOOL actionHappened = NO;
    
    if (!self.editing) {
        return NO;
    }
    
    if ((flags & NSEventModifierFlagShift) && (flags & NSEventModifierFlagOption)) {
        actionHappened = [self insertCurveToPoint:[event locationOnPage]];
    } else if (flags & NSEventModifierFlagShift) {
        actionHappened = [self insertPoint:[event locationOnPage]];
    } else if (flags & NSEventModifierFlagCommand) {
        actionHappened = [self removePoint:[event locationOnPage]];
    } else if (flags & NSEventModifierFlagControl) {
        actionHappened = [self appendMoveToPoint:[event locationOnPage]];
    }

    if (actionHappened) {
        _frameAndBoundsAreDirty = YES;
        [self setNeedsDisplay];
    }
    
    return actionHappened;
}

#pragma mark - Inspectors

- (NSArray<AJRInspectorIdentifier> *)inspectorIdentifiers {
    NSMutableArray<AJRInspectorIdentifier> *identifiers = [[super inspectorIdentifiers] mutableCopy];
    [identifiers addObject:AJRInspectorIdentifierPen];
    return identifiers;
}

@end
