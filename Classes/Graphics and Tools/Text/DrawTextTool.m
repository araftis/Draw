/* DrawTextTool.m created by alex on Thu 08-Oct-1998 */

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
