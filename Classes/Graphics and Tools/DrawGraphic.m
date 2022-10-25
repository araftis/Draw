/*
DrawGraphic.m
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

#import "DrawGraphic.h"

#import "AJRBezierPath-DrawExtensions.h"
#import "DrawAspect.h"
#import "DrawDocument.h"
#import "DrawEvent.h"
#import "DrawFunctions.h"
#import "DrawLayer.h"
#import "DrawPage.h"
#import "DrawShadow.h"
#import "DrawText.h"
#import "AJRXMLCoder-DrawExtensions.h"
#import <Draw/Draw-Swift.h>

#import <AJRInterface/AJRInterface.h>

NSString *DrawGraphicDidInitNotification = @"DrawGraphicDidInitNotification";
NSString *DrawGraphicDidChangeFrameNotification = @"DrawGraphicDidChangeFrameNotification";
NSString *DrawFlatnessKey = @"DrawFlatnessKey";
const AJRInspectorIdentifier AJRInspectorIdentifierGraphic = @"graphic";
const DrawHandle DrawHandleMissed = (DrawHandle){DrawHandleTypeMissed, 0, 0};

static BOOL _notificationsAreDisabled = NO;

@interface DrawGraphic (Private)

- (void)_resizeSubgraphicsFromRect:(NSRect)oldFrame toRect:(NSRect)newFrame;

@end


@implementation DrawGraphic

+ (void)initialize {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{DrawFlatnessKey:@(1.0)}];
}

static BOOL _showsDirtyBounds = NO;

+ (BOOL)showsDirtyBounds {
    return _showsDirtyBounds;
}

+ (void)setShowsDirtyBounds:(BOOL)flag {
    _showsDirtyBounds = flag;
}

+ (NSImage *)handleImage {
    static NSImage *_handleImage = nil;

    if (!_handleImage) {
        _handleImage = [AJRImages imageNamed:@"handle" forClass:self];
    }

    return _handleImage;
}

+ (void)disableNotifications {
    _notificationsAreDisabled = YES;
}

+ (void)enableNotifications {
    _notificationsAreDisabled = NO;
}

+ (BOOL)notificationsAreDisabled {
    return _notificationsAreDisabled;
}

#pragma mark - Creation

- (void)draw_commonInit {
    // Mostly needed for xml coding initialization
    _handle.type = DrawHandleTypeCenter;

    _seed = random();
    _flatness = [[NSUserDefaults standardUserDefaults] floatForKey:DrawFlatnessKey];

    _path = [[AJRBezierPath alloc] init];

    _aspects = [[NSMutableArray alloc] initWithCapacity:DrawAspectPriorityLast - DrawAspectPriorityFirst];
    for (DrawAspectPriority priority = DrawAspectPriorityFirst; priority <= DrawAspectPriorityLast; priority++) {
        [_aspects addObject:[NSMutableArray array]];
    }

    _relatedGraphics = [[NSMutableSet alloc] init];
    _autosizeSubgraphics = YES;
    _autosizingMask = DrawGraphicAllSizable;
    _subgraphics = [[NSMutableArray alloc] init];

    _variableStore = [AJRStore store];
}

- (id)init {
    if ((self = [super init])) {
        [self draw_commonInit];
    }
    return self;
}

- (id)initWithFrame:(NSRect)aFrame {
    if ((self = [super init])) {
        [self draw_commonInit];

        _frame = AJRNormalizeRect(aFrame);
        if (_frame.size.width < 0.01) _frame.size.width = 0.01;
        if (_frame.size.height < 0.01) _frame.size.height = 0.01;

        if (!_notificationsAreDisabled) {
            [[NSNotificationCenter defaultCenter] postNotificationName:DrawGraphicDidInitNotification object:self];
        }

        if (NSEqualRects(_bounds, NSZeroRect)) {
            [self updateBounds];
        }
    }

    return self;
}

#pragma mark - Document, Pages, and Layers

- (void)setDocument:(DrawDocument *)aDocumentView {
    if (_document != aDocumentView) {
        NSInteger x;

        _document = aDocumentView;

        for (x = 0; x < (const NSInteger)[_subgraphics count]; x++) {
            [[_subgraphics objectAtIndex:x] setDocument:aDocumentView];
        }
    }
}

- (void)setPage:(DrawPage *)aPage {
    if (_page != aPage) {
        NSInteger x;

        _page = aPage;

        if (_supergraphic) {
            [_page observeGraphic:self yesNo:YES];
        }

        for (x = 0; x < (const NSInteger)[_subgraphics count]; x++) {
            [(DrawGraphic *)[_subgraphics objectAtIndex:x] setPage:_page];
        }
    }
}

- (void)setLayer:(DrawLayer *)aLayer {
    if (_layer != aLayer) {
        _layer = aLayer;
        for (DrawGraphic *subgraphic in _subgraphics) {
            [subgraphic setLayer:_layer];
        }
    }
}

#pragma mark - Frame

- (void)setFrameWithoutNotification:(NSRect)frame {
    _frame = frame;
}

- (void)setFrame:(NSRect)aFrame {
    if (!NSEqualRects(aFrame, _frame)) {
        NSRect deltaRect;
        NSRect oldFrame = _frame;
        BOOL informAspects = NO;

        [_page setNeedsDisplayInRect:[self dirtyBounds]];

        if ((aFrame.size.width > -0.01) && (aFrame.size.width < 0.01)) {
            if (aFrame.size.width < 0.0) aFrame.size.width = -0.01;
            else aFrame.size.width = 0.01;
        }
        if ((aFrame.size.height > -0.01) && (aFrame.size.height < 0.01)) {
            if (aFrame.size.height < 0.0) aFrame.size.height = -0.01;
            else aFrame.size.height = 0.01;
        }

        deltaRect.origin.x = (aFrame.origin.x - _frame.origin.x);
        deltaRect.origin.y = (aFrame.origin.y - _frame.origin.y);
        deltaRect.size.width = (aFrame.size.width / _frame.size.width);
        deltaRect.size.height = (aFrame.size.height / _frame.size.height);

        [(DrawGraphic *)[_document prepareWithInvocationTarget:self] setFrame:_frame];

        [_path setControlPointBounds:aFrame];

        if (NSEqualSizes(aFrame.size, _frame.size)) {
            _bounds.origin.x += deltaRect.origin.x;
            _bounds.origin.y += deltaRect.origin.y;
            informAspects = YES;
        } else {
            [self updateBounds];
        }

        _frame = AJRNormalizeRect(aFrame);

        if ([_subgraphics count] && !_editing && _autosizeSubgraphics) {
            [self _resizeSubgraphicsFromRect:oldFrame toRect:_frame];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:DrawGraphicDidChangeFrameNotification object:self];

        if (informAspects) {
            [self informAspectsOfShapeChange];
        }

        [self updateBounds];
        [_page setNeedsDisplayInRect:[self dirtyBounds]];
    }
}

- (void)setFrameOrigin:(NSPoint)origin {
    NSRect newFrame = {origin, _frame.size};
    [self setFrame:newFrame];
}

- (void)setFrameSize:(NSSize)size {
    [self setFrame:(NSRect){_frame.origin, size}];
}

- (NSRect)bounds {
    if (_boundsAreDirty) {
        [self updateBounds];
    }
    return _bounds;
}

- (NSRect)dirtyBounds {
    NSRect bounds = [self bounds];

    if ([[_page document] isGraphicSelected:self]) {
        NSImage *handleImage = [DrawGraphic handleImage];
        NSSize size = [handleImage size];
        CGFloat scale = [_page scale];

        bounds = NSInsetRect(bounds, -ceil((size.width / 2.0) / scale), -ceil((size.height / 2.0) / scale));
    }

    return bounds;
}

- (NSRect)dirtyBoundsWithRelatedObjects {
    NSRect dirtyBounds = [self dirtyBounds];

    if ([_relatedGraphics count]) {
        dirtyBounds = NSUnionRect(dirtyBounds, DrawBoundsForGraphics(_relatedGraphics));
    }

    return dirtyBounds;
}

- (NSPoint)centroid {
    return (NSPoint){_frame.origin.x + _frame.size.width / 2.0, _frame.origin.y + _frame.size.height / 2.0};
}

#pragma mark - Handles

- (DrawHandle)setHandle:(DrawHandle)handle toLocation:(NSPoint)point {
    NSRect workFrame = _frame;

    switch (handle.type) {
        case DrawHandleTypeTopLeft:
            workFrame.origin.x = point.x;
            workFrame.size.width = _frame.size.width - (point.x - _frame.origin.x);
            workFrame.origin.y = point.y;
            workFrame.size.height = _frame.size.height - (point.y - _frame.origin.y);
            break;
        case DrawHandleTypeTopCenter:
            workFrame.origin.y = point.y;
            workFrame.size.height = _frame.size.height - (point.y - _frame.origin.y);
            break;
        case DrawHandleTypeTopRight:
            workFrame.size.width = point.x - _frame.origin.x;
            workFrame.origin.y = point.y;
            workFrame.size.height = _frame.size.height - (point.y - _frame.origin.y);
            break;
        case DrawHandleTypeLeft:
            workFrame.origin.x = point.x;
            workFrame.size.width = _frame.size.width - (point.x - _frame.origin.x);
            break;
        case DrawHandleTypeCenter:
            _frame.origin.x += (point.x - (_frame.origin.x + (_frame.size.width / 2.0)));
            _frame.origin.y += (point.y - (_frame.origin.y + (_frame.size.height / 2.0)));
            break;
        case DrawHandleTypeRight:
            workFrame.size.width = point.x - _frame.origin.x;
            break;
        case DrawHandleTypeBottomLeft:
            workFrame.origin.x = point.x;
            workFrame.size.width = _frame.size.width - (point.x - _frame.origin.x);
            workFrame.size.height = point.y - _frame.origin.y;
            break;
        case DrawHandleTypeBottomCenter:
            workFrame.size.height = point.y - _frame.origin.y;
            break;
        case DrawHandleTypeBottomRight:
            workFrame.size.width = point.x - _frame.origin.x;
            workFrame.size.height = point.y - _frame.origin.y;
            break;
        default:
            break;
    }

    [self setFrame:workFrame];

    if (workFrame.size.width < 0.0) {
        switch (handle.type) {
            case DrawHandleTypeTopLeft:
                handle.type = DrawHandleTypeTopRight;
                break;
            case DrawHandleTypeTopRight:
                handle.type = DrawHandleTypeTopLeft;
                break;
            case DrawHandleTypeLeft:
                handle.type = DrawHandleTypeRight;
                break;
            case DrawHandleTypeRight:
                handle.type = DrawHandleTypeLeft;
                break;
            case DrawHandleTypeBottomLeft:
                handle.type = DrawHandleTypeBottomRight;
                break;
            case DrawHandleTypeBottomRight:
                handle.type = DrawHandleTypeBottomLeft;
                break;
            default:
                break;
        }
    }
    if (workFrame.size.height < 0.0) {
        switch (handle.type) {
            case DrawHandleTypeTopLeft:
                handle.type = DrawHandleTypeBottomLeft;
                break;
            case DrawHandleTypeTopRight:
                handle.type = DrawHandleTypeBottomRight;
                break;
            case DrawHandleTypeTopCenter:
                handle.type = DrawHandleTypeBottomCenter;
                break;
            case DrawHandleTypeBottomCenter:
                handle.type = DrawHandleTypeTopCenter;
                break;
            case DrawHandleTypeBottomLeft:
                handle.type = DrawHandleTypeTopLeft;
                break;
            case DrawHandleTypeBottomRight:
                handle.type = DrawHandleTypeTopRight;
                break;
            default:
                break;
        }
    }

    return handle;
}

- (NSPoint)locationOfHandle:(DrawHandle)aHandle {
    switch (aHandle.type) {
        case DrawHandleTypeTopLeft:
            return _frame.origin;
        case DrawHandleTypeTopCenter:
            return (NSPoint){_frame.origin.x + _frame.size.width / 2.0, _frame.origin.y};
        case DrawHandleTypeTopRight:
            return (NSPoint){_frame.origin.x + _frame.size.width, _frame.origin.y};
        case DrawHandleTypeLeft:
            return (NSPoint){_frame.origin.x, _frame.origin.y + _frame.size.height / 2.0};
        case DrawHandleTypeCenter:
            return (NSPoint){_frame.origin.x + _frame.size.width / 2.0, _frame.origin.y + _frame.size.height / 2.0};
        case DrawHandleTypeRight:
            return (NSPoint){_frame.origin.x + _frame.size.width, _frame.origin.y + _frame.size.height / 2.0};
        case DrawHandleTypeBottomLeft:
            return (NSPoint){_frame.origin.x, _frame.origin.y + _frame.size.height};
        case DrawHandleTypeBottomCenter:
            return (NSPoint){_frame.origin.x + _frame.size.width / 2.0, _frame.origin.y + _frame.size.height};
        case DrawHandleTypeBottomRight:
            return (NSPoint){_frame.origin.x + _frame.size.width, _frame.origin.y + _frame.size.height};
        default:
            break;
    }

    return NSZeroPoint;
}

- (void)noteBoundsAreDirty {
    _boundsAreDirty = YES;
}

- (BOOL)shouldEncodePath {
    return NO;
}

- (void)drawHandleAtPoint:(NSPoint)point {
    CGFloat scale = _page ? [_page scale] : 1.0;
    NSImage *handleImage = [DrawGraphic handleImage];
    NSSize size = [handleImage size];
    NSRect frame;

    frame = (NSRect){point, {size.width / scale, size.height / scale}};
    frame.origin.x -= (size.width / 2.0) / scale;
    if ([_page isFlipped]) {
        frame.origin.y -= (size.height / 2.0) / scale;
    } else {
        frame.origin.y += (size.height / 2.0) / scale;
    }
    frame = [_page centerScanRect:frame];

    [handleImage drawInRect:frame fromRect:(NSRect){NSZeroPoint, size} operation:NSCompositingOperationCopy fraction:1.0];
}

- (void)drawHandles {
    if (!_ignore) {
        if (NSEqualSizes(_frame.size, NSZeroSize)) {
            if (!NSEqualPoints(_frame.origin, NSZeroPoint)) {
                [self drawHandleAtPoint:_frame.origin];
            }
        } else {
            [self drawHandleAtPoint:(NSPoint){NSMinX(_frame), NSMinY(_frame)}];
            [self drawHandleAtPoint:(NSPoint){NSMidX(_frame), NSMinY(_frame)}];
            [self drawHandleAtPoint:(NSPoint){NSMaxX(_frame), NSMinY(_frame)}];
            [self drawHandleAtPoint:(NSPoint){NSMinX(_frame), NSMidY(_frame)}];
            [self drawHandleAtPoint:(NSPoint){NSMaxX(_frame), NSMidY(_frame)}];
            [self drawHandleAtPoint:(NSPoint){NSMinX(_frame), NSMaxY(_frame)}];
            [self drawHandleAtPoint:(NSPoint){NSMidX(_frame), NSMaxY(_frame)}];
            [self drawHandleAtPoint:(NSPoint){NSMaxX(_frame), NSMaxY(_frame)}];
        }
    }
}

#pragma mark - Drawing

- (void)setPath:(AJRBezierPath *)path {
    if (path != _path) {
        _path = path;
        _boundsAreDirty = YES;
        [self setNeedsDisplay];
    }
}

- (BOOL)drawAspect:(DrawAspect *)aspect withPriority:(DrawAspectPriority)priority path:(AJRBezierPath *)path completionBlocks:(NSMutableArray *)drawingCompletionBlocks {
    DrawGraphicCompletionBlock completionBlock;

    completionBlock = [aspect drawPath:path withPriority:priority];
    if (completionBlock) {
        [drawingCompletionBlocks addObject:completionBlock];
    }

    return [aspect rendersToCanvas];
}

- (BOOL)drawAspectsWithPriority:(DrawAspectPriority)priority path:(AJRBezierPath *)path aspectFilter:(DrawGraphicAspectFilter)filter completionBlocks:(NSMutableArray *)drawingCompletionBlocks; {
    NSArray *subaspects = [_aspects objectAtIndex:priority];
    BOOL didDraw = NO;

    for (DrawAspect *aspect in subaspects) {
        if ([aspect isActive] && (!filter || (filter && filter(aspect, priority)))) {
            if ([self drawAspect:aspect withPriority:priority path:path completionBlocks:drawingCompletionBlocks]) {
                didDraw = YES;
            }
        }
    }

    return didDraw;
}

- (void)draw {
    [self drawWithAspectFilter:NULL];
}

- (BOOL)isPrinting {
    return NSPrintOperation.currentOperation.printInfo.isPrinting;
}

- (BOOL)isTemplateGraphic {
    return self == self.document.templateGraphic;
}

- (void)drawWithAspectFilter:(DrawGraphicAspectFilter)filter {
    if (!_ignore) {
        if (!((_frame.size.width == 0.0) && (_frame.size.height == 0.0))) {
            NSGraphicsContext *context = [NSGraphicsContext currentContext];

            [context drawWithSavedGraphicsState:^(NSGraphicsContext *context) {
                AJRBezierPath *path = [self path];
                NSMutableArray *drawingCompletionBlocks = [[NSMutableArray alloc] init];
                BOOL didDraw = NO;

                [self.supergraphic addClip];
                if (self.editing && self.subgraphics.count) {
                    [[NSColor lightGrayColor] set];
                    [path setLineWidth:0.0];
                    [path setLineJoinStyle:0];
                    [path setLineCapStyle:0];
                    [path setMiterLimit:11.0];
                    [path setFlatness:1.0];
                    [path stroke];
                }

                for (DrawAspectPriority priority = DrawAspectPriorityFirst; priority <= DrawAspectPriorityLast; priority += 1) {
                    // We do something special for this, which is we draw our children before the aspects.
                    if (priority == DrawAspectPriorityChildren) {
                        [context drawWithSavedGraphicsState:^(NSGraphicsContext *context) {
                            [path addClip];
                            for (DrawGraphic *subgraphic in self->_subgraphics) {
                                [subgraphic drawWithAspectFilter:filter];
                            }
                        }];
                    }
                    if ([self drawAspectsWithPriority:priority path:path aspectFilter:filter completionBlocks:drawingCompletionBlocks]) {
                        didDraw = YES;
                    }
                }

                // This will be called when we have no aspects capable of drawing anything, at which point we display a "ghost" image of ourself, but only when drawing to the screen.
                if (!didDraw && !self.isPrinting) {
                    AJRBezierPathPointTransform savedTransform = [path strokePointTransform];

                    [[NSColor lightGrayColor] set];
                    [path setLineWidth:AJRHairLineWidth];
                    DrawGraphic * __weak weakSelf = self;
                    [path setStrokePointTransform:^(NSPoint point) {
                        DrawGraphic *strongSelf = weakSelf;
                        if (strongSelf != nil) {
                            NSRect rect = (NSRect){point, {1.0, 1.0}};
                            CGFloat offset = (1.0 / [strongSelf->_page scale]) / 2.0;
                            rect = [strongSelf->_page centerScanRect:rect];
                            return (NSPoint){rect.origin.x - offset, rect.origin.y - offset};
                        }
                        return point;
                    }];
                    [path stroke];

                    [path setStrokePointTransform:savedTransform];
                }

                for (DrawGraphicCompletionBlock completionBlock in [drawingCompletionBlocks reverseObjectEnumerator]) {
                    completionBlock();
                }

                if (filter == NULL && [DrawGraphic showsDirtyBounds]) {
                    CGFloat scale = self.page.scale;
                    CGFloat inset = (1.0 / scale) / 2.0;
                    AJRBezierPath *path = [AJRBezierPath bezierPathWithRect:NSInsetRect([self.page centerScanRect:self.dirtyBounds], -inset, -inset)];
                    CGFloat dash[2] = { 1.0, 2.0 };

                    [[NSColor lightGrayColor] set];
                    [path setLineDash:dash count:2 phase:0];
                    [path setLineWidth:AJRHairLineWidth];
                    [path stroke];
                }
            }];
        }
    }
}

- (void)setNeedsDisplay {
    // We might need to make this dirtyBoundsWithRelatedObjects.
    [_page setNeedsDisplayInRect:[self dirtyBounds]];
}

#pragma mark - Event Handling

- (BOOL)trackMouse:(DrawEvent *)event {
    return [self trackMouse:event fromHandle:DrawHandleMake(DrawHandleTypeBottomRight, 0, 0)];
}

- (BOOL)trackMouse:(DrawEvent *)drawEvent fromHandle:(DrawHandle)handle {
    _handle = handle;
    _mouseDownFlags = [drawEvent modifierFlags];

    if (DrawHandleIsBase(_handle)) {
        [(DrawGraphic *)[_document prepareWithInvocationTarget:self] setFrame:_frame];
        [[_document undoManager] disableUndoRegistration];
    }

    NSPoint currentPoint = [_document snapPointToGrid:[drawEvent locationOnPage]];
    if ([self startTrackingAt:currentPoint]) {
        NSPoint lastPoint;
        BOOL done = NO;
        while (!done) {
            lastPoint = currentPoint;

            NSEvent *event = [NSApp nextEventMatchingMask:NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged
                                                untilDate:[NSDate distantFuture]
                                                   inMode:NSEventTrackingRunLoopMode
                                                  dequeue:YES];
            currentPoint = [[drawEvent document] snapPointToGrid:[[drawEvent page] convertPoint:[event locationInWindow] fromView:nil]];

            switch ([event type]) {
                case NSEventTypeLeftMouseUp:
                    [self stopTracking:lastPoint at:currentPoint];
                    done = YES;
                    break;
                case NSEventTypeLeftMouseDragged:
                    done = ![self continueTracking:lastPoint at:currentPoint];
                    break;
                default:
                    break;
            }
        }
    }

    if (DrawHandleIsBase(_handle)) {
        [[_document undoManager] enableUndoRegistration];
    }

    return YES;
}

- (BOOL)startTrackingAt:(NSPoint)startPoint {
    return YES;
}

- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint {
    NSRect updateBounds;

    _ignore = YES;
    updateBounds = [self dirtyBounds];
    _ignore = NO;
    _handle = [self setHandle:_handle toLocation:currentPoint];
    updateBounds = NSUnionRect(updateBounds, DrawBoundsForGraphics(_relatedGraphics));
    [_page setNeedsDisplayInRect:updateBounds];

    return YES;
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint {
}

- (NSInteger)mouseDownFlags {
    return _mouseDownFlags;
}

- (void)setEditing:(BOOL)flag {
    if (flag != _editing) {
        _editing = flag;

        if (flag && [_subgraphics count]) {
            [_document performSelector:@selector(focusGroup:) withObject:self afterDelay:0.0001];
        }

        [_page setNeedsDisplayInRect:[self dirtyBounds]];
    }
    if (!flag) {
        NSArray *subaspects;
        NSInteger x, y;

        for (x = [_aspects count] - 1; x >= 0; x--) {
            subaspects = [_aspects objectAtIndex:x];
            for (y = [subaspects count] - 1; y >= 0; y--) {
                [[subaspects objectAtIndex:y] endEditing];
            }
        }
    }
}

- (BOOL)beginAspectEditingFromEvent:(DrawEvent *)event {
    NSArray *subaspects;
    NSInteger x, y;
    DrawAspect *aspect;

    for (x = [_aspects count] - 1; x >= 0; x--) {
        subaspects = [_aspects objectAtIndex:x];
        for (y = [subaspects count] - 1; y >= 0; y--) {
            aspect = [subaspects objectAtIndex:y];
            if ([aspect beginEditingFromEvent:event]) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)informAspectsOfShapeChange {
    [self enumerateAspectsWithBlock:^(DrawAspect *aspect) {
        [aspect graphicDidChangeShape:self];
    }];
    [_relatedGraphics makeObjectsPerformSelector:@selector(graphicDidChangeShape:) withObject:self];
}

- (NSRect)boundsForAspect:(DrawAspect *)aspect withPriority:(DrawAspectPriority)priority {
    return [aspect boundsForPath:[self path]];
}

- (void)updateBounds {
    BOOL createdBounds = NO;
    NSRect work;
    NSRect frameIncludingHandles;
    NSMutableArray *deferredBounds = [[NSMutableArray alloc] init];
    DrawAspectPriority priority;

    [self informAspectsOfShapeChange];

    frameIncludingHandles = NSInsetRect(_frame, -3.0, -3.0);

    for (priority = DrawAspectPriorityFirst; priority <= DrawAspectPriorityLast; priority++) {
        NSArray *aspectSubarray = [_aspects objectAtIndex:priority];
        for (DrawAspect *aspect in aspectSubarray) {
            if ([aspect isActive]) {
                if ([aspect boundsExpandsGraphicBounds]) {
                    [deferredBounds addObject:aspect];
                } else {
                    work = [self boundsForAspect:aspect withPriority:priority];
                    if (work.origin.x > -30000.0) {
                        if (!NSEqualRects(work, NSZeroRect)) {
                            work = NSUnionRect(frameIncludingHandles, work);
                            if (createdBounds) {
                                _bounds = NSUnionRect(_bounds, work);
                            } else {
                                createdBounds = YES;
                                _bounds = work;
                            }
                        }
                    }
                }
            }
        }
    }

    if (!createdBounds) {
        CGFloat inset = ceil(1.0 / [_page scale]);
        _bounds = NSInsetRect(_frame, -inset, -inset);
    }

    NSRect initialBounds = _bounds;
    for (DrawAspect *aspect in deferredBounds) {
        _bounds = NSUnionRect(_bounds, [aspect boundsForGraphicBounds:initialBounds]);
    }

    _boundsAreDirty = NO;
}

- (NSGraphicsContext *)hitContext {
    static NSGraphicsContext *_hitContext = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _hitContext = [NSGraphicsContext graphicsContextWithAttributes:@{}];
    });
    return _hitContext;
}

- (BOOL)isPoint:(NSPoint)aPoint inHandleAt:(NSPoint)otherPoint {
    CGFloat adjustment = 3.0; //[_page error];

    return (aPoint.x > otherPoint.x - adjustment) && (aPoint.x < otherPoint.x + adjustment) && (aPoint.y > otherPoint.y - adjustment) && (aPoint.y < otherPoint.y + adjustment);
}

- (DrawHandle)pathHandleForPoint:(NSPoint)point {
    return [_path drawHandleForPoint:point error:3.0/*[_page error]*/];
}

