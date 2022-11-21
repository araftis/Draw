/*
 DrawPage-Event.m
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

#import "DrawPage.h"

#import "DrawGraphic.h"
#import "DrawTool.h"
#import "DrawToolSet.h"
#import "DrawDocument.h"
#import <Draw/Draw-Swift.h>

@implementation DrawPage (Event)

#pragma mark - Utilities

typedef BOOL (*DrawMethod)(id, SEL, id);

- (BOOL)makeSelectionPerformSelector:(SEL)selector withObject:(id)anObject shortCircuit:(BOOL)shortCircuit {
    BOOL handledReturn = NO;
    NSSet *selection = [_document selection];

    for (DrawGraphic *graphic in selection) {
        DrawMethod method = (DrawMethod)AJRGetMethodImplementation(graphic.class, selector);
        if (method != NULL) {
            BOOL handledEvent = method(graphic, selector, anObject);
            if (handledEvent) {
                handledReturn = YES;
                if (shortCircuit) {
                    break;
                }
            }
        }
    }

    return handledReturn;
}

#pragma mark - Left Mouse

- (void)updateTrackingAreas {
    NSArray<NSTrackingArea *> *areas = [self.trackingAreas copy];
    for (NSTrackingArea *area in areas) {
        [self removeTrackingArea:area];
    }

    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow | NSTrackingActiveInActiveApp owner:self userInfo:NULL];
    [self addTrackingArea:area];
}

- (void)mouseDown:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![_document.currentTool mouseDown:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(mouseDown:) withObject:drawEvent shortCircuit:YES];
    } else {
        [[self window] makeFirstResponder:self];
    }
}

- (void)mouseDragged:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] mouseDragged:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(mouseDragged:) withObject:drawEvent shortCircuit:YES];
    }
}

- (void)mouseUp:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] mouseUp:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(mouseUp:) withObject:drawEvent shortCircuit:YES];
    }
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
    return YES;
}

#pragma mark - Mouse Tracking

- (void)mouseMoved:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] mouseMoved:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(mouseMoved:) withObject:drawEvent shortCircuit:YES];
    } else {
        [[self window] makeFirstResponder:self];
    }
}

- (void)mouseEntered:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] mouseEntered:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(mouseEntered:) withObject:drawEvent shortCircuit:YES];
    } else {
        [[self window] makeFirstResponder:self];
    }

    _mouseInPage = YES;
}

- (void)mouseExited:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] mouseExited:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(mouseExited:) withObject:drawEvent  shortCircuit:YES];
    } else {
        [[self window] makeFirstResponder:self];
    }

    _mouseInPage = NO;
}

- (BOOL)mouseInPage {
    return _mouseInPage;
}

#pragma mark - Right Mouse

- (void)rightMouseDown:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] rightMouseDown:drawEvent]) {
        if (![self makeSelectionPerformSelector:@selector(rightMouseDown:) withObject:drawEvent shortCircuit:YES]) {
            [super rightMouseDown:event];
        }
    } else {
        [[self window] makeFirstResponder:self];
    }
}

- (void)rightMouseDragged:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] rightMouseDragged:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(rightMouseDragged:) withObject:drawEvent shortCircuit:YES];
    }
}

- (void)rightMouseUp:(NSEvent *)event  {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] rightMouseUp:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(rightMouseUp:) withObject:drawEvent shortCircuit:YES];
    }
}

#pragma mark - Keyboard

- (DrawTool *)findToolMatchingKeyString:(NSString *)keyString inToolSet:(DrawToolSet *)toolSet {
    DrawTool *found = nil;

    for (DrawTool *tool in [toolSet tools]) {
        if ([keyString isEqualToString:[tool activationKey]]) {
            found = tool;
            break;
        }
    }

    return found;
}

- (DrawToolSet *)findToolSetMatchingKeyString:(NSString *)keyString {
    DrawToolSet *found = nil;

    for (DrawToolSet *toolSet in [DrawToolSet toolSets]) {
        if ([keyString isEqualToString:[toolSet activationKey]]) {
            found = toolSet;
            break;
        }
    }

    return found;
}

- (DrawTool *)findToolMatchingKeyString:(NSString *)keyString {
    DrawTool *tool = [self findToolMatchingKeyString:keyString inToolSet:_document.displayedToolSet];
    if (tool == nil) {
        tool = [self findToolMatchingKeyString:keyString inToolSet:DrawToolSet.globalToolSet];
    }
    return tool;
}

- (void)keyDown:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    [[self window] makeFirstResponder:self];

    if (![[_document currentTool] keyDown:drawEvent]) {
        if (![self makeSelectionPerformSelector:@selector(keyDown:) withObject:drawEvent shortCircuit:NO]) {
            // So none of our tools did anything with the key event, maybe we can.
            DrawTool *tool = [self findToolMatchingKeyString:[event characters]];
            if (tool == nil) {
                DrawToolSet *toolSet = [self findToolSetMatchingKeyString:[event characters]];
                if (toolSet == nil) {
                    NSBeep();
                } else {
                    if (_document.currentToolSet != toolSet) {
                        _document.currentToolSet = toolSet;
                    }
                }
            } else {
                NSArray *actions = [tool actions];
                if ([_document currentTool] == tool && [actions count] > 1) {
                    DrawToolAction *currentAction = [tool currentAction];
                    NSUInteger index = [[tool actions] indexOfObjectIdenticalTo:currentAction];

                    index = (index + 1) % [actions count];

                    [tool setCurrentAction:[[tool actions] objectAtIndex:index]];
                } else {
                    [_document setCurrentTool:tool];
                }
            }
        }
    }
}

- (void)keyUp:(NSEvent *)event  {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] keyUp:drawEvent]) {
        if (![self makeSelectionPerformSelector:@selector(keyUp:) withObject:drawEvent shortCircuit:YES]) {
            [super keyUp:event];
        }
    }
}

- (void)flagsChanged:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] flagsChanged:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(flagsChanged:) withObject:drawEvent shortCircuit:YES];
    }
}

- (void)helpRequested:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] helpRequested:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(helpRequested:) withObject:drawEvent shortCircuit:YES];
    } else {
        [[self window] makeFirstResponder:self];
    }
}

#pragma mark - Menus

- (void)addCopyOfMenu:(NSMenu *)sourceMenu to:(NSMenu *)menu {
    if (sourceMenu && [[sourceMenu itemArray] count]) {
        [menu addItem:[NSMenuItem separatorItem]];
        for (NSMenuItem *item in [sourceMenu itemArray]) {
            NSMenuItem *newItem;

            newItem = [menu addItemWithTitle:[item title] action:[item action] keyEquivalent:[item keyEquivalent]];
            [newItem setTarget:[item target]];
            [newItem setHidden:[item isHidden]];
            [newItem setAlternate:[item isAlternate]];
            [newItem setImage:[item image]];
            [newItem setOnStateImage:[item onStateImage]];
            [newItem setOffStateImage:[item offStateImage]];
            [newItem setMixedStateImage:[item mixedStateImage]];
            [newItem setTag:[item tag]];
            [newItem setState:[item state]];
            [newItem setIndentationLevel:[item indentationLevel]];
            [newItem setToolTip:[item toolTip]];
            [newItem setRepresentedObject:[item representedObject]];
            [newItem setView:[item view]];
        }
    }
}

- (NSMenu *)menuForEvent:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Context Menu"];
    NSMenuItem *item;
    BOOL hasSelection = [[_document selection] count];

    if (hasSelection) {
        item = [menu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@""];
        item = [menu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@""];
    }
    item = [menu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@""];

    for (DrawToolSet *toolSet in DrawToolSet.toolSets) {
        [self addCopyOfMenu:[toolSet menuForEvent:drawEvent] to:menu];
    }
    for (DrawTool *tool in [[_document currentToolSet] tools]) {
        [self addCopyOfMenu:[tool menuForEvent:drawEvent] to:menu];
    }

    return menu;
}

#pragma mark - Dragging

- (BOOL)dragSelection:(NSArray *)selection withLastHitGraphic:(DrawGraphic *)graphic fromEvent:(DrawEvent *)event; {
    return [[graphic document] dragSelection:selection withLastHitGraphic:graphic fromEvent:event];
}

@end
