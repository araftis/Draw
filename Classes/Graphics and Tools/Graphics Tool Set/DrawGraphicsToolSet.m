
#import "DrawGraphicsToolSet.h"

#import "DrawDocument.h"

#import <AJRInterface/AJRInterface.h>

DrawToolSetId const DrawToolSetIdGraphics = @"graphics";

@implementation DrawGraphicsToolSet

#pragma mark - DrawToolSet: Document Querries

- (NSSet *)selectionForInspectionForDocument:(DrawDocument *)document {
    return [NSSet setWithObject:[document templateGraphic]];
}

@end
