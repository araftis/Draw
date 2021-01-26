/* DrawInspectorModule.m created by alex on Fri 16-Oct-1998 */

#import "DrawInspectorModule.h"

#import "DrawGraphic.h"
#import "DrawPage.h"
#import "DrawPageLayout.h"
#import "DrawDocument.h"

@implementation DrawInspectorModule

- (id)init
{
   [super init];
   
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateForPrintInfo) name:NSPrintInfoDidUpdateNotification object:nil];

   return self;
}

- (Class)inspectedClass
{
   return [DrawGraphic class];
}

- (BOOL)handlesMultipleSelection
{
   // All our inspectors can handle multiple selection.
	return YES;
}

- (BOOL)handlesEmptySelection
{
   // All modules also handle empty selection, since this just causes them to update defaults, and nothing more.
	return YES;
}

- (void)_updateForPrintInfo
{
   if ([view superview]) {
      [self update];
   }
}

- (NSPrintInfo *)printInfo
{
#warning Implement
//   DrawView		*drawView = [[DrawController sharedInstance] currentView];
//
//   if (drawView) return [drawView printInfo];
//
   return [NSPrintInfo sharedPrintInfo];
}

- (NSArray *)selection
{
#warning Implement
//   return [[[DrawController sharedInstance] currentView] selection];
    return [NSArray array];
}

- (void)performInvocation:(NSInvocation *)invocation
{
   NSInteger			x;
   NSArray		*selection = [self selection];
   DrawGraphic	*graphic;

   for (x = 0; x < (const NSInteger)[selection count]; x++) {
      graphic = [selection objectAtIndex:x];
      if ([self canInspectObject:graphic]) {
         [[graphic page] graphicWillChange:graphic];
         [invocation invokeWithTarget:graphic];
      }
   }

#warning Implement
   //[[[DrawController sharedInstance] currentView] displayIntermediateResults];
}

@end
