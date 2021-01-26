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
