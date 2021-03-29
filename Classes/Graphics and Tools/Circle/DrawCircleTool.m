
#import "DrawCircleTool.h"

#import "DrawCircle.h"
#import "DrawDocument.h"
#import "DrawEvent.h"
#import "DrawGraphicsToolSet.h"
#import "DrawPage.h"
#import "DrawToolAction.h"
#import "DrawToolSet.h"

#import <AJRInterface/AJRImages.h>

typedef NS_ENUM(uint8_t, DrawCircleToolTag) {
    DrawCircleToolTagCircle = 0,
    DrawCircleToolTagWedge = 1,
};

@implementation DrawCircleTool

#pragma mark - DrawTool

- (DrawGraphic *)graphicWithPoint:(NSPoint)point document:(DrawDocument *)document page:(DrawPage *)page {
    DrawCircle	*aGraphic;

    aGraphic = [[DrawCircle alloc] initWithFrame:(NSRect){point, {0.0, 0.0}}];
    [aGraphic takeAspectsFromGraphic:[document templateGraphic]];

    if ([[self currentAction] tag] == DrawCircleToolTagWedge) {
        [aGraphic setStartAngle:0.0];
        [aGraphic setEndAngle:0.0];
    }

    return aGraphic;
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
