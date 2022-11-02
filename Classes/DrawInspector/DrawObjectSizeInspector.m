/*
 DrawObjectSizeInspector.m
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
/* DrawObjectSizeInspector.m created by alex on Wed 03-Feb-1999 */

#import "DrawObjectSizeInspector.h"

#import "DrawGraphic.h"
#import "DrawPageLayout.h"
#import "DrawDocument.h"

#import <ASInterface/ASInterface.h>
#import <ASInterface/NSPrintInfo-Extensions.h>

@implementation DrawObjectSizeInspector

- (id)init
{
   self = [super init];

   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateGraphic:) name:DrawGraphicDidChangeFrameNotification object:nil];

   return self;
}

- (NSString *)title
{
   return @"Size";
}

- (void)updateGraphic:(NSNotification *)notification
{
#warning Implement
//   DrawView		*drawView = [[DrawController sharedInstance] currentView];
//   DrawGraphic	*graphic = [notification object];
//
//   if ([graphic drawView] == drawView) {
//      NSArray	*selection = [drawView selection];
//
//      if (([selection count] == 1) && ([selection objectAtIndex:0] == graphic)) {
//         [self update];
//      }
//   }
}

- (void)update
{
   NSArray			*selection = [self selection];

   if ([selection count]) {
      DrawGraphic			*graphic = [selection objectAtIndex:0];
      BOOL					multiple = [selection count] > 1;
      NSRect				frame = [graphic frame];
      NSPrintInfo			*printInfo = [[graphic drawDocument] printInfo];
      DrawAutosizeMask	mask = [graphic autoresizingMask];

      [xTextField setEnabled:!multiple];
      [yTextField setEnabled:!multiple];
      [widthTextField setEnabled:!multiple];
      [heightTextField setEnabled:!multiple];

      [xTextField setStringValue:multiple ? (NSString *)@"N/A" : [printInfo pointsAsMeasureString:frame.origin.x]];
      [yTextField setStringValue:multiple ? (NSString *)@"N/A" : [printInfo pointsAsMeasureString:frame.origin.y]];
      [widthTextField setStringValue:multiple ? (NSString *)@"N/A" : [printInfo pointsAsMeasureString:frame.size.width]];
      [heightTextField setStringValue:multiple ? (NSString *)@"N/A" : [printInfo pointsAsMeasureString:frame.size.height]];

      [leftEdgeButton setState:(mask & DrawGraphicMinXMargin) != 0];
      [rightEdgeButton setState:(mask & DrawGraphicMaxXMargin) != 0];
      if ([[graphic drawDocument] isFlipped]) {
         [topEdgeButton setState:(mask & DrawGraphicMinYMargin) != 0];
         [bottomEdgeButton setState:(mask & DrawGraphicMaxYMargin) != 0];
      } else {
         [topEdgeButton setState:(mask & DrawGraphicMaxYMargin) != 0];
         [bottomEdgeButton setState:(mask & DrawGraphicMinYMargin) != 0];
      }
      [horizontalButton setState:(mask & DrawGraphicWidthSizable) != 0];
      [verticalButton setState:(mask & DrawGraphicHeightSizable) != 0];
      [leftEdgeButton setEnabled:YES];
      [rightEdgeButton setEnabled:YES];
      [bottomEdgeButton setEnabled:YES];
      [topEdgeButton setEnabled:YES];
      [horizontalButton setEnabled:YES];
      [verticalButton setEnabled:YES];
   } else {
      [xTextField setEnabled:NO];
      [yTextField setEnabled:NO];
      [widthTextField setEnabled:NO];
      [heightTextField setEnabled:NO];
      [xTextField setStringValue:@"N/A"];
      [yTextField setStringValue:@"N/A"];
      [widthTextField setStringValue:@"N/A"];
      [heightTextField setStringValue:@"N/A"];
      [leftEdgeButton setState:NO];
      [leftEdgeButton setEnabled:NO];
      [rightEdgeButton setState:NO];
      [rightEdgeButton setEnabled:NO];
      [bottomEdgeButton setState:NO];
      [bottomEdgeButton setEnabled:NO];
      [topEdgeButton setState:NO];
      [topEdgeButton setEnabled:NO];
      [horizontalButton setState:NO];
      [horizontalButton setEnabled:NO];
      [verticalButton setState:NO];
      [verticalButton setEnabled:NO];
   }
}

