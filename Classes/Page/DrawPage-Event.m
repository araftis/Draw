/* DrawView-Mouse.m created by alex on Thu 08-Oct-1998 */

#import "DrawPage.h"

#import "DrawEvent.h"
#import "DrawGraphic.h"
#import "DrawInspector.h"
#import "DrawTool.h"
#import "DrawToolSet.h"
#import "DrawDocument.h"

@implementation DrawPage (Event)

#pragma mark - Utilities

typedef BOOL (*DrawMethod)(id, SEL, id);

- (BOOL)makeSelectionPerformSelector:(SEL)selector withObject:(id)anObject shortCircuit:(BOOL)shortCircuit {
    BOOL handledReturn = NO;
    NSSet *selection = [_document selection];

    for (DrawGraphic *graphic in selection) {
        DrawMethod method = (DrawMethod)AJRGetMethodImplementation(graphic.class, selector);
        if (method != NULL) {
            BOOL handledEvent = method(graphic, selector, anObject);
            if (handledEvent) {
                handledReturn = YES;
                if (shortCircuit) {
                    break;
                }
            }
        }
    }

    return handledReturn;
}

#pragma mark - Left Mouse

- (void)mouseDown:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![_document.currentTool mouseDown:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(mouseDown:) withObject:drawEvent shortCircuit:YES];
    } else {
        [[self window] makeFirstResponder:self];
    }
}

- (void)mouseDragged:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] mouseDragged:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(mouseDragged:) withObject:drawEvent shortCircuit:YES];
    }
}

- (void)mouseUp:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] mouseUp:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(mouseUp:) withObject:drawEvent shortCircuit:YES];
    }
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
    return YES;
}

#pragma mark - Mouse Tracking

- (void)mouseMoved:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] mouseMoved:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(mouseMoved:) withObject:drawEvent shortCircuit:YES];
    } else {
        [[self window] makeFirstResponder:self];
    }
}

- (void)mouseEntered:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] mouseEntered:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(mouseEntered:) withObject:drawEvent shortCircuit:YES];
    } else {
        [[self window] makeFirstResponder:self];
    }
}

- (void)mouseExited:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] mouseExited:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(mouseExited:) withObject:drawEvent  shortCircuit:YES];
    } else {
        [[self window] makeFirstResponder:self];
    }
}

#pragma mark - Right Mouse

- (void)rightMouseDown:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] rightMouseDown:drawEvent]) {
        if (![self makeSelectionPerformSelector:@selector(rightMouseDown:) withObject:drawEvent shortCircuit:YES]) {
            [super rightMouseDown:event];
        }
    } else {
        [[self window] makeFirstResponder:self];
    }
}

- (void)rightMouseDragged:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] rightMouseDragged:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(rightMouseDragged:) withObject:drawEvent shortCircuit:YES];
    }
}

- (void)rightMouseUp:(NSEvent *)event  {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] rightMouseUp:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(rightMouseUp:) withObject:drawEvent shortCircuit:YES];
    }
}

#pragma mark - Keyboard

- (DrawTool *)findToolMatchingKeyString:(NSString *)keyString {
    DrawToolSet *toolSet = [_document currentToolSet];

    for (DrawTool *tool in [toolSet tools]) {
        if ([keyString isEqualToString:[tool activationKey]]) {
            return tool;
        }
    }

    return nil;
}

- (void)keyDown:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    [[self window] makeFirstResponder:self];

    if (![[_document currentTool] keyDown:drawEvent]) {
        if (![self makeSelectionPerformSelector:@selector(keyDown:) withObject:drawEvent shortCircuit:NO]) {
            // So none of our tools did anything with the key event, maybe we can.
            DrawTool *tool = [self findToolMatchingKeyString:[event characters]];
            if (tool == nil) {
                NSBeep();
            } else {
                NSArray *actions = [tool actions];
                if ([_document currentTool] == tool && [actions count] > 1) {
                    DrawToolAction *currentAction = [tool currentAction];
                    NSUInteger index = [[tool actions] indexOfObjectIdenticalTo:currentAction];

                    index = (index + 1) % [actions count];

                    [tool setCurrentAction:[[tool actions] objectAtIndex:index]];
                } else {
                    [_document setCurrentTool:tool];
                }
            }
        }
    }
}

- (void)keyUp:(NSEvent *)event  {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] keyUp:drawEvent]) {
        if (![self makeSelectionPerformSelector:@selector(keyUp:) withObject:drawEvent shortCircuit:YES]) {
            [super keyUp:event];
        }
    }
}

- (void)flagsChanged:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] flagsChanged:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(flagsChanged:) withObject:drawEvent shortCircuit:YES];
    }
}

- (void)helpRequested:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];

    [_document setPage:self];

    if (![[_document currentTool] helpRequested:drawEvent]) {
        [self makeSelectionPerformSelector:@selector(helpRequested:) withObject:drawEvent shortCircuit:YES];
    } else {
        [[self window] makeFirstResponder:self];
    }
}

#pragma mark - Menus

- (void)addCopyOfMenu:(NSMenu *)sourceMenu to:(NSMenu *)menu {
    if (sourceMenu && [[sourceMenu itemArray] count]) {
        [menu addItem:[NSMenuItem separatorItem]];
        for (NSMenuItem *item in [sourceMenu itemArray]) {
            NSMenuItem *newItem;

            newItem = [menu addItemWithTitle:[item title] action:[item action] keyEquivalent:[item keyEquivalent]];
            [newItem setTarget:[item target]];
            [newItem setHidden:[item isHidden]];
            [newItem setAlternate:[item isAlternate]];
            [newItem setImage:[item image]];
            [newItem setOnStateImage:[item onStateImage]];
            [newItem setOffStateImage:[item offStateImage]];
            [newItem setMixedStateImage:[item mixedStateImage]];
            [newItem setTag:[item tag]];
            [newItem setState:[item state]];
            [newItem setIndentationLevel:[item indentationLevel]];
            [newItem setToolTip:[item toolTip]];
            [newItem setRepresentedObject:[item representedObject]];
            [newItem setView:[item view]];
        }
    }
}

- (NSMenu *)menuForEvent:(NSEvent *)event {
    DrawEvent *drawEvent = [DrawEvent eventWithOriginalEvent:event document:_document page:self];
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Context Menu"];
    NSMenuItem *item;
    BOOL hasSelection = [[_document selection] count];

    if (hasSelection) {
        item = [menu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@""];
        item = [menu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@""];
    }
    item = [menu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@""];

    for (DrawToolSet *toolSet in DrawToolSet.toolSets) {
        [self addCopyOfMenu:[toolSet menuForEvent:drawEvent] to:menu];
    }
    for (DrawTool *tool in [[_document currentToolSet] tools]) {
        [self addCopyOfMenu:[tool menuForEvent:drawEvent] to:menu];
    }

    return menu;
}

#pragma mark - Dragging

- (BOOL)dragSelection:(NSArray *)selection withLastHitGraphic:(DrawGraphic *)graphic fromEvent:(DrawEvent *)event; {
    return [[graphic document] dragSelection:selection withLastHitGraphic:graphic fromEvent:event];
}

@end
