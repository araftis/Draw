/* DrawRectangleTool.m created by alex on Thu 08-Oct-1998 */

#import "DrawRectangleTool.h"

#import "DrawDocument.h"
#import "DrawGraphicsToolSet.h"
#import "DrawRectangle.h"
#import "DrawToolAction.h"
#import "DrawToolSet.h"

#import <AJRInterface/AJRImages.h>

@implementation DrawRectangleTool

#pragma mark - DrawTool

- (DrawGraphic *)graphicWithPoint:(NSPoint)point document:(DrawDocument *)document page:(DrawPage *)page {
    DrawRectangle *graphic = nil;

    switch (self.currentAction.tag) {
        case 0:
            graphic = [[DrawRectangle alloc] initWithFrame:(NSRect){point, {0.0, 0.0}}];
            break;
        case 1:
            graphic = [[DrawRectangle alloc] initWithFrame:(NSRect){point, {0.0, 0.0}}];
            [graphic setRadius:[[NSUserDefaults standardUserDefaults] floatForKey:DrawRectangleRadiusKey]];
            break;
        case 2:
            graphic = [[DrawRectangle alloc] initWithFrame:(NSRect){point, {0.0, 0.0}}];
            [graphic setRadius:MAXFLOAT];
            break;
    }

    [graphic takeAspectsFromGraphic:[document templateGraphic]];

    return graphic;
}

@end
