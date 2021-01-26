/* DrawAspectInspector.m created by alex on Fri 16-Oct-1998 */

#import "DrawAspectInspector.h"

#import "DrawAspect.h"
#import "DrawGraphic.h"
#import "DrawDocument.h"

@implementation DrawAspectInspector

- (id)init
{
   self = [super init];

   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_graphicDidInit:) name:DrawGraphicDidInitNotification object:nil];

   return self;
}

- (DrawAspect *)aspectWithGraphic:(DrawGraphic *)graphic
{
   return nil;
}

- (void)_graphicDidInit:(NSNotification *)notification
{
   [self graphicDidInit:[notification object]];
}

- (void)graphicDidInit:(DrawGraphic *)graphic
{
   if ([self active]) {
      DrawAspect		*aspect = [self aspectWithGraphic:graphic];

      if (aspect) {
         [graphic setAspect:aspect forKey:[self aspectKey] withPriority:[self aspectPriority]];
      }
   }
}

- (NSString *)aspectKey
{
   return @"";
}

- (void)performInvocation:(NSInvocation *)invocation
{
   NSInteger			x;
   NSArray		*selection = [self selection];
   DrawAspect	*aspect;
   DrawGraphic	*graphic;

   for (x = 0; x < (const NSInteger)[selection count]; x++) {
      graphic = [selection objectAtIndex:x];
      aspect = [graphic aspectForKey:[self aspectKey]];
      if (!aspect) {
         aspect = [self aspectWithGraphic:graphic];
         [graphic setAspect:aspect forKey:[self aspectKey] withPriority:[self aspectPriority]];
         if (![self active]) [self setActive:YES];
      }
      [invocation invokeWithTarget:aspect];
   }

#warning Implement
//   [[[DrawController sharedInstance] currentView] displayIntermediateResults];
}

- (NSString *)_activeKey
{
   return [NSString stringWithFormat:@"%@Active", [self aspectKey]];
}

- (void)setActive:(BOOL)flag
{
   [activeCheck setState:flag];
   [[NSUserDefaults standardUserDefaults] setObject:flag ? @"YES" : @"NO" forKey:[self _activeKey]];
}

- (BOOL)active
{
   return [[[NSUserDefaults standardUserDefaults] stringForKey:[self _activeKey]] hasPrefix:@"Y"];
}

- (void)toggleActive:(id)sender
{
   NSUserDefaults			*defaults = [NSUserDefaults standardUserDefaults];
   NSArray					*selection = [self selection];
   NSInteger						x;
   DrawGraphic				*graphic;

   if ([sender state]) {
      [defaults setObject:@"YES" forKey:[self _activeKey]];
      for (x = 0; x < (const NSInteger)[selection count]; x++) {
         graphic = [selection objectAtIndex:x];
         [graphic setAspect:[self aspectWithGraphic:graphic] forKey:[self aspectKey] withPriority:[self aspectPriority]];
      }
   } else {
      [defaults setObject:@"NO" forKey:[self _activeKey]];
      for (x = 0; x < (const NSInteger)[selection count]; x++) {
         graphic = [selection objectAtIndex:x];
         [graphic removeAspectForKey:[self aspectKey]];
      }
   }
}

@end
