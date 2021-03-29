/*
DrawTextTool.m
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

#import "DrawTextTool.h"

#import "DrawDocument.h"
#import "DrawEvent.h"
#import "DrawFormEntry.h"
#import "DrawGraphicsToolSet.h"
#import "DrawPage.h"
#import "DrawRectangle.h"
#import "DrawText.h"
#import "DrawToolAction.h"

#import <AJRInterface/AJRInterface.h>

NSString * const DrawTextToolIdentifier = @"text";

@implementation DrawTextTool

#pragma mark - DrawTool

- (DrawTextTag)tag {
    return (DrawTextTag)[[self currentAction] tag];
}

- (DrawGraphic *)graphicWithPoint:(NSPoint)point document:(DrawDocument *)document page:(DrawPage *)page {
    DrawRectangle *aGraphic = nil;
    DrawText *text;
    NSFont *selectedFont = [[NSFontManager sharedFontManager] selectedFont];
    NSSize size;

    size = [selectedFont boundingRectForFont].size;
    size.width *= 2.0;
    size.height *= 2.0;

    aGraphic = [[DrawRectangle alloc] initWithFrame:(NSRect){point, size}];

    switch ([self tag]) {
        case DrawTextTagText:
            text = [[DrawText alloc] initWithGraphic:aGraphic];
            break;
        case DrawTextTagFormEntry:
            text = [[DrawFormEntry alloc] initWithGraphic:aGraphic];
            break;
        default:
            text = [[DrawText alloc] initWithGraphic:aGraphic];
            break;
    }

    [aGraphic takeAspectsFromGraphic:[document templateGraphic]];
    [aGraphic addAspect:text withPriority:DrawAspectPriorityAfterBackground];

    [text setAttributedString:[[NSAttributedString alloc] initWithString:@""]];

    return aGraphic;
}

- (BOOL)mouseDown:(DrawEvent *)event {
    if ([event layerIsLockedOrNotVisible]) {
        return NO;
    }

    if (self.graphic) {
        self.graphic = nil;
        return YES;
    }

    self.graphic = [self graphicWithPoint:[event locationOnPageSnappedToGrid] document:[event document] page:[event page]];

    [[event page] addGraphic:self.graphic select:YES byExtendingSelection:NO];

    [self.graphic beginAspectEditingFromEvent:event];

    return YES;
}

- (NSCursor *)cursor {
    return [NSCursor IBeamCursor];
}

- (NSMenu *)menuForEvent:(DrawEvent *)event {
    NSMenu *menu = nil;

    if ([[[event document] selection] count]) {
        NSMenuItem  *menuItem;

        menu = [[NSMenu alloc] initWithTitle:[[self translator] valueForKey:@"Text"]];
        menuItem = [menu addItemWithTitle:[[self translator] valueForKey:@"Add to Graphic"] action:@selector(addTextToGraphics:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:event];
        menuItem = [menu addItemWithTitle:[[self translator] valueForKey:@"Make Form Entry"] action:@selector(makeFormEntry:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:event];
        menuItem = [menu addItemWithTitle:[[self translator] valueForKey:@"Make Plain Text"] action:@selector(makePlainText:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setRepresentedObject:event];
    }

    return menu;
}

#pragma mark Actions

- (void)addTextToGraphics:(id)sender {
    DrawDocument *document = [(DrawEvent *)[sender representedObject] document];
    NSSet *selection = [document selection];
    DrawText *text;

    for (DrawGraphic *graphic in selection) {
        text = [[DrawText alloc] initWithGraphic:graphic];
        [graphic addAspect:text withPriority:DrawAspectPriorityBeforeChildren];
        [text setAttributedString:[[NSAttributedString alloc] initWithString:@"Text"]];
    }
}

- (IBAction)makeFormEntry:(id)sender {
    AJRPrintf(@"%C: %S", self, _cmd);
}

- (IBAction)makePlainText:(id)sender {
    AJRPrintf(@"%C: %S", self, _cmd);
}

#pragma mark NSMenuValidation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    DrawEvent *event = [menuItem  representedObject];
    NSSet *selection = [[event document] selection];

    if ([menuItem action] == @selector(addTextToGraphics:)) {
        return [selection count] != 0;
    } else if ([menuItem action] == @selector(makeFormEntry:)) {
        return [selection count] != 0;
    } else if ([menuItem action] == @selector(makePlainText:)) {
        return [selection count] != 0;
    }

    return NO;
}

@end