- (DrawHandle)pathHandleFromEvent:(NSEvent *)anEvent {
    return [self pathHandleForPoint:[_page convertPoint:[anEvent locationInWindow] fromView:nil]];
}

- (NSPoint)pointForHandle:(DrawHandle)handle {
    if ([_page isFlipped]) {
        switch (handle.type) {
            case DrawHandleTypeMissed:
                return [self centroid];
            case DrawHandleTypeTopLeft:
                return _frame.origin;
            case DrawHandleTypeTopCenter:
                return (NSPoint){_frame.origin.x + _frame.size.width / 2.0, _frame.origin.y};
            case DrawHandleTypeTopRight:
                return (NSPoint){_frame.origin.x + _frame.size.width, _frame.origin.y};
            case DrawHandleTypeLeft:
                return (NSPoint){_frame.origin.x, _frame.origin.y + _frame.size.height / 2.0};
            case DrawHandleTypeCenter:
                return (NSPoint){_frame.origin.x + _frame.size.width / 2.0, _frame.origin.y + _frame.size.height / 2.0};
            case DrawHandleTypeRight:
                return (NSPoint){_frame.origin.x + _frame.size.width, _frame.origin.y + _frame.size.height / 2.0};
            case DrawHandleTypeBottomLeft:
                return (NSPoint){_frame.origin.x, _frame.origin.y + _frame.size.height};
            case DrawHandleTypeBottomCenter:
                return (NSPoint){_frame.origin.x + _frame.size.width / 2.0, _frame.origin.y + _frame.size.height};
            case DrawHandleTypeBottomRight:
                return (NSPoint){_frame.origin.x + _frame.size.width, _frame.origin.y + _frame.size.height};
            case DrawHandleTypeIndexed: {
                NSPoint points[3];
                [_path elementAtIndex:handle.elementIndex associatedPoints:points];
                return points[handle.subindex];
            }
        }
    } else {
        switch (handle.type) {
            case DrawHandleTypeMissed:
                return [self centroid];
            case DrawHandleTypeTopLeft:
                return (NSPoint){_frame.origin.x, _frame.origin.y + _frame.size.height};
            case DrawHandleTypeTopCenter:
                return (NSPoint){_frame.origin.x + _frame.size.width / 2.0, _frame.origin.y + _frame.size.height};
            case DrawHandleTypeTopRight:
                return (NSPoint){_frame.origin.x + _frame.size.width, _frame.origin.y + _frame.size.height};
            case DrawHandleTypeLeft:
                return (NSPoint){_frame.origin.x, _frame.origin.y + _frame.size.height / 2.0};
            case DrawHandleTypeCenter:
                return (NSPoint){_frame.origin.x + _frame.size.width / 2.0, _frame.origin.y + _frame.size.height / 2.0};
            case DrawHandleTypeRight:
                return (NSPoint){_frame.origin.x + _frame.size.width, _frame.origin.y + _frame.size.height / 2.0};
            case DrawHandleTypeBottomLeft:
                return _frame.origin;
            case DrawHandleTypeBottomCenter:
                return (NSPoint){_frame.origin.x + _frame.size.width / 2.0, _frame.origin.y};
            case DrawHandleTypeBottomRight:
                return (NSPoint){_frame.origin.x + _frame.size.width, _frame.origin.y};
            case DrawHandleTypeIndexed: {
                NSPoint points[3];
                [_path elementAtIndex:handle.elementIndex associatedPoints:points];
                return points[handle.subindex];
            }
        }
    }

    return [self centroid];
}

