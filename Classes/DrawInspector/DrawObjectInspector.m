/* DrawObjectInspector.m created by alex on Fri 16-Oct-1998 */

#import "DrawObjectInspector.h"

#import <ASInterface/ASBox.h>

@implementation DrawObjectInspector

- (NSString *)title
{
   return @"Object";
}

- (void)update
{
   NSArray			*selection = [self selection];
   NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
   BOOL				inspect = YES;

   if ([selection count]) {
      DrawGraphic				*graphic;
      DrawInspectorModule	*inspector;
      
      if ([selection count] > 1) {
         // We only want to continue if all out subsequent types are the same.
         NSInteger			x;
         Class			class = [[selection objectAtIndex:0] class];
         
         for (x = 1; x < (const NSInteger)[selection count]; x++) {
            if ([[selection objectAtIndex:x] class] != class) {
               inspect = NO;
               break;
            }
         }
      }

      if (inspect) {
         [[view window] disableFlushWindow];
         graphic = [selection objectAtIndex:0];
         inspector = [graphic inspector];
         [subinspector setContentView:[inspector view]];
         [inspector update];
         [flatnessText setFloatValue:[graphic flatness]];
         [flatnessSlider setIntValue:[graphic flatness]];
         [[view window] enableFlushWindow];
         [[view window] flushWindow];
         [subinspector setTitle:[inspector title]];
   
         [defaults setFloat:[graphic flatness] forKey:DrawFlatnessKey];
         
         return;
      }
   }

   [subinspector setContentView:nil];
   [subinspector setTitle:inspect ? @"No Object Selected" : @"Multiple Types Selected"];
   [flatnessText setFloatValue:[defaults floatForKey:DrawFlatnessKey]];
   [flatnessSlider setIntValue:[defaults floatForKey:DrawFlatnessKey]];
}

- (void)setRepetitionMatrix:(NSMatrix *)aMatrix
{
//   ASToolCell		*cell;
//
//   [aMatrix setCellClass:[ASToolCell class]];
//
//   cell = [[ASToolCell allocWithZone:[self zone]] initWithImages:[NSImage imageNamed:@"objectNoRepeat"], [NSImage imageNamed:@"objectAllRepeat"], [NSImage imageNamed:@"objectOddRepeat"], [NSImage imageNamed:@"objectEvenRepeat"], nil];
//   [cell setTriggerOnMouseDown:YES];
//   [cell setPopDirection:ASPopVertical];
//
//   [aMatrix putCell:cell atRow:0 column:0];
//
//   repetitionMatrix = aMatrix;
}

- (void)setFlatness:(id)sender
{
   CGFloat		value;
   
   if (sender == flatnessText) {
      value = [sender floatValue];
      [flatnessSlider setFloatValue:rint(value)];
   } else {
      value = rint([sender floatValue]);
      [flatnessText setFloatValue:value];
   }

   [self setFloatValue:value withSelector:@selector(setFlatness:)];
   [[NSUserDefaults standardUserDefaults] setFloat:value forKey:DrawFlatnessKey];
}

- (void)setObjectRepetition:(id)sender
{
}

@end
