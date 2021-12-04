/*
DrawDocument-Selection.m
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

#import "DrawDocument.h"

#import "DrawDocumentStorage.h"
#import "DrawGraphic.h"
#import "DrawLayer.h"
#import "DrawPage.h"
#import "DrawToolSet.h"

#import <AJRFoundation/NSMutableArray+Extensions.h>
#import <Draw/Draw-Swift.h>
#import <objc/runtime.h>

@implementation DrawDocument (Selection)

// Sorts graphics by page, layer, order.
static NSComparisonResult _compareGraphics(DrawGraphic *first, DrawGraphic *second, DrawDocument *self) {
    DrawPage *firstPage = first.page;
    DrawPage *secondPage = second.page;
    DrawLayer *firstLayer;
    DrawLayer *secondLayer;
    NSArray *graphics;
    
    // First see if they're on the same page.
    if (firstPage != secondPage) {
        return [self.pages indexOfObjectIdenticalTo:firstPage] - [self.pages indexOfObjectIdenticalTo:secondPage];
    }
    
    firstLayer = first.layer;
    secondLayer = second.layer;
    
    // Next compare the layers.
    if (firstLayer != secondLayer) {
        return [self.layers indexOfObjectIdenticalTo:firstLayer] - [self.layers indexOfObjectIdenticalTo:secondLayer];
    }
    
    // At this point, both graphcis are on the same page and layer. So compare their position in the layer.
    graphics = [first.page graphicsForLayer:firstLayer];
    
    return [graphics indexOfObjectIdenticalTo:first] - [graphics indexOfObjectIdenticalTo:second];
}

- (BOOL)isGraphicSelected:(DrawGraphic *)graphic {
    return [_storage.selection containsObject:graphic];
}

- (void)addGraphicToSelection:(DrawGraphic *)graphic {
    [self addGraphicsToSelection:@[graphic]];
}

- (void)removeGraphicFromSelection:(DrawGraphic *)graphic {
    [self removeGraphicsFromSelection:@[graphic]];
}

- (void)addGraphicsToSelection:(id <NSFastEnumeration,NSCopying>)graphics {
    [self willChangeValueForKey:@"selection"];
    NSArray<DrawGraphic *> *currentSelection = _storage.selection.allObjects;
    for (DrawGraphic *graphic in [graphics copyWithZone:NULL]) {
        [_storage.selection addObject:graphic];
        [graphic.page setNeedsDisplayInRect:graphic.dirtyBounds];
    }
    if (currentSelection.count > 0) {
        [self.inspectorGroupsViewController pop:currentSelection for:AJRInspectorIdentifierGraphic];
    }
    [self.inspectorGroupsViewController push:_storage.selection.allObjects for:AJRInspectorContentIdentifierAny];
    [self didChangeValueForKey:@"selection"];
}

- (void)removeGraphicsFromSelection:(id <NSFastEnumeration,NSCopying>)graphics {
    [self willChangeValueForKey:@"selection"];
    NSArray<DrawGraphic *> *currentSelection = _storage.selection.allObjects;
    for (DrawGraphic *graphic in [graphics copyWithZone:NULL]) {
        [graphic.page setNeedsDisplayInRect:graphic.dirtyBounds];
        [graphic setEditing:NO];
        [_storage.selection removeObject:graphic];
    }
    if (currentSelection.count > 0) {
        [self.inspectorGroupsViewController pop:currentSelection for:AJRInspectorContentIdentifierAny];
    }
    if (_storage.selection.count > 0) {
        [self.inspectorGroupsViewController push:_storage.selection.allObjects for:AJRInspectorContentIdentifierAny];
    } else {
        [self.inspectorGroupsViewController push:@[_storage.templateGraphic] for:AJRInspectorContentIdentifierAny];
    }
    [self didChangeValueForKey:@"selection"];
}

- (NSSet *)selection {
    return _storage.selection;
}

- (NSSet *)selectionForInspection {
    return [_storage.selection count] ? _storage.selection : [_currentToolSet selectionForInspectionForDocument:self];
}

- (NSArray *)sortedSelection {
    return [[_storage.selection allObjects] sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))_compareGraphics context:(__bridge void *)(self)];
}

- (void)clearSelection {
    [self removeGraphicsFromSelection:_storage.selection];
}

- (IBAction)deleteSelection:(id)sender {
    [self deleteSelection];
}

- (void)deleteSelection {
    if ([_storage.selection count]) {
        for (DrawGraphic *graphic in _storage.selection) {
            if ([graphic supergraphic]) {
                [graphic removeFromSupergraphic];
            } else {
                [self removeGraphic:graphic];
            }
        }
        
        [self clearSelection];
    }
}

- (IBAction)moveSelectionUp:(id)sender {
    [self moveSelectionUp];
}

- (void)moveSelectionUp {
    DrawPage *page;
    NSMutableArray *graphics;
    NSUInteger index;
    NSArray *selection = [self sortedSelection];
    
    if ([selection count]) {
        for (DrawGraphic *graphic in selection) {
            page = [graphic page];
            if (_storage.group) {
                graphics = (NSMutableArray *)[_storage.group subgraphics];
            } else {
                graphics = [page graphicsForLayer:[graphic layer]];
            }
            
            index = [graphics indexOfObjectIdenticalTo:graphic];
            if (index != [graphics count] - 1) {
                if (![self isGraphicSelected:[graphics objectAtIndex:index + 1]]) {
                    [graphics moveObjectAtIndex:index toIndex:index + 1];
                    [[graphic page] graphicWillChange:graphic];
                }
            }
        }
    }
}

- (IBAction)moveSelectionToTop:(id)sender {
    [self moveSelectionToTop];
}

- (void)moveSelectionToTop {
    if ([_storage.selection count]) {
        DrawPage *page, *oldPage;
        DrawGraphic *graphic;
        DrawLayer *newLayer, *oldLayer;
        NSMutableArray *graphics;
        NSUInteger index;
        NSInteger destinationIndex = 0;
        NSUInteger graphicsCount = 0;
        NSArray *selection = [self sortedSelection];
        
        oldPage = nil;
        oldLayer = nil;
        for (NSInteger x = [selection count] - 1; x >= 0; x--) {
            graphic = [selection objectAtIndex:x];
            page = [graphic page];
            newLayer = [graphic layer];
            if (_storage.group) {
                graphics = (NSMutableArray *)[_storage.group subgraphics];
            } else {
                graphics = [page graphicsForLayer:[graphic layer]];
            }
            
            if ((oldPage != page) || (oldLayer != newLayer)) {
                graphicsCount = [graphics count];
                destinationIndex = graphicsCount - 1;
            }
            
            if (destinationIndex > -1) {
                index = [graphics indexOfObjectIdenticalTo:graphic];
                if (index < destinationIndex) {
                    while ([self isGraphicSelected:[graphics objectAtIndex:destinationIndex]] && (destinationIndex > -1)) destinationIndex--;
                    if ((destinationIndex > -1) && (index < destinationIndex)) {
                        [graphics moveObjectAtIndex:index toIndex:destinationIndex];
                        [[graphic page] graphicWillChange:graphic];
                    }
                }
            }
            
            oldPage = page;
            oldLayer = newLayer;
        }
    }
}

- (IBAction)moveSelectionDown:(id)sender {
    [self moveSelectionDown];
}

- (void)moveSelectionDown {
    if ([_storage.selection count]) {
        DrawPage *page;
        DrawGraphic *graphic;
        NSMutableArray *graphics;
        NSUInteger index;
        NSArray *selection = [self sortedSelection];
        
        for (NSInteger x = [selection count] - 1; x >= 0; x--) {
            graphic = [selection objectAtIndex:x];
            page = [graphic page];
            if (_storage.group) {
                graphics = (NSMutableArray *)[_storage.group subgraphics];
            } else {
                graphics = [page graphicsForLayer:[graphic layer]];
            }
            
            index = [graphics indexOfObjectIdenticalTo:graphic];
            if (index != 0) {
                if (![self isGraphicSelected:[graphics objectAtIndex:index - 1]]) {
                    [graphics moveObjectAtIndex:index toIndex:index - 1];
                    [[graphic page] graphicWillChange:graphic];
                }
            }
        }
    }
}

- (IBAction)moveSelectionToBottom:(id)sender {
    [self moveSelectionToBottom];
}

- (void)moveSelectionToBottom {
    if ([_storage.selection count]) {
        DrawPage *page, *oldPage;
        DrawGraphic *graphic;
        DrawLayer *newLayer, *oldLayer;
        NSMutableArray *graphics;
        NSUInteger index;
        NSUInteger destinationIndex = 0;
        NSUInteger graphicsCount = 0;
        NSArray *selection = [self sortedSelection];
        
        oldPage = nil;
        oldLayer = nil;
        for (NSInteger x = 0; x < (const NSInteger)[selection count]; x++) {
            graphic = [selection objectAtIndex:x];
            page = [graphic page];
            newLayer = [graphic layer];
            if (_storage.group) {
                graphics = (NSMutableArray *)[_storage.group subgraphics];
            } else {
                graphics = [page graphicsForLayer:[graphic layer]];
            }
            
            if ((oldPage != page) || (oldLayer != newLayer)) {
                destinationIndex = 0;
                graphicsCount = [graphics count];
            }
            
            if (destinationIndex != graphicsCount) {
                index = [graphics indexOfObjectIdenticalTo:graphic];
                if (index > destinationIndex) {
                    while ([self isGraphicSelected:[graphics objectAtIndex:destinationIndex]] && (destinationIndex < graphicsCount)) destinationIndex++;
                    if ((destinationIndex < graphicsCount) && (index > destinationIndex)) {
                        [graphics moveObjectAtIndex:index toIndex:destinationIndex];
                        [[graphic page] graphicWillChange:graphic];
                    }
                }
            }
            
            oldPage = page;
            oldLayer = newLayer;
        }
    }
}

- (IBAction)selectAll:(id)sender {
    NSInteger pageIndex, layerIndex;
    NSArray *graphics;
    DrawLayer *aLayer;
    
    [self clearSelection];
    
    if (_storage.group) {
        graphics = [_storage.group subgraphics];
        [self addGraphicsToSelection:graphics];
    } else {
        for (pageIndex = 0; pageIndex < (const NSInteger)[_storage.pages count]; pageIndex++) {
            for (layerIndex = 0; layerIndex < (const NSInteger)[_storage.layers count]; layerIndex++) {
                aLayer = [_storage.layers objectAtIndex:layerIndex];
                if (![aLayer locked]) {
                    [self addGraphicsToSelection:[[_storage.pages objectAtIndex:pageIndex] graphicsForLayer:aLayer]];
                }
            }
        }
    }
}

- (BOOL)selectionContainsGroups {
    for (DrawGraphic *graphic in _storage.selection) {
        if ([[graphic subgraphics] count]) return YES;
    }
    
    return NO;
}

- (DrawGraphic *)groupFromSelection {
    DrawGraphic *group = nil;
    
    for (DrawGraphic *graphic in _storage.selection) {
        if ([[graphic subgraphics] count]) {
            if (group) return nil;
            group = graphic;
        }
    }
    
    return group;
}

@end
