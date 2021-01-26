/* DrawPage-DragAndDrop.m created by alex on Fri 06-Nov-1998 */

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
