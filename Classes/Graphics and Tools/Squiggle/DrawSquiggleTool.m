
#import "DrawSquiggleTool.h"

#import "DrawDocument.h"
#import "DrawEvent.h"
#import "DrawGraphicsToolSet.h"
#import "DrawPathAnalysisAspect.h"
#import "DrawPage.h"
#import "DrawSquiggle.h"
#import "DrawToolAction.h"
#import "DrawToolSet.h"

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
