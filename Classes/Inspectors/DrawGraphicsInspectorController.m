
#import "DrawGraphicsInspectorController.h"

#import "DrawInspector.h"
#import "DrawInspectorGroupController.h"

NSString * const DrawInspectorGroupGraphics = @"Graphics";

@implementation DrawGraphicsInspectorController

#pragma mark - Factory

//+ (void)load
//{
//	[DrawInspectorGroupController registerControllerClass:self forName:@"Graphics"];
//}

#pragma mark - DrawInspectorController

- (NSSet *)inspectorClassesForObject:(id)object {
    return [NSSet set]; //[DrawInspectorGroupController inspectorClassesForClass:[object class] forName:DrawInspectorGroupGraphics];
}

@end
