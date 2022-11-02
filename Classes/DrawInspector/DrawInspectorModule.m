/*
 DrawInspectorModule.m
 Draw

 Copyright © 2022, AJ Raftis and Draw authors
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
