/*
 DrawSelectionTool.m
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

#import "DrawSelectionTool.h"

#import "DrawDocument.h"
#import "DrawEvent.h"
#import "DrawFunctions.h"
#import "DrawGraphic.h"
#import "DrawGraphicsToolSet.h"
#import "DrawLayer.h"
#import "DrawPage.h"
#import "DrawSelectionActions.h"
#import "DrawToolAction.h"
#import "DrawToolSet.h"

#import <AJRFoundation/AJRFoundation.h>
#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>
#import <AJRInterface/AJRInterface.h>

static NSString * const DrawHitGraphicsCountKey = @"hitGraphicsCount";

static NSMutableDictionary *registeredDraggers = nil;

@implementation DrawSelectionTool {
    NSMutableArray *_hitGraphics;
    NSPoint _lastMouseLocation;

    NSRect _selectionBounds; // This does double duty. If we have "selected" graphics, as found during a mouse down, this will be the bounds of those graphics. Otherwise this represents the "dragged" out selection.

    DrawEvent *_mouseDown;
    DrawDrawingToken _selectionDrawerToken;
    NSTimer *_selectionAnimator;
    CGFloat _animationOffset;

    BOOL _hasDragged;
    BOOL _draggingGraphcis;
    BOOL _shortCircuitedMouseDown;
}

+ (void)initialize {
    registeredDraggers = [[NSMutableDictionary alloc] init];
}

#pragma mark - DrawTool

- (NSNumber *)keyForDrawView:(DrawDocument *)document {
    return [NSNumber numberWithUnsignedLong:(unsigned long)document];
}

- (id)initWithToolSet:(DrawToolSet *)toolSet {
    if ((self = [super initWithToolSet:toolSet])) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(drawViewDidAddGraphic:) name:DrawDocumentDidAddGraphicNotification object:nil];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - DrawTool Activation

- (void)computeSelectionBoundsForSelection:(NSSet *)selection {
    if ([selection count]) {
        BOOL first = YES;

        for (DrawGraphic *graphic in selection) {
            if (first) {
                _selectionBounds = [graphic dirtyBoundsWithRelatedObjects];
                first = NO;
            } else {
                _selectionBounds = NSUnionRect(_selectionBounds, [graphic dirtyBoundsWithRelatedObjects]);
            }
        }
    } else {
        _selectionBounds = NSZeroRect;
    }
}

- (NSCursor *)cursor {
    return [NSCursor arrowCursor];
}

- (BOOL)mouseDown:(DrawEvent *)event {
    DrawDocument *document = [event document];
    DrawPage *page = [event page];
    NSArray *selection = [document sortedSelection];
    NSArray *layers;
    NSInteger x, y;
    DrawLayer *layer;
    NSArray *graphics;
    DrawGraphic *graphic;
    DrawHandle hitLocation;
    DrawGraphic *group = [document focusedGroup];
    CGFloat adjustment = [page error];

    if ([page makeSelectionPerformSelector:@selector(mouseDown:) withObject:event shortCircuit:YES]) {
        _shortCircuitedMouseDown = YES;
        return YES;
    }
    _shortCircuitedMouseDown = NO;
    _draggingGraphcis = NO; // This gets set to yes if the mouse down hits a graphic.

    _mouseDown = event;

    layers = [document layers];

    _lastMouseLocation = [event locationOnPage];

    // First, we need to loop and see if we hit any of the current selection's handles.
    for (x = 0; x < (const NSInteger)[selection count]; x++) {
        graphic = [selection objectAtIndex:x];
        if (NSPointInRect(_lastMouseLocation, NSInsetRect(graphic.bounds, -adjustment, -adjustment)) && (group == graphic.supergraphic)) {
            hitLocation = [graphic handleForPoint:_lastMouseLocation];
            AJRPrintf(@"hit: %@: %@\n", graphic, DrawStringFromHandle(hitLocation));
            // This means that we hit a handle of a selected graphic. In this event, we're just going to track it in a manner similar to having just created the graphic.
            if ((hitLocation.type != DrawHandleTypeMissed) && (hitLocation.type != DrawHandleTypeCenter)) {
                [graphic trackMouse:event fromHandle:hitLocation];
                return YES;
            }
        }
    }

    // Now, let's see if the focused Group's handles were hit.
    if (group) {
        hitLocation = [group handleForPoint:_lastMouseLocation];
        if ((hitLocation.elementIndex > DrawHandleTypeMissed) && (hitLocation.elementIndex != DrawHandleTypeCenter)) {
            [group trackMouse:event fromHandle:hitLocation];
            return YES;
        }
    }

    // This prehaps isn't the most efficient method, but we're going to create an array of all the graphic underneath the mouse down. This will allow us to process the current selection in a fairly complex way. See below for details.
    _hitGraphics = [NSMutableArray array];

    // If we're drilled into a group, then we want to examine that group only.
    if (group) {
        graphics = [group graphicsHitByPoint:_lastMouseLocation];
        if ([graphics count]) {
            [_hitGraphics addObjectsFromArray:graphics];
        }
    } else {
        for (x = [layers count] - 1; x >= 0; x--) {
            layer = [layers objectAtIndex:x];
            if (![layer locked] && [layer visible]) {
                graphics = [page graphicsForLayer:layer];
                for (y = [graphics count] - 1; y >= 0; y--) {
                    graphic = [graphics objectAtIndex:y];
                    if (NSPointInRect(_lastMouseLocation, NSInsetRect([graphic bounds], -adjustment, -adjustment))) {
                        [_hitGraphics addObjectsFromArray:[graphic graphicsHitByPoint:_lastMouseLocation]];
                    }
                }
            }
        }
    }

    _lastMouseLocation = [document snapPointToGrid:_lastMouseLocation];
    _hasDragged = NO;
    _draggingGraphcis = [_hitGraphics count] != 0;
    if (!_draggingGraphcis) {
        __weak DrawSelectionTool *weakSelf = self;
        _selectionDrawerToken = [[_mouseDown page] addGuestDrawer:^(DrawPage * _Nonnull page, NSRect dirtyRect) {
            DrawSelectionTool *strongSelf = weakSelf;
            if (strongSelf != nil) {
                NSRect rect = [page backingAlignedRect:strongSelf->_selectionBounds options:NSAlignAllEdgesNearest];
                AJRBezierPath *path = [AJRBezierPath bezierPathWithRect:rect];
                path.lineWidth = 2.0 / page.scale;
                CGFloat dashes[] = { 3.0, 3.0 };
                [path setLineDash:dashes count:AJRCountOf(dashes) phase:strongSelf->_animationOffset];
                [NSColor.blackColor set];
                [path stroke];
            }
        }];
        _animationOffset = 0.0;
        _selectionAnimator = [NSTimer scheduledTimerWithTimeInterval:0.25 repeats:YES block:^(NSTimer * _Nonnull timer) {
            DrawSelectionTool *strongSelf = weakSelf;
            if (strongSelf != nil) {
                strongSelf->_animationOffset += 1.0;
                if (strongSelf->_animationOffset > 5.0) {
                    strongSelf->_animationOffset = 0.0;
                }
                [strongSelf->_mouseDown.page setNeedsDisplayInRect:NSInsetRect(strongSelf->_selectionBounds, -2.0, -2.0)];
            }
        }];
    }

    return YES;
}

- (BOOL)mouseDraggedWithGraphics:(DrawEvent *)event {
    DrawDocument *document = [event document];
    DrawPage *page = [event page];
    NSPoint point = [event locationOnPage];
    NSPoint delta;
    NSPoint origin;
    NSArray *selection = [document sortedSelection];
    NSInteger x;
    DrawGraphic *hitGraphic = nil;
    BOOL isFirstDrag = NO;

    // First we need to see if there's any overlap between our selection and hitGraphics. If there is, then we just drag. Otherwise we add the top graphic to selection and drag it. We only do this the first time.
    if (!_hasDragged) {
        _hasDragged = YES;

        // First, and easy check. If [selection count] == 0, we have nothing selected, so just add the top graphic.
        if ([selection count] == 0) {
            hitGraphic = [_hitGraphics objectAtIndex:0];
            [document addGraphicToSelection:hitGraphic];
            [self computeSelectionBoundsForSelection:[document selection]];
        } else {
            // Nope, we're going to have to do this the hard way. First, let's see if we have any overlap.
            for (x = 0; x < (const NSInteger)[selection count]; x++) {
                hitGraphic = [selection objectAtIndex:x];
                if ([_hitGraphics indexOfObjectIdenticalTo:hitGraphic] != NSNotFound) {
                    break;
                }
            }
            // If we don't have overlap, then we'll basically do what we did above. Add the top hitGraphic to selection and drag it.
            if (x == [selection count]) {
                // This only happens if we didn't find anything above.
                hitGraphic = [_hitGraphics objectAtIndex:0];
                // However replace selection if the shift key isn't held, otherwise add.
                if (!([event modifierFlags] & NSEventModifierFlagShift)) {
                    // It's safe to remove everything, because none of our hit graphics are in the selection.
                    [document clearSelection];
                }
                [document addGraphicToSelection:hitGraphic];
            }

            // Finally, in either case, compute the bounds we're working with...
            [self computeSelectionBoundsForSelection:[document selection]];
        }

        // Note that this is the first time we've ever dragged.
        isFirstDrag = YES;
    }

    if (isFirstDrag) {
        NSUInteger mask;
        NSNumber *maskKey;
        NSEnumerator *enumerator;

        mask = [event modifierFlags] & (NSEventModifierFlagShift | NSEventModifierFlagControl | NSEventModifierFlagOption | NSEventModifierFlagCommand | NSEventModifierFlagHelp);

        enumerator = [registeredDraggers keyEnumerator];
        while ((maskKey = [enumerator nextObject])) {
            if ([maskKey intValue] == mask) {
                if ([[registeredDraggers objectForKey:maskKey] dragSelection:selection withLastHitGraphic:hitGraphic fromEvent:_mouseDown]) {
                    return YES;
                }
            }
        }

        // Now that we've done whatever is necessary to our selection, if the shift key is held down, drag it.
        if ([event modifierFlags] & NSEventModifierFlagShift) {
            [page.document dragSelection:selection withLastHitGraphic:hitGraphic fromEvent:event];
            return YES;
        }
    }

    point = [document snapPointToGrid:point];
    delta.x = point.x - _lastMouseLocation.x;
    delta.y = point.y - _lastMouseLocation.y;

    // This check may seem a little odd, but will happen when the view is contrained to a grid, since this could cause multiple mouse drags, but no actual movement of our point.
    if (!((delta.x == 0.0) && (delta.y == 0.0))) {
        // First, erase the old graphics.
        [page setNeedsDisplayInRect:_selectionBounds];

        for (x = 0; x < (const NSInteger)[selection count]; x++) {
            hitGraphic = [selection objectAtIndex:x];
            if (isFirstDrag) {
                //[(NSView *)[document prepareWithInvocationTarget:aGraphic] setFrame:[aGraphic frame]];
            }
            origin = [hitGraphic frame].origin;
            origin.x += delta.x;
            origin.y += delta.y;
            [hitGraphic setFrameOrigin:origin];
        }

        _selectionBounds.origin.x += delta.x;
        _selectionBounds.origin.y += delta.y;

        [page setNeedsDisplayInRect:_selectionBounds];
    }

    _lastMouseLocation = point;

    return YES;
}

- (BOOL)mouseDraggedWithoutGraphics:(DrawEvent *)event {
    NSPoint firstPoint = [_mouseDown locationOnPage];
    NSPoint currentPoint = [event locationOnPage];

    if (!NSEqualRects(NSZeroRect, _selectionBounds)) {
        [_mouseDown.page setNeedsDisplayInRect:NSInsetRect(_selectionBounds, -2.0, -2.0)];
    }

    _selectionBounds.origin = firstPoint;
    _selectionBounds.size.width = currentPoint.x - firstPoint.x;
    _selectionBounds.size.height = currentPoint.y - firstPoint.y;
    _selectionBounds = AJRNormalizeRect(_selectionBounds);

    [_mouseDown.page setNeedsDisplayInRect:_selectionBounds];

    [self setSelection:[_mouseDown.page graphicsHitByRect:_selectionBounds]];

    _hasDragged = YES;

    return YES;
}

- (BOOL)mouseDragged:(DrawEvent *)event {
    BOOL result = NO;

    if (_shortCircuitedMouseDown) {
        return YES;
    }

    if (_draggingGraphcis) {
        result = [self mouseDraggedWithGraphics:event];
    } else {
        result = [self mouseDraggedWithoutGraphics:event];
    }

    return result;
}

- (void)modifyNoCountSelection:(NSArray *)selection event:(DrawEvent *)event {
    DrawGraphic *graphic;

    graphic = [_hitGraphics objectAtIndex:0];
    [[event document] addGraphicToSelection:graphic];
}

- (void)modifySingleHitSelection:(NSArray *)selection event:(DrawEvent *)event {
    NSUInteger index;
    DrawGraphic *graphic;
    DrawDocument *document = [event document];

    graphic = [_hitGraphics objectAtIndex:0];
    // We'll this isn't completely simple, since we have to deal with the shift key, but it's still a lot easier than the next case.
    if ([event modifierFlags] & NSEventModifierFlagShift) {
        if ((index = [selection indexOfObjectIdenticalTo:graphic]) == NSNotFound) {
            [document addGraphicToSelection:graphic];
        } else {
            [document removeGraphicFromSelection:graphic];
        }
    } else {
        [document clearSelection];
        [document addGraphicToSelection:graphic];
    }
}

- (void)modifySelection:(NSArray<DrawGraphic *> *)selection event:(DrawEvent *)event {
    NSUInteger index;
    DrawGraphic *graphic;
    NSInteger lastHitGraphicsCount = [[[event document] instanceObjectForKey:DrawHitGraphicsCountKey] intValue];
    DrawDocument *document = [event document];

    if ([event modifierFlags] & NSEventModifierFlagShift) {
        NSInteger x;

        for (x = 0; x < (const NSInteger)[_hitGraphics count]; x++) {
            graphic = [_hitGraphics objectAtIndex:x];
            index = [selection indexOfObjectIdenticalTo:graphic];
            if (index == NSNotFound) {
                [document addGraphicToSelection:graphic];
                break;
            }
        }
    } else {
        if (lastHitGraphicsCount != [_hitGraphics count]) {
            index = 0;
        } else {
            if ([selection count] == 1) {
                graphic = [selection objectAtIndex:0];
                index = [_hitGraphics indexOfObjectIdenticalTo:graphic];

                if (index == NSNotFound) index = 0;
                else index++;
                if (index == [_hitGraphics count]) index = 0;

            } else {
                index = 0;
            }
        }

        [[event document] clearSelection];

        graphic = [_hitGraphics objectAtIndex:index];
        [document addGraphicToSelection:graphic];
    }
}

- (void)setSelection:(NSArray<DrawGraphic *> *)newSelection {
    // We're going to do a bit of brute forcing. If this proves an issue, we can optimize the searches in the arrays.
    DrawDocument *document = _mouseDown.document;

    if (document == nil) {
        AJRLogWarning(@"%s only works during a drag event loop.", __FUNCTION__);
    } else {
        NSMutableArray<DrawGraphic *> *notInNewSelection = [NSMutableArray array];
        NSSet<DrawGraphic *> *currentSelection = document.selection;

        for (DrawGraphic *graphic in currentSelection) {
            if (![newSelection containsObjectIdenticalTo:graphic]) {
                [notInNewSelection addObject:graphic];
            }
        }
        for (DrawGraphic *graphic in notInNewSelection) {
            [document removeGraphicFromSelection:graphic];
        }
        [document addGraphicsToSelection:newSelection];
    }
}

- (BOOL)mouseUp:(DrawEvent *)event {
    DrawDocument *document = [event document];
    NSArray *selection = [document sortedSelection];

    if (_shortCircuitedMouseDown) {
        return YES;
    }

    if (_selectionDrawerToken != 0) {
        [_mouseDown.page removeGuestDrawer:_selectionDrawerToken];
        _selectionDrawerToken = 0;
        [_mouseDown.page setNeedsDisplayInRect:NSInsetRect(_selectionBounds, -1.0, -1.0)];
    }

    [_selectionAnimator invalidate];
    _selectionAnimator = nil;
    _mouseDown = nil;
    _selectionBounds = NSZeroRect;

    if (_hasDragged) {
        _hasDragged = NO;
    } else {
        // Let's see if we double clicked.
        if ([event clickCount] > 1) {
            NSInteger x;
            DrawGraphic *aGraphic;
            BOOL aspectsCanEdit;

            aspectsCanEdit = ([event modifierFlags] & NSEventModifierFlagOption) == 0;

            for (x = 0; x < (const NSInteger)[selection count]; x++) {
                aGraphic = [selection objectAtIndex:x];
                if (aspectsCanEdit) {
                    if (![aGraphic beginAspectEditingFromEvent:event]) {
                        [aGraphic setEditing:YES];
                    }
                } else {
                    [aGraphic setEditing:YES];
                }
            }
        } else {
            // This is the easy case. If they just clicked the background, undo the selection.
            if ([_hitGraphics count] == 0) {
                DrawGraphic *group = [document focusedGroup];

                if (group) {
                    [document clearSelection];
                    if (![[group path] isHitByPoint:_lastMouseLocation]) {
                        [document unfocusGroup];
                    }
                } else {
                    [document clearSelection];
                }
            } else {
                if ([selection count] == 0) {
                    // First, easy case one. Here, if the [selection count] == 0, we don't have a selection, we already know from above that we have a hit object, so just make the top most hit object the selection.
                    [self modifyNoCountSelection:selection event:event];
                } else if ([_hitGraphics count] == 1) {
                    // This is the second easy case. In this event, we just update the current selection based on the only object we found.
                    [self modifySingleHitSelection:selection event:event];
                } else {
                    // Thus, this becomes the complicated case. This is complicated, because as hits occur, we'll cycle through them. This allows us to selection single images out of stacked graphics.
                    [self modifySelection:selection event:event];
                }
            }
        }
    }

    [document setInstanceObject:@(_hitGraphics.count) forKey:DrawHitGraphicsCountKey];

    _hitGraphics = nil;

    return YES;
}

- (BOOL)keyDown:(DrawEvent *)event {
    NSString *characters = [event characters];
    unichar character = [characters length] ? [characters characterAtIndex:0] : 0;

    switch (character) {
        case UNICODE_DELETE:
        case UNICODE_DELETE_BACK:
            [[event document] deleteSelection];
            return YES;
        case NSPageUpFunctionKey:
            [[event document] moveSelectionUp];
            break;
        case NSPageDownFunctionKey:
            [[event document] moveSelectionDown];
            break;
        case NSHomeFunctionKey:
            [[event document] moveSelectionToTop];
            break;
        case NSEndFunctionKey:
            [[event document] moveSelectionToBottom];
            break;
        default:
            break;
    }
    return NO;
}

- (NSMenu *)menuForEvent:(DrawEvent *)event {
    NSMenu *menu = nil;

    if ([[[event document] selection] count]) {
        NSMenuItem *menuItem;
        DrawSelectionActions *selectionActions = [DrawSelectionActions sharedInstance];

        menu = [[NSMenu alloc] initWithTitle:@"Shape"];
        menuItem = [menu addItemWithTitle:@"Flip Vertical" action:@selector(flipVertical:) keyEquivalent:@""];
        [menuItem setTarget:selectionActions];
        menuItem = [menu addItemWithTitle:@"Flip Horizontal" action:@selector(flipHorizontal:) keyEquivalent:@""];
        [menuItem setTarget:selectionActions];
        menuItem = [menu addItemWithTitle:@"Make Square" action:@selector(makeSquare:) keyEquivalent:@""];
        [menuItem setTarget:selectionActions];
        menuItem = [menu addItemWithTitle:@"Snap to Grid" action:@selector(snapToGrid:) keyEquivalent:@""];
        [menuItem setTarget:selectionActions];
    }

    return menu;
}

#pragma mark - Notifications

- (void)drawViewDidAddGraphic:(NSNotification *)notification {
}

+ (void)registerObject:(id <DrawSelectionDragger>)aTool forDragWithModifierMask:(NSUInteger)mask {
    NSNumber *key = [NSNumber numberWithUnsignedInteger:mask];
    DrawTool *oldTool;

    oldTool = [registeredDraggers objectForKey:key];
    if (oldTool) {
        AJRPrintf(@"WARNING: %@ had already registered for mask: 0x%x\n", [oldTool class], mask);
    }

    [registeredDraggers setObject:aTool forKey:key];
}

#pragma mark - DrawTool / Activation

- (BOOL)toolShouldActivateForDocument:(DrawDocument *)document {
    [[DrawSelectionActions sharedInstance] activate];
    return YES;
}

- (BOOL)toolShouldDeactivateForDocument:(DrawDocument *)document {
    [[DrawSelectionActions sharedInstance] deactivate];
    return YES;
}

@end