- (DrawHandle)handleForPoint:(NSPoint)point {
    DrawHandle location = DrawHandleMissed;
    CGFloat adjustment = 3.0;//[_page error];

    // We only check for a hit of a _handle if we are drawing them. Otherwise, we only care if we hit the stroke to fill of the graphic.
    if ((point.x > (_frame.origin.x - adjustment)) && (point.x < (_frame.origin.x + adjustment))) {
        if ((point.y > (_frame.origin.y - adjustment)) && (point.y < (_frame.origin.y + adjustment))) {
            location.type = DrawHandleTypeTopLeft;
        } else if ((point.y > (_frame.origin.y + _frame.size.height - adjustment)) && (point.y < (_frame.origin.y + _frame.size.height + adjustment))) {
            location.type = DrawHandleTypeBottomLeft;
        } else if ((point.y > (_frame.origin.y + _frame.size.height / 2.0 - adjustment)) && (point.y < (_frame.origin.y + _frame.size.height / 2.0 + adjustment))) {
            location.type = DrawHandleTypeLeft;
        }
    } else if ((point.x > (_frame.origin.x + _frame.size.width - adjustment)) && (point.x < (_frame.origin.x + _frame.size.width + adjustment))) {
        if ((point.y > (_frame.origin.y - adjustment)) && (point.y < (_frame.origin.y + adjustment))) {
            location.type = DrawHandleTypeTopRight;
        } else if ((point.y > (_frame.origin.y + _frame.size.height - adjustment)) && (point.y < (_frame.origin.y + _frame.size.height + adjustment))) {
            location.type = DrawHandleTypeBottomRight;
        } else if ((point.y > (_frame.origin.y + _frame.size.height / 2.0 - adjustment)) && (point.y < (_frame.origin.y + _frame.size.height / 2.0 + adjustment))) {
            location.type = DrawHandleTypeRight;
        }
    } else if ((point.x > (_frame.origin.x + _frame.size.width / 2.0 - adjustment)) && (point.x < (_frame.origin.x + _frame.size.width / 2.0 + adjustment))) {
        if ((point.y > (_frame.origin.y - adjustment)) && (point.y < (_frame.origin.y + adjustment))) {
            location.type = DrawHandleTypeTopCenter;
        } else if ((point.y > (_frame.origin.y + _frame.size.height - adjustment)) && (point.y < (_frame.origin.y + _frame.size.height + adjustment))) {
            location.type = DrawHandleTypeBottomCenter;
        }
    }

    return location;
}

