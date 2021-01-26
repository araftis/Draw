/* DrawInspectorModule.h created by alex on Fri 16-Oct-1998 */

#import "DrawGraphic.h"

#import <ASInterface/ASInterface.h>

@interface DrawInspectorModule : ASInspectorModule
{
}

- (NSPrintInfo *)printInfo;
- (NSArray *)selection;

- (void)performInvocation:(NSInvocation *)invocation;

@end
