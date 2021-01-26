/* DrawInspector.m created by alex on Sun 11-Oct-1998 */

#import "DrawInspector.h"

#import "DrawInspectorModule.h"
#import "DrawDocument.h"

#import <ASFoundation/ASFoundation.h>
#import <ASInterface/ASInterface.h>

static DrawInspector *SELF = nil;

NSString *DrawInspectorOrderKey = @"DrawInspectorOrderKey";

@implementation DrawInspector

+ (id)allocWithZone:(NSZone *)zone
{
    if (!SELF) SELF = [super allocWithZone:zone];
    return SELF;
}

- (id)init
{
    if (!window) {
        [super init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(drawViewDidChangeSelection:) name:DrawViewDidChangeSelectionNotification object:nil];
    }
    
    return self;
}

+ (id)sharedInstance
{
    return [[self alloc] init];
}

- (Class)inspectorClass
{
    return [DrawInspectorModule class];
}

- (void)showDrawInspectorPanel:(id)sender
{
    [inspector update];
    [window makeKeyAndOrderFront:sender];
}

- (void)drawViewDidChangeSelection:(NSNotification *)notification
{
#warning Implement
//    if ([notification object] == [[DrawController sharedInstance] currentView]) {
//        [inspector update];
//    }
}

@end


@implementation NSResponder (DrawInspectorControll)

- (void)showDrawInspectorPanel:(id)sender
{
    [[DrawInspector sharedInstance] showDrawInspectorPanel:sender];
}

@end