- (BOOL)isHitByPoint:(NSPoint)aPoint forAspectsWithPriority:(DrawAspectPriority)priority {
    for (DrawAspect *aspect in [_aspects objectAtIndex:priority]) {
        if ([aspect isActive] && [aspect isPoint:aPoint inPath:_path withPriority:priority]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isHitByRect:(NSRect)rect forAspectsWithPriority:(DrawAspectPriority)priority {
    for (DrawAspect *aspect in [_aspects objectAtIndex:priority]) {
        if ([aspect isActive] && [aspect doesRect:rect intersectPath:_path withPriority:priority]) {
            return YES;
        }
    }
    return NO;
}

- (NSArray<DrawGraphic *> *)graphicsHitByGraphicTest:(NSArray<DrawGraphic *> * (^)(DrawGraphic *graphic))graphicTest
                                          aspectTest:(BOOL (^)(DrawAspectPriority priority))aspectTest
                                            pathTest:(BOOL (^)(AJRBezierPath *path))pathTest {
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    NSMutableArray<DrawGraphic *> *hit = nil;
    NSArray<DrawGraphic *> *others;
    BOOL hasAspects = NO;

    for (DrawGraphic *subgraphic in [_subgraphics reverseObjectEnumerator]) {
        others = graphicTest(subgraphic);
        if ([others count]) {
            if (!hit) {
                hit = [NSMutableArray array];
            }
            [hit addObjectsFromArray:others];
        }
    }

    if (!_editing) {
        if ([hit count]) {
            return @[self];
        }
    }

    [NSGraphicsContext setCurrentContext:[self hitContext]];

    for (DrawAspectPriority priority = DrawAspectPriorityFirst; priority <= DrawAspectPriorityLast; priority++) {
        if (aspectTest(priority)) {
            if (!hit) {
                hit = [NSMutableArray array];
            }
            [hit addObject:self];
            break;
        }
        hasAspects = YES;
    }

    // if we had no aspects capable of causing a hit, then see if our stroke was hit.
    if (!hasAspects) {
        // This just makes really small lines easier to actual hit with the mouse.
        [_path setLineWidth:3.0 / [_page scale]];
        if (pathTest(_path)) {
            if (!hit) {
                hit = [NSMutableArray array];
            }
            [hit addObject:self];
        }
    }

    [NSGraphicsContext setCurrentContext:context];

    return hit;
}

- (NSArray<DrawGraphic *> *)graphicsHitByPoint:(NSPoint)point; {
    return [self graphicsHitByGraphicTest:^NSArray<DrawGraphic *> *(DrawGraphic *graphic) {
        return [graphic graphicsHitByPoint:point];
    } aspectTest:^BOOL(DrawAspectPriority priority) {
        return [self isHitByPoint:point forAspectsWithPriority:priority];
    } pathTest:^BOOL(AJRBezierPath *path) {
        return [path isStrokeHitByPoint:point];
    }];
}

- (NSArray<DrawGraphic *> *)graphicsHitByRect:(NSRect)rect {
    return [self graphicsHitByGraphicTest:^NSArray<DrawGraphic *> *(DrawGraphic *graphic) {
        return [graphic graphicsHitByRect:rect];
    } aspectTest:^BOOL(DrawAspectPriority priority) {
        return [self isHitByRect:rect forAspectsWithPriority:priority];
    } pathTest:^BOOL(AJRBezierPath *path) {
        return [path isHitByRect:rect];
    }];
}

#pragma mark - Aspects

- (void)enumerateAspectsWithBlock:(void (^)(DrawAspect *aspect))block {
    for (NSArray *subaspects in _aspects) {
        for (DrawAspect *aspect in subaspects) {
            block(aspect);
        }
    }
}

- (void)addAspect:(DrawAspect *)aspect {
    [self addAspect:aspect withPriority:[aspect.class defaultPriority]];
}

- (void)addAspect:(DrawAspect *)aspect withPriority:(DrawAspectPriority)priority {
    NSMutableArray *subaspects = [_aspects objectAtIndex:priority];

    if ([subaspects indexOfObjectIdenticalTo:aspect] == NSNotFound) {
        [aspect willAddToGraphic:self];
        [aspect willAddToDocument:_document];
        [[_aspects objectAtIndex:priority] addObject:aspect];
        [aspect setGraphic:self];
        [aspect didAddToGraphic:self];
        [aspect didAddToDocument:_document];
        [self updateBounds];
        [self setNeedsDisplay];
    }
}

- (NSArray *)aspects {
    return _aspects;
}

- (NSArray *)aspectsForPriority:(DrawAspectPriority)priority {
    return [_aspects objectAtIndex:priority];
}

- (DrawAspect *)firstAspectOfType:(Class)aspectType withPriority:(DrawAspectPriority)priority {
    return [self firstAspectOfType:aspectType withPriority:priority create:NO];
}

- (nullable DrawAspect *)firstAspectOfType:(Class)aspectType withPriority:(DrawAspectPriority)priority create:(BOOL)flag {
    DrawAspect *foundAspect = nil;

    for (DrawAspect *aspect in [_aspects objectAtIndex:priority]) {
        if ([aspect isKindOfClass:aspectType]) {
            foundAspect = aspect;
            break;
        }
    }

    if (foundAspect == nil && flag) {
        // NOTE: Could still return nil, since not all aspect will provide a default. However, it's generally a contract between the aspect and the caller that if they're asking for an aspect to create itself, it'll be passing in an aspect type that will return an object.
        foundAspect = [aspectType defaultAspectForGraphic:self];
        [self addAspect:foundAspect withPriority:priority];
    }

    return foundAspect;
}

- (NSArray *)prioritiesForAspect:(DrawAspect *)aspect {
    NSInteger x;
    NSUInteger index;
    NSMutableArray *priorities = [[NSMutableArray alloc] init];

    for (x = 0; x < (const NSInteger)[_aspects count]; x++) {
        index = [[_aspects objectAtIndex:x] indexOfObjectIdenticalTo:aspect];
        if (index != NSNotFound) {
            [priorities addObject:[NSNumber numberWithInteger:x]];
        }
    }

    return priorities;
}

- (void)removeAllAspects {
    NSInteger x;

    for (x = 0; x < (const NSInteger)[_aspects count]; x++) {
        [[_aspects objectAtIndex:x] removeAllObjects];
    }

    [self updateBounds];
    [self setNeedsDisplay];
}

- (void)removeAspect:(DrawAspect *)aspect {
    NSInteger x;

    [aspect willRemoveFromDocument:_document];
    [aspect willRemoveFromGraphic:self];
    for (x = 0; x < (const NSInteger)[_aspects count]; x++) {
        [[_aspects objectAtIndex:x] removeObjectIdenticalTo:aspect];
    }
    [aspect didRemoveFromGraphic:self];
    [aspect didRemoveFromDocument:_document];

    [self updateBounds];
    [self setNeedsDisplay];
}

- (void)takeAspectsFromGraphic:(DrawGraphic *)otherGraphic {
    _aspects = [[NSMutableArray alloc] initWithCapacity:DrawAspectPriorityLast - DrawAspectPriorityFirst];
    for (NSArray *otherSubaspects in otherGraphic->_aspects) {
        NSMutableArray *subaspects = [[NSMutableArray alloc] init];
        [_aspects addObject:subaspects];

        for (DrawAspect *aspect in otherSubaspects) {
            DrawAspect *copy = [aspect copy];
            [copy setGraphic:self];
            [aspect willAddToGraphic:self];
            [aspect willAddToDocument:_document];
            [subaspects addObject:copy];
            [aspect didRemoveFromGraphic:self];
            [aspect didAddToDocument:_document];
        }
    }

    [self updateBounds];
    [self setNeedsDisplay];
}

- (BOOL)hasAspectOfType:(Class)aspectType {
    for (NSArray *subaspects in _aspects) {
        for (DrawAspect *aspect in subaspects) {
            if ([aspect isKindOfClass:aspectType]) return YES;
        }
    }
    return NO;
}

- (BOOL)hasAspectOfType:(Class)aspectType withPriority:(DrawAspectPriority)priority {
    for (DrawAspect *aspect in [_aspects objectAtIndex:priority]) {
        if ([aspect isKindOfClass:aspectType]) {
            return YES;
        }
    }
    return NO;
}

- (DrawAspect *)primaryAspectOfType:(Class)aspectClass create:(BOOL)createFlag {
    DrawAspect *aspect = [self firstAspectOfType:aspectClass withPriority:[aspectClass defaultPriority]];
    if (aspect == nil && createFlag) {
        aspect = [[[[self document] templateGraphic] firstAspectOfType:aspectClass withPriority:[aspectClass defaultPriority] create:YES] copy];
        [self addAspect:aspect withPriority:[aspectClass defaultPriority]];
    }
    return aspect;
}

- (DrawStroke *)primaryStroke {
    return (DrawStroke *)[self primaryAspectOfType:DrawStroke.class create:YES];
}

- (DrawFill *)primaryFill {
    return (DrawFill *)[self primaryAspectOfType:DrawFill.class create:YES];
}

- (DrawShadow *)primaryShadow {
    return (DrawShadow *)[self primaryAspectOfType:DrawShadow.class create:YES];
}

- (DrawReflection *)primaryReflection {
    return (DrawReflection *)[self primaryAspectOfType:DrawReflection.class create:YES];
}

- (DrawText *)primaryText {
    return (DrawText *)[self primaryAspectOfType:DrawText.class create:YES];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)aZone {
    DrawGraphic *new = [[self class] allocWithZone:aZone];

    new->_frame = _frame;
    new->_bounds = _bounds;
    new->_path = [_path copyWithZone:aZone];
    [new takeAspectsFromGraphic:self];
    new->_handle = _handle;
    new->_ignore = NO;
    new->_editing = NO;
    new->_autosizeSubgraphics = _autosizeSubgraphics;
    new->_autosizingMask = _autosizingMask;
    new->_subgraphics = [_subgraphics copyWithZone:aZone];
    new->_supergraphic = _supergraphic;
    [new->_subgraphics setValue:new forKey:@"supergraphic"];
    new->_variableStore = [_variableStore copyWithZone:aZone];

    return new;
}

#pragma mark - AJRXMLCoding

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [coder decodeRectForKey:@"frame" setter:^(CGRect rect) {
        self->_frame = rect;
    }];
    [coder decodeObjectForKey:@"path" setter:^(id  _Nonnull object) {
        self->_path = object;
    }];
    [coder decodeGroupForKey:@"aspects" usingBlock:^{
        NSArray<NSString *> *names = [self.class priorityNames];
        for (NSInteger x = 0; x < names.count; x++) {
            [coder decodeObjectForKey:names[x] setter:^(id  _Nonnull object) {
                for (DrawAspect *aspect in object) {
                    [aspect willAddToGraphic:self];
                }
                self->_aspects[x] = object;
            }];
        }
    } setter:^{
    }];
    [coder decodeDrawHandleForKey:@"handle" setter:^(DrawHandle handle) {
        self->_handle = handle;
    }];
    [coder decodeObjectForKey:@"relatedGraphics" setter:^(id  _Nonnull object) {
        self->_relatedGraphics = [object mutableCopy];
    }];
    [coder decodeFloatForKey:@"flatness" setter:^(float value) {
        self->_flatness = value;
    }];
    [coder decodeObjectForKey:@"subgraphics" setter:^(id  _Nonnull object) {
        self->_subgraphics = [object mutableCopy];
    }];
    [coder decodeObjectForKey:@"supergraphic" setter:^(id  _Nonnull object) {
        self->_supergraphic = object;
    }];
    [coder decodeBoolForKey:@"autosizeSubgraphics" setter:^(BOOL value) {
        self->_autosizeSubgraphics = value;
    }];
    [coder decodeIntegerForKey:@"autosizingMask" setter:^(NSInteger value) {
        self->_autosizingMask = value;
    }];
    [coder decodeUIntegerForKey:@"seed" setter:^(NSUInteger value) {
        self->_seed = value;
    }];
    [coder decodeObjectForKey:@"variableStore" setter:^(id object) {
        if (object == nil) {
            self->_variableStore = [AJRStore store];
        } else {
            self->_variableStore = object;
        }
    }];
}

+ (NSArray<NSString *> *)priorityNames {
    static NSArray<NSString *> *priorityNames;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        priorityNames = @[@"beforeBackground",
                          @"background",
                          @"afterBackground",
                          @"beforeChildren",
                          @"children",
                          @"afterChildren",
                          @"beforeForeground",
                          @"foreground",
                          @"afterForeground"];
    });
    return priorityNames;
}

