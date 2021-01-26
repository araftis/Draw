/* DrawInspector.h created by alex on Sun 11-Oct-1998 */

@class DrawInspectorModule, ASObjectBroker;

#import <ASInterface/ASInterface.h>

extern NSString *DrawInspectorOrderKey;

@interface DrawInspector : ASInspector
{
}

+ (id)sharedInstance;
- (void)showDrawInspectorPanel:(id)sender;

@end
