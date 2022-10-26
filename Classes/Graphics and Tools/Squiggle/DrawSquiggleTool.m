/*
DrawSquiggleTool.m
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

#import "DrawSquiggleTool.h"

#import "DrawDocument.h"
#import "DrawEvent.h"
#import "DrawGraphicsToolSet.h"
#import "DrawPage.h"
#import "DrawSquiggle.h"
#import "DrawToolAction.h"
#import "DrawToolSet.h"
#import <Draw/Draw-Swift.h>

#import <AJRFoundation/AJRFoundation.h>
#import <AJRInterface/AJRInterface.h>
#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

@implementation DrawSquiggleTool {
    DrawHandle _handle;
}

#pragma mark - DrawTool

- (DrawSquiggleTag)tag {
    return (DrawSquiggleTag)[[self currentAction] tag];
}

- (DrawGraphic *)graphicWithPoint:(NSPoint)point document:(DrawDocument *)document page:(DrawPage *)page {
    DrawGraphic  *graphic = [[DrawSquiggle alloc] initWithFrame:(NSRect){point, {0.0, 0.0}}];
    [graphic takeAspectsFromGraphic:[document templateGraphic]];
    return graphic;
}

- (BOOL)mouseDown:(DrawEvent *)event {
    if (![self waitForMouseDrag:event]) return NO;
    if ([event layerIsLockedOrNotVisible]) return NO;

    self.graphic = [self graphicWithPoint:[event locationOnPageSnappedToGrid] document:[event document] page:[event page]];

    if (([self tag] == DrawSquiggleTagClosed) || ([self tag] == DrawSquiggleTagSmart)) {
        [(DrawSquiggle *)self.graphic setClosed:YES];
    }

    [[event page] addGraphic:self.graphic select:YES byExtendingSelection:NO];

    _handle.type = DrawHandleTypeIndexed;
    _handle.elementIndex = 0;
    [self.graphic setEditing:YES];
    [(DrawSquiggle *)self.graphic setCreating:YES];
    [self.graphic trackMouse:event fromHandle:_handle];
    [(DrawSquiggle *)self.graphic setCreating:NO];
    [self.graphic setEditing:NO];

    [self.graphic addAspect:[[DrawPathAnalysisAspect alloc] initWithGraphic:self.graphic] withPriority:DrawAspectPriorityLast];

    return YES;
}

@end