/// Returns `YES` if aspects count > 0 and at least one aspect returns `YES` to should encode.
- (BOOL)shouldEncodeAspects:(NSArray<DrawAspect *> *)aspects {
    return aspects.count > 0 && [aspects ajr_firstObjectPassingTest:^BOOL(DrawAspect *object) {
        return [[object class] shouldArchive];
    }] != nil;
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)encoder {
    [encoder encodeRect:_frame forKey:@"frame"];
    if (self.shouldEncodePath) {
        [encoder encodeObject:_path forKey:@"path"];
    }

    NSArray<NSString *> *names = [self.class priorityNames];
    BOOL hasAspectsToEncode = NO;
    for (NSInteger x = 0; x < names.count; x++) {
        if ([self shouldEncodeAspects:_aspects[x]]) {
            hasAspectsToEncode = YES;
            break;
        }
    }
    if (hasAspectsToEncode) {
        [encoder encodeGroupForKey:@"aspects" usingBlock:^{
            for (NSInteger x = 0; x < names.count; x++) {
                if ([self shouldEncodeAspects:self->_aspects[x]]) {
                    [encoder encodeObject:self->_aspects[x] forKey:names[x]];
                }
            }
        }];
    }
    [encoder encodeDrawHandle:_handle forKey:@"handle"];
    if (_relatedGraphics.count > 0) {
        [encoder encodeObject:_relatedGraphics forKey:@"relatedGraphics"];
    }
    [encoder encodeFloat:_flatness forKey:@"flatness"];
    if (_subgraphics.count > 0) {
        [encoder encodeObject:_subgraphics forKey:@"subgraphics"];
    }
    [encoder encodeObjectIfNotNil:_supergraphic forKey:@"supergraphic"];
    [encoder encodeBool:_autosizeSubgraphics forKey:@"autosizeSubgraphics"];
    [encoder encodeInteger:_autosizingMask forKey:@"autosizingMask"];
    [encoder encodeUInteger:_seed forKey:@"seed"];
    if (_variableStore.count > 0) {
        [encoder encodeObject:_variableStore forKey:@"variableStore"];
    }
}

