/*
DrawObjectInspector.m
Draw

Copyright © 2021, AJ Raftis and AJRFoundation authors
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this 
  list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, 
  this list of conditions and the following disclaimer in the documentation 
  and/or other materials provided with the distribution.
* Neither the name of Draw nor the names of its contributors may be 
  used to endorse or promote products derived from this software without 
  specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL AJ RAFTIS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
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
