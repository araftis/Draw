/*
DrawInspectorController.m
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
/* DrawInspectorController.m created by alex on Sun 11-Oct-1998 */

#import "DrawInspectorController.h"

#import "DrawController.h"
#import "DrawInspector.h"
#import "DrawView.h"

#import <ASFoundation/ASFoundation.h>
#import <ASInterface/ASBox.h>

static DrawInspectorController *SELF = nil;

NSString *DrawInspectorOrderKey = @"DrawInspectorOrderKey";

@implementation DrawInspectorController

+ (id)allocWithZone:(NSZone *)zone
{
   if (!SELF) SELF = [super allocWithZone:zone];
   return SELF;
}

+ (void)initialize
{
}

- (id)init
{
   if (!window) {
      [NSBundle loadNibNamed:@"DrawInspector" owner:self];
      [window setFrameAutosaveName:@"DrawInspector"];
      [window setFrameUsingName:@"DrawInspector"];
      [window setHidesOnDeactivate:YES];

      while ([buttons numberOfRows]) {
         [buttons removeRow:[buttons numberOfRows] - 1];
      }

      inspectors = [[NSMutableArray allocWithZone:[self zone]] init];

      [buttons sizeToFit];

      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(drawViewDidChangeSelection:) name:DrawViewDidChangeSelectionNotification object:nil];

      [self sortCells];

      [self setInspector:[inspectors objectAtIndex:[[buttons cellAtRow:0 column:0] tag]]];
   }

   return self;
}

- (void)dealloc
{
   // No-op
}

+ (id)sharedInstance
{
   return [[self alloc] init];
}

- (void)showDrawInspectorPanel:(id)sender
{
   [inspector update];
   [window makeKeyAndOrderFront:sender];
}

- (BOOL)selectInspectorAtIndex:(NSUInteger)index
{
   NSCell	*cell;

   if (index < [buttons numberOfRows]) {
      cell = [buttons cellAtRow:index column:0];
      [buttons selectCellAtRow:index column:0];
      [self setInspector:[inspectors objectAtIndex:[cell tag]]];
      if (![window isVisible]) [window orderFront:self];
      return YES;
   }

   return NO;
}

- (void)setInspector:(DrawInspector *)anInspector
{
   if (inspector != anInspector) {
      [inspector release];
      inspector = [anInspector retain];

      [box setContentView:[inspector view]];
   }

   [inspector update];
}

- (void)selectInspector:(id)sender
{
   [self setInspector:[inspectors objectAtIndex:[[sender selectedCell] tag]]];
}

- (void)addInspector:(Class)anInspectorClass
{
   DrawInspector	*anInspector = [[anInspectorClass allocWithZone:[self zone]] init];
   NSCell			*cell;

   if ([anInspector icon]) {
      [inspectors addObject:anInspector];
      [anInspector release];

      [buttons addRow];
      cell = [[buttons cells] lastObject];
      [cell setTag:[inspectors count] - 1];
      [cell setImage:[anInspector icon]];
   }

   ASPrintf(@"Inspector: %@\n", anInspectorClass);
}

- (BOOL)matrix:(NSMatrix *)matrix canMoveCell:(NSCell *)aCell atRow:(NSUInteger)rowIndex column:(NSUInteger)column toRow:(NSUInteger)otherRowIndex column:(NSUInteger)otherRowInde
{
   return YES;
}

- (void)matrix:(NSMatrix *)matrix didMoveCell:(NSCell *)aCell atRow:(NSUInteger)rowIndex column:(NSUInteger)column toRow:(NSUInteger)otherRowIndex column:(NSUInteger)otherColumnIndex
{
   NSArray			*cells = [buttons cells];
   NSMutableArray	*inspectorNames = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:[cells count]];
   NSInteger				x;

   for (x = 0; x < (const NSInteger)[cells count]; x++) {
      [inspectorNames addObject:[[[inspectors objectAtIndex:[[cells objectAtIndex:x] tag]] class] description]];
   }

   [[NSUserDefaults standardUserDefaults] setObject:inspectorNames forKey:DrawInspectorOrderKey];
}

- (void)drawViewDidChangeSelection:(NSNotification *)notification
{
   if ([notification object] == [[DrawController sharedInstance] currentView]) {
      [inspector update];
   }
}

static NSArray *_order = nil;
static NSArray *_inspectors = nil;

static NSComparisonResult cellSorter(NSCell *first, NSCell *second, DrawInspectorController *self)
{
   NSInteger		index1, index2;
   NSString	*name1 = [[[_inspectors objectAtIndex:[first tag]] class] description];
   NSString	*name2 = [[[_inspectors objectAtIndex:[second tag]] class] description];

   index1 = [_order indexOfObject:name1];
   index2 = [_order indexOfObject:name2];

   if ((index1 == NSNotFound) && (index2 != NSNotFound)) return NSOrderedDescending;
   if ((index1 != NSNotFound) && (index2 == NSNotFound)) return NSOrderedAscending;
   if ((index1 == NSNotFound) && (index2 == NSNotFound)) return [name1 compare:name2];

   if (index1 < index2) return NSOrderedAscending;
   if (index1 > index2) return NSOrderedDescending;

   return NSOrderedSame;
}

- (void)sortCells
{
   _order = [[[NSUserDefaults standardUserDefaults] stringArrayForKey:DrawInspectorOrderKey] retain];

   if (_order) {
      _inspectors = inspectors;
      [buttons sortUsingFunction:(NSInteger (*)(id, id ,void *))cellSorter context:self];
      [_order release]; _order = nil;
      _inspectors = nil;
      [buttons setNeedsDisplay:YES];
   }
}

@end


@implementation NSResponder (DrawInspectorControll)

- (void)showDrawInspectorPanel:(id)sender
{
   [[DrawInspectorController sharedInstance] showDrawInspectorPanel:sender];
}

@end