- (id)finalizeXMLDecodingWithError:(NSError * _Nullable __autoreleasing *)error {
    // Aspects don't archive a reference to their graphic, since that makes the XML cleaner.
    for (NSArray<DrawAspect *> *subaspects in _aspects) {
        for (DrawAspect *aspect in subaspects) {
            aspect.graphic = self;
            [aspect didAddToGraphic:self];
        }
    }
    // Make sure to mark this, because if we're reading from a document, we're definitely dirty.
    _boundsAreDirty = YES;
    return self;
}

- (BOOL)isEqualToGraphic:(DrawGraphic *)other {
    return (self.class == other.class
            && AJREqual(_document, other->_document)
            && AJREqual(_page, other->_page)
            && AJREqual(_layer, other->_layer)
            && NSEqualRects(_frame, other->_frame)
            && _seed == other->_seed
            && AJREqual(_path, other->_path)
            && AJREqual(_aspects, other->_aspects)
            && DrawHandleEqual(_handle, other->_handle)
            //&& AJREqual(_relatedGraphics, other->_relatedGraphics) // Checking this causes an infinite loop.
            && _flatness == other->_flatness
            && AJREqual(_subgraphics, other->_subgraphics)
            && AJREqual(_supergraphic, other->_supergraphic)
            && _autosizeSubgraphics == other->_autosizeSubgraphics
            && _autosizingMask == other->_autosizingMask
            && AJREqual(_variableStore, other->_variableStore));
}