- (void)setX:(id)sender
{
   DrawGraphic		*graphic = [[self selection] lastObject];
   NSRect			frame;
   NSPrintInfo		*printInfo = [[graphic drawDocument] printInfo];

   frame = [graphic frame];
   frame.origin.x = [printInfo measureToPoints:[xTextField floatValue]];

   [graphic setFrame:frame];
   
   [[yTextField window] makeFirstResponder:yTextField];
}

- (void)setY:(id)sender
{
   DrawGraphic		*graphic = [[self selection] lastObject];
   NSRect			frame;
   NSPrintInfo		*printInfo = [[graphic drawDocument] printInfo];

   frame = [graphic frame];
   frame.origin.y = [printInfo measureToPoints:[yTextField floatValue]];

   [graphic setFrame:frame];

   [[widthTextField window] makeFirstResponder:widthTextField];
}

- (void)setWidth:(id)sender
{
   DrawGraphic		*graphic = [[self selection] lastObject];
   NSRect			frame;
   NSPrintInfo		*printInfo = [[graphic drawDocument] printInfo];

   frame = [graphic frame];
   frame.size.width = [printInfo measureToPoints:[widthTextField floatValue]];

   [graphic setFrame:frame];

   [[heightTextField window] makeFirstResponder:heightTextField];
}

- (void)setHeight:(id)sender
{
   DrawGraphic		*graphic = [[self selection] lastObject];
   NSRect			frame;
   NSPrintInfo		*printInfo = [[graphic drawDocument] printInfo];

   frame = [graphic frame];
   frame.size.height = [printInfo measureToPoints:[heightTextField floatValue]];

   [graphic setFrame:frame];

   [[topEdgeButton window] makeFirstResponder:topEdgeButton];
}

- (DrawAutosizeMask)_buildMask
{
   DrawAutosizeMask 	mask = DrawGraphicNotSizable;

   if ([leftEdgeButton state]) mask |= DrawGraphicMinXMargin;
   if ([rightEdgeButton state]) mask |= DrawGraphicMaxXMargin;
   if ([horizontalButton state]) mask |= DrawGraphicWidthSizable;
   if ([verticalButton state]) mask |= DrawGraphicHeightSizable;
#warning Implement
//   if ([[[DrawController sharedInstance] currentView] isFlipped]) {
//      if ([topEdgeButton state]) mask |= DrawGraphicMinYMargin;
//      if ([bottomEdgeButton state]) mask |= DrawGraphicMaxYMargin;
//   } else {
//      if ([topEdgeButton state]) mask |= DrawGraphicMaxYMargin;
//      if ([bottomEdgeButton state]) mask |= DrawGraphicMinYMargin;
//   }

   return mask;
}

- (void)toggleLeftEdge:(id)sender
{
   DrawAutosizeMask	mask = [self _buildMask];

   [self setIntValue:mask withSelector:@selector(setAutoresizingMask:)];
}

- (void)toggleRightEdge:(id)sender
{
   DrawAutosizeMask	mask = [self _buildMask];

   [self setIntValue:mask withSelector:@selector(setAutoresizingMask:)];
}

- (void)toggleTopEdge:(id)sender
{
   DrawAutosizeMask	mask = [self _buildMask];

   [self setIntValue:mask withSelector:@selector(setAutoresizingMask:)];
}

- (void)toggleBottomEdge:(id)sender
{
   DrawAutosizeMask	mask = [self _buildMask];

   [self setIntValue:mask withSelector:@selector(setAutoresizingMask:)];
}

- (void)toggleHorizontal:(id)sender
{
   DrawAutosizeMask	mask = [self _buildMask];

   [self setIntValue:mask withSelector:@selector(setAutoresizingMask:)];
}

- (void)toggleVertical:(id)sender
{
   DrawAutosizeMask	mask = [self _buildMask];

   [self setIntValue:mask withSelector:@selector(setAutoresizingMask:)];
}

@end
