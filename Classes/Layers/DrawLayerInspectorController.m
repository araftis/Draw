
#import "DrawLayerInspectorController.h"

#import <AJRFoundation/NSObject+Extensions.h>

NSString * const DrawInspectorGroupLayers = @"Layers";

NSString * const DrawLayerInspectorControllerID = @"layers";

@implementation DrawLayerInspectorController

#pragma mark - Factory Client

+ (NSString *)identifier {
    return DrawLayerInspectorControllerID;
}

+ (NSString *)name {
    return [[self translator] valueForKey:@"name"];
}

+ (CGFloat)priority {
    return 1.0;
}

@end