- (BOOL)isEqual:(id)other {
    return self == other || ([other isKindOfClass:[DrawGraphic class]] && [self isEqualToGraphic:other]);
}

+ (NSString *)ajr_nameForXMLArchiving {
    return @"graphic";
}

#pragma mark - Event Handling

- (void)moveHandle:(DrawHandle)aHandle byDelta:(NSPoint)delta {
    NSPoint location = [self locationOfHandle:aHandle];
    location.x += delta.x;
    location.y += delta.y;
    [self setHandle:aHandle toLocation:location];
}

- (void)moveFrameOriginByDelta:(NSPoint)delta {
    NSRect frame = [self frame];
    frame.origin.x += delta.x;
    frame.origin.y += delta.y;
    [self setFrame:frame];
}

- (BOOL)keyDown:(NSEvent *)event {
    unichar character = [[event characters] characterAtIndex:0];
    CGFloat delta = 1.0;

    if ([_document gridEnabled]) {
        delta = [_document gridSpacing];
    }

    if ([event modifierFlags] & NSEventModifierFlagControl) {
        switch (character) {
            case NSUpArrowFunctionKey:
                if ([_page isFlipped]) {
                    [self moveHandle:DrawHandleMake(DrawHandleTypeBottomCenter, 0, 0) byDelta:(NSPoint){0.0, -delta}];
                    break;
                } else {
                    [self moveHandle:DrawHandleMake(DrawHandleTypeTopCenter, 0, 0) byDelta:(NSPoint){0.0, delta}];
                }
                return YES;
            case NSDownArrowFunctionKey:
                if ([_page isFlipped]) {
                    [self moveHandle:DrawHandleMake(DrawHandleTypeBottomCenter, 0, 0) byDelta:(NSPoint){0.0, delta}];
                } else {
                    [self moveHandle:DrawHandleMake(DrawHandleTypeTopCenter, 0, 0) byDelta:(NSPoint){0.0, -delta}];
                }
                return YES;
            case NSLeftArrowFunctionKey:
                [self moveHandle:DrawHandleMake(DrawHandleTypeRight, 0, 0) byDelta:(NSPoint){-delta, 0.0}];
                return YES;
            case NSRightArrowFunctionKey:
                [self moveHandle:DrawHandleMake(DrawHandleTypeRight, 0, 0) byDelta:(NSPoint){delta, 0.0}];
                return YES;
        }
    } else {
        switch (character) {
            case NSUpArrowFunctionKey:
                [self moveFrameOriginByDelta:(NSPoint){0.0, [_page isFlipped] ? -delta : delta}];
                return YES;
            case NSDownArrowFunctionKey:
                [self moveFrameOriginByDelta:(NSPoint){0.0, [_page isFlipped] ? delta : -delta}];
                return YES;
            case NSLeftArrowFunctionKey:
                [self moveFrameOriginByDelta:(NSPoint){-delta, 0.0}];
                return YES;
            case NSRightArrowFunctionKey:
                [self moveFrameOriginByDelta:(NSPoint){delta, 0.0}];
                return YES;
        }
    }
    return NO;
}

#pragma mark - Notifications

- (void)graphicWillAddToDocument:(DrawDocument *)view {
    [self enumerateAspectsWithBlock:^(DrawAspect *aspect) {
        [aspect willAddToDocument:view];
    }];
}

- (void)graphicDidAddToDocument:(DrawDocument *)view {
    [self enumerateAspectsWithBlock:^(DrawAspect *aspect) {
        [aspect didAddToDocument:view];
    }];
}

- (void)graphicWillAddToPage:(DrawPage *)page {
    [self enumerateAspectsWithBlock:^(DrawAspect *aspect) {
        [aspect willAddToPage:page];
    }];
}

