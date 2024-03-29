/*
 DrawPenTool.m
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

#import "DrawPenTool.h"

#import "DrawPage.h"
#import "DrawPen.h"
#import "DrawPenBezierAspect.h"
#import "DrawDocument.h"
#import <Draw/Draw-Swift.h>

#import <AJRFoundation/AJRFoundation.h>
#import <AJRInterface/AJRInterface.h>
#import <Draw/DrawToolAction.h>
#import <Draw/DrawGraphicsToolSet.h>
#import <Draw/DrawToolSet.h>

@implementation DrawPenTool {
    DrawHandle _handle;
}

#pragma mark - DrawTool

- (DrawGraphic *)graphicWithPoint:(NSPoint)point document:(DrawDocument *)document page:(DrawPage *)page {
    DrawGraphic *graphic = [[DrawPen alloc] initWithFrame:(NSRect){point, {0.0, 0.0}}];
    [graphic takeAspectsFromGraphic:[document templateGraphic]];
    return graphic;
}

- (DrawPenTag)tag {
    return (DrawPenTag)[[self currentAction] tag];
}

- (void)toolDidActivateForDocument:(DrawDocument *)document {
    [super toolDidActivateForDocument:document];
    if (self.graphic) {
        [self.graphic setEditing:NO];
        [(DrawPen *)self.graphic setCreating:NO];
        self.graphic = nil;
    }
}

#pragma mark - DrawTool / Events

- (void)setGraphic:(DrawGraphic *)graphic {
    [super setGraphic:graphic];
}

- (BOOL)mouseDown:(DrawEvent *)event {
    if (![self waitForMouseDrag:event]) return NO;
    if ([event layerIsLockedOrNotVisible]) return NO;

    if (self.graphic) {
        if ([self.graphic page] == [event page]) {
            NSPoint point = [[event document] snapPointToGrid:[event locationOnPage]];

            if ([event modifierFlags] & NSEventModifierFlagControl) {
                [(DrawPen *)self.graphic appendMoveToPoint:point];
                _handle.type = DrawHandleTypeIndexed;
                _handle.elementIndex += [(DrawPen *)self.graphic closed] ? 2 : 1;
            } else {
                [(DrawPen *)self.graphic appendLineToPoint:point];
                _handle.type = DrawHandleTypeIndexed;
                _handle.elementIndex++;
            }
            [self.graphic trackMouse:event fromHandle:_handle];
        } else {
            [self.graphic setEditing:NO];
            self.graphic = nil;
        }
    } else {
        self.graphic = [self graphicWithPoint:[event locationOnPageSnappedToGrid] document:[event document] page:[event page]];

        if ([self tag] == DrawPenTagClosed) {
            [(DrawPen *)self.graphic setClosed:YES];
        }

        [[event page] addGraphic:self.graphic select:YES byExtendingSelection:NO];

        _handle.type = DrawHandleTypeIndexed;
        _handle.elementIndex = 1;
        _handle.subindex = 0;
        [self.graphic setEditing:YES];
        [(DrawPen *)self.graphic setCreating:YES];
        [self.graphic trackMouse:event fromHandle:_handle];

        if ([self tag] == DrawPenTagLine) {
            [self.graphic setEditing:NO];
            self.graphic = nil;
        }
    }

    return YES;
}

- (NSMenu *)menuForEvent:(DrawEvent *)event {
    NSMenu *menu = nil;

    if ([[[event document] selection] count]) {
        NSMenuItem  *menuItem;

        menu = [[NSMenu alloc] initWithTitle:@"Pen"];
        menuItem = [menu addItemWithTitle:@"Convert to Pen" action:@selector(convertToPen:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:event];
        menuItem = [menu addItemWithTitle:@"Add" action:@selector(unionPens:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:event];
        menuItem = [menu addItemWithTitle:@"Subtract" action:@selector(differencePens:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:event];
        menuItem = [menu addItemWithTitle:@"Intersect" action:@selector(intersectPens:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:event];
        menuItem = [menu addItemWithTitle:@"Exclusively Intersect" action:@selector(exclusivelyIntersectPens:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:event];
    }

    return menu;
}

#pragma mark - Actions

- (void)convertToPen:(NSMenuItem *)sender {
    DrawEvent *event = [sender representedObject];
    DrawDocument *document = [event document];
    NSSet *selection = [document selection];
    DrawGraphic *newGraphic;
    NSArray *subgraphics;

    for (DrawGraphic *oldGraphic in [selection copy]) {
        // Don't convert pens to pens.
        if (![oldGraphic isKindOfClass:[DrawPen class]]) {
            newGraphic = [[DrawPen alloc] initWithFrame:[oldGraphic frame] path:[oldGraphic path]];
            [newGraphic takeAspectsFromGraphic:oldGraphic];
            [newGraphic addAspect:[[DrawPenBezierAspect alloc] initWithGraphic:newGraphic] withPriority:DrawAspectPriorityAfterForeground];
            [document replaceGraphic:oldGraphic withGraphic:newGraphic];
            subgraphics = [oldGraphic subgraphics];
            while ([subgraphics count]) {
                [newGraphic addSubgraphic:[subgraphics objectAtIndex:0]];
            }
        }
    }
}

- (void)_csgWithSelector:(SEL)selector inDocument:(DrawDocument *)document {
    NSArray *selection = [document sortedSelection];
    AJRBezierPath *result = nil, *last = nil, *current;
    DrawPen *newGraphic;
    
    if ([selection count] < 2) {
        NSBeep();
        return;
    }
    
    last = [(DrawGraphic *)[selection objectAtIndex:0] path];
    for (DrawGraphic *graphic in selection) {
        if (last == nil) {
            last = [graphic path];
        } else {
            current = [graphic path];
            result = [last ajr_performSelector:selector withObject:current];
            last = current;
        }
    }
    
    newGraphic = [[DrawPen alloc] initWithFrame:[result controlPointBounds] path:result];
    [[document page] addGraphic:newGraphic select:YES byExtendingSelection:NO];
}

- (void)unionPens:(id)sender {
    [self _csgWithSelector:@selector(pathByUnioningWithPath:) inDocument:[[sender representedObject] document]];
}

- (void)differencePens:(id)sender {
    [self _csgWithSelector:@selector(pathBySubtractingPath:) inDocument:[[sender representedObject] document]];
}

- (void)intersectPens:(id)sender {
    [self _csgWithSelector:@selector(pathByIntersectingWithPath:) inDocument:[[sender representedObject] document]];
}

- (void)exclusivelyIntersectPens:(id)sender {
    [self _csgWithSelector:@selector(pathByExclusivelyIntersectingPath:) inDocument:[[sender representedObject] document]];
}

#pragma mark NSMenuValidation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    DrawEvent *event = [menuItem  representedObject];
    NSSet *selection = [[event document] selection];

    if ([menuItem action] == @selector(convertToPen:)) {
        if ([selection count]) return YES;
    } else if ([selection count] >= 2) {
        return YES;
    }

    return NO;
}

@end
