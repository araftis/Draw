/*
DrawPage-DragAndDrop.m
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

#import "DrawPage.h"

#import "DrawFunctions.h"
#import "DrawGraphic.h"
#import "DrawTool.h"
#import "DrawDocument.h"
#import "NSPasteboard-DrawExtensions.h"

@implementation DrawPage (DragAndDrop)

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	if (_draggingTool && [_draggingTool respondsToSelector:@selector(concludeDragOperation:inView:)]) {
		[_draggingTool concludeDragOperation:sender inView:self];
	}
	 _draggingTool = nil;
}

- (NSUInteger)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSArray			*tools;
	DrawTool		*tool;
	NSPasteboard	*pasteboard;
	NSUInteger		sourceDragMask;
	NSArray			*types;
	NSString		*type;
	NSInteger		x, y;
	NSUInteger		response;
	
	sourceDragMask = [sender draggingSourceOperationMask];
	pasteboard = [sender draggingPasteboard];
	
	types = [pasteboard types];
	
	if ([types containsObject:DrawGraphicPboardType]) {
		_draggingTool = (id)self;
		_draggingOperation = NSDragOperationCopy;
		return _draggingOperation;
	}
	
	for (x = 0; x < (const NSInteger)[types count]; x++) {
		type = [types objectAtIndex:x];
		tools = [[DrawDocument draggedTypes] objectForKey:type];
		for (y = 0; y < (const NSInteger)[tools count]; y++) {
			tool = [tools objectAtIndex:y];
			if ([tool respondsToSelector:@selector(draggingEntered:inView:)]) {
				response = [tool draggingEntered:sender inView:self];
				if (response != NSDragOperationNone) {
					_draggingTool = tool;
					_draggingOperation = response;
					return response;
				}
			}
		}
	}
	
	return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	if (_draggingTool) {
		if (_draggingTool == (id)self) {
			 _draggingTool = nil;
		} else if ([_draggingTool respondsToSelector:@selector(draggingExited:inView:)]) {
			[_draggingTool draggingExited:sender inView:self];
		}
	}
	 _draggingTool = nil;
}

- (NSUInteger)draggingUpdated:(id <NSDraggingInfo>)sender
{
	if (_draggingTool) {
		if (_draggingTool == (id)self) {
			return _draggingOperation;
		} else if ([_draggingTool respondsToSelector:@selector(draggingUpdated:inView:)]) {
			return [_draggingTool draggingUpdated:sender inView:self];
		}
	}
	return _draggingOperation;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if (_draggingTool) {
		if (_draggingTool == (id)self) {
			NSPasteboard	*pasteboard = [sender draggingPasteboard];
			NSString			*type;
			
			type = [pasteboard availableTypeFromArray:[NSArray arrayWithObjects:DrawGraphicPboardType, nil]];
			
			if ([type isEqualToString:DrawGraphicPboardType]) {
				NSArray			*graphics;
				DrawGraphic		*graphic;
				NSInteger		x;
				NSRect			bounds;
				NSPoint			location;
				NSPoint			delta;
				NSPoint			origin;
				
				graphics = [pasteboard drawGraphicsForType:DrawGraphicPboardType];
				bounds = DrawBoundsForGraphics(graphics);
				location = [self convertPoint:[sender draggedImageLocation] fromView:nil];
				delta.x = bounds.origin.x - location.x;
				if ([self isFlipped]) {
					delta.y = bounds.origin.y - (location.y - bounds.size.height);
				} else {
					delta.y = bounds.origin.y - location.y;
				}
				
				if ([graphics count]) {
					for (x = 0; x < (const NSInteger)[graphics count]; x++) {
						graphic = [graphics objectAtIndex:x];
						origin = [graphic frame].origin;
						origin.x -= delta.x;
						origin.y -= delta.y;
						[graphic setFrameOrigin:origin];
						[graphic setDocument:_document];
						[self addGraphic:graphic toLayer:[_document layer]];
					}
					
					[_document clearSelection];
					[_document addGraphicsToSelection:graphics];
				}
			}
			return YES;
		} else if ([_draggingTool respondsToSelector:@selector(performDragOperation:inView:)]) {
			return [_draggingTool performDragOperation:sender inView:self];
		}
	}
	return NO;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	if (_draggingTool) {
		if (_draggingTool == (id)self) {
			return YES;
		} else if ([_draggingTool respondsToSelector:@selector(prepareForDragOperation:inView:)]) {
			return [_draggingTool prepareForDragOperation:sender inView:self];
		}
	}
	return NO;
}

@end