- (void)graphicDidAddToPage:(DrawPage *)page {
    [self enumerateAspectsWithBlock:^(DrawAspect *aspect) {
        [aspect didAddToPage:page];
    }];
}

- (void)graphicWillRemoveFromDocument:(DrawDocument *)view {
    [self enumerateAspectsWithBlock:^(DrawAspect *aspect) {
        [aspect willRemoveFromDocument:view];
    }];
}

- (void)graphicDidRemoveFromDocument:(DrawDocument *)view {
    _document = nil;
    _page = nil;
    _layer = nil;
    [self enumerateAspectsWithBlock:^(DrawAspect *aspect) {
        [aspect didRemoveFromDocument:view];
    }];
}

#pragma mark - Links

- (NSSet *)relatedGraphics {
    return _relatedGraphics;
}

- (void)addToRelatedGraphics:(DrawGraphic *)graphic {
    [_relatedGraphics addObject:graphic];
}

- (void)removeFromRelatedGraphics:(DrawGraphic *)graphic {
    [_relatedGraphics removeObject:graphic];
}

- (NSPoint)intersectionWithLineEndingAtPoint:(NSPoint)aPoint found:(BOOL *)found {
    NSArray *intersections;
    AJRLine line;

    line.start = aPoint;
    line.end = [self centroid];

    intersections = [_path intersectionsWithLine:line error:0.1];
    if (intersections) {
        *found = YES;
        intersections = [intersections sortedArrayFromPoint:aPoint];
        return [[intersections objectAtIndex:0] point];
    }

    *found = NO;
    return (NSPoint){0.0, 0.0};
}

#pragma mark - Sheer randomness

- (void)resetRandomNumberSequence {
    srandom((unsigned)_seed);
}

- (NSInteger)randomNumberInRange:(NSRange)range {
    return random() % range.length + range.location;
}

#pragma mark - Error

- (void)setFlatness:(CGFloat)aFlatness {
    if (_flatness != aFlatness) {
        [[_document prepareWithInvocationTarget:self] setFlatness:_flatness];
        _flatness = aFlatness;
        [self updateBounds];
    }
}

- (CGFloat)error {
    return [_page error];
}

#pragma mark - Inspectors

- (NSArray<AJRInspectorIdentifier> *)inspectorIdentifiers {
    NSMutableArray<AJRInspectorIdentifier> *identifiers = [[super inspectorIdentifiers] mutableCopy];
    [identifiers addObject:AJRInspectorIdentifierGraphic];
    return identifiers;
}

@end

DrawHandle DrawHandleMake(DrawHandleType type, NSInteger elementIndex, NSInteger index) {
    return (DrawHandle){type, elementIndex, index};
}

BOOL DrawHandleEqual(DrawHandle handle1, DrawHandle handle2) {
    return (handle1.type == handle2.type) && (handle1.elementIndex == handle2.elementIndex) && (handle1.subindex == handle2.subindex);
}

NSString *DrawStringFromDrawHandleType(DrawHandleType type) {
    switch (type) {
        case DrawHandleTypeMissed:
            return @"Missed";
        case DrawHandleTypeIndexed:
            return @"Indexed";
        case DrawHandleTypeTopLeft:
            return @"TopLeft";
        case DrawHandleTypeTopCenter:
            return @"TopCenter";
        case DrawHandleTypeTopRight:
            return @"TopRight";
        case DrawHandleTypeLeft:
            return @"Left";
        case DrawHandleTypeCenter:
            return @"Center";
        case DrawHandleTypeRight:
            return @"Right";
        case DrawHandleTypeBottomLeft:
            return @"BottomLeft";
        case DrawHandleTypeBottomCenter:
            return @"BottomCenter";
        case DrawHandleTypeBottomRight:
            return @"BottomRight";
    }
    return @"Missed";
}

DrawHandleType DrawHandleTypeFromString(NSString *string) {
    if ([string caseInsensitiveCompare:@"Missed"] == NSOrderedSame) {
        return DrawHandleTypeMissed;
    }
    if ([string caseInsensitiveCompare:@"Indexed"] == NSOrderedSame) {
        return DrawHandleTypeMissed;
    }
    if ([string caseInsensitiveCompare:@"TopLeft"] == NSOrderedSame) {
        return DrawHandleTypeMissed;
    }
    if ([string caseInsensitiveCompare:@"TopCenter"] == NSOrderedSame) {
        return DrawHandleTypeMissed;
    }
    if ([string caseInsensitiveCompare:@"TopRight"] == NSOrderedSame) {
        return DrawHandleTypeMissed;
    }
    if ([string caseInsensitiveCompare:@"Left"] == NSOrderedSame) {
        return DrawHandleTypeMissed;
    }
    if ([string caseInsensitiveCompare:@"Center"] == NSOrderedSame) {
        return DrawHandleTypeMissed;
    }
    if ([string caseInsensitiveCompare:@"Right"] == NSOrderedSame) {
        return DrawHandleTypeMissed;
    }
    if ([string caseInsensitiveCompare:@"BottomLeft"] == NSOrderedSame) {
        return DrawHandleTypeMissed;
    }
    if ([string caseInsensitiveCompare:@"BottomCenter"] == NSOrderedSame) {
        return DrawHandleTypeMissed;
    }
    if ([string caseInsensitiveCompare:@"BottomRight"] == NSOrderedSame) {
        return DrawHandleTypeMissed;
    }
    return DrawHandleTypeMissed;
}

NSString *DrawStringFromHandle(DrawHandle handle) {
    if (handle.type == DrawHandleTypeIndexed) {
        if (handle.subindex == 0) {
            // For brevity, if the subindex is 0, don't include it.
            return [NSString stringWithFormat:@"{elementIndex = %ld}", handle.elementIndex];
        } else {
            return [NSString stringWithFormat:@"{elementIndex = %ld; subindex = %ld}", handle.elementIndex, handle.subindex];
        }
    } else if (handle.type == DrawHandleTypeMissed) {
        return @"{}";
    } else {
        return [NSString stringWithFormat:@"{handle = \"%@\"}", DrawStringFromDrawHandleType(handle.type)];
    }
}

DrawHandle DrawHandleFromString(NSString *string) {
    NSDictionary<NSString *, id> *dict = [string propertyList];

    if (dict == nil || dict.count == 0) {
        return DrawHandleMake(DrawHandleTypeMissed, 0, 0);
    }
    if ([dict objectForKey:@"handle"]) {
        return DrawHandleMake(DrawHandleTypeFromString(dict[@"handle"]), 0, 0);
    }
    return DrawHandleMake(DrawHandleTypeIndexed, [dict[@"elementIndex"] integerValue], [dict[@"subindex"] integerValue]);

}

inline BOOL DrawHandleIsBase(DrawHandle handle) {
    return handle.type != DrawHandleTypeMissed && handle.type != DrawHandleTypeIndexed;
}

NSString *DrawStringFromDrawAspectPriority(DrawAspectPriority priority) {
    return [DrawGraphic priorityNames][priority];
}

DrawAspectPriority DrawAspectPriorityFromString(NSString *string) {
    DrawAspectPriority priority = DrawAspectPriorityBackground;
    NSArray<NSString *> *names = [[DrawGraphic class] priorityNames];

    for (NSInteger x = 0; x < (const NSInteger)[names count]; x++) {
        if ([names[x] caseInsensitiveCompare:string] == NSOrderedSame) {
            priority = x;
            break;
        }
    }

    return priority;
}
