/*
 DrawCircleTool.m
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

#import "DrawCircleTool.h"

#import "DrawCircle.h"
#import "DrawDocument.h"
#import "DrawGraphicsToolSet.h"
#import "DrawPage.h"
#import "DrawToolAction.h"
#import "DrawToolSet.h"
#import <Draw/Draw-Swift.h>

#import <AJRInterface/AJRImages.h>

typedef NS_ENUM(uint8_t, DrawCircleToolTag) {
    DrawCircleToolTagCircle = 0,
    DrawCircleToolTagWedge = 1,
};

@implementation DrawCircleTool

#pragma mark - DrawTool

- (DrawGraphic *)graphicWithPoint:(NSPoint)point document:(DrawDocument *)document page:(DrawPage *)page {
    DrawCircle	*newGraphic = [[DrawCircle alloc] initWithFrame:(NSRect){point, {0.0, 0.0}}];

    [newGraphic takeAspectsFromGraphic:document.templateGraphic];

    if ([[self currentAction] tag] == DrawCircleToolTagWedge) {
        [newGraphic setStartAngle:0.0];
        [newGraphic setEndAngle:0.0];
    }

    return newGraphic;
}

- (void)toolDidActivateForDocument:(DrawDocument *)document {
    [super toolDidActivateForDocument:document];
    if (self.graphic) {
        [[self.graphic document] removeGraphic:self.graphic];
        self.graphic = nil;
    }
}

- (BOOL)mouseDown:(DrawEvent *)event {
    if (![self waitForMouseDrag:event]) return NO;
    if ([event layerIsLockedOrNotVisible]) return NO;

    if (self.graphic) {
        if ([self.graphic document] == [event document]) {
            [self.graphic trackMouse:event fromHandle:DrawHandleMake(DrawHandleTypeIndexed, 2, 0)];
            [self.graphic setEditing:NO];
            self.graphic = nil;
        } else {
            [[self.graphic document] removeGraphic:self.graphic];
            self.graphic = nil;
        }
    } else {
        self.graphic = [self graphicWithPoint:[event locationOnPageSnappedToGrid] document:[event document] page:[event page]];

        [[event page] addGraphic:self.graphic select:YES byExtendingSelection:NO];

        switch (self.currentAction.tag) {
            case DrawCircleToolTagCircle:
                [self.graphic trackMouse:event];
                self.graphic = nil;
                break;
            case DrawCircleToolTagWedge:
                [self.graphic setEditing:YES];
                [self.graphic trackMouse:event fromHandle:DrawHandleMake(DrawHandleTypeIndexed, 0, 0)];
                break;
        }
    }

    return YES;
}

@end
