/* DrawView-Layers.m created by alex on Tue 06-Oct-1998 */

#import "DrawDocument.h"

#import "DrawDocumentStorage.h"
#import "DrawLayer.h"
#import "DrawPage.h"

#import <Draw/Draw-Swift.h>

#import <AJRInterface/AJRInterface.h>

NSString * const DrawLayerDidChangeNotification = @"DrawLayerDidChangeNotification";

@implementation DrawDocument (Layers)

- (DrawLayerViewController *)layerViewController {
    return AJRObjectIfKindOfClass([self.pagedView.window.contentViewController ajr_descendantViewControllerOfClass:DrawLayerViewController.class], DrawLayerViewController);
}

- (void)_resetLayerPopUpButton {
    [_layerPopUpButton removeAllItems];

    for (NSInteger x = 0; x < (const NSInteger)[_storage.layers count]; x++) {
        [_layerPopUpButton addItemWithTitle:[[_storage.layers objectAtIndex:x] name]];
    }
    [_layerPopUpButton setTitle:[_storage.layer name]];
}

- (NSArray *)layers {
    return _storage.layers;
}

- (void)setLayer:(DrawLayer *)aLayer {
    if (_storage.layer != aLayer) {
        if ([_storage.layers indexOfObjectIdenticalTo:aLayer] != NSNotFound) {
            _storage.layer = aLayer;
            [_layerPopUpButton setTitle:[_storage.layer name]];
        }
    }
}

- (DrawLayer *)layer {
    return _storage.layer;
}

- (void)setLayerWithName:(NSString *)aName {
    DrawLayer *temp = [self layerWithName:aName];

    if (temp) [self setLayer:temp];
}

- (void)addLayer:(DrawLayer *)aLayer {
    [_storage.layers addObject:aLayer];
    _storage.layer = aLayer;

    [self _resetLayerPopUpButton];
}

- (void)addLayerWithName:(NSString *)name {
    [self addLayer:[[DrawLayer alloc] initWithName:name document:self]];
}

- (void)removeLayer:(DrawLayer *)aLayer; {
    NSUInteger index = [_storage.layers indexOfObjectIdenticalTo:aLayer];

    if (index != NSNotFound) {
        [self removeLayerAtIndex:index];
    }
}

- (void)removeLayerWithName:(NSString *)aName {
    NSUInteger index = [self indexOfLayerWithName:aName];

    if (index != NSNotFound) {
        [self removeLayerAtIndex:index];
    }
}

- (void)removeLayerAtIndex:(NSUInteger)index {
    DrawLayer *oldLayer = [_storage.layers objectAtIndex:index];

    [_storage.layers removeObjectAtIndex:index];

    if (oldLayer == _storage.layer) {
        if (index < [_storage.layers count]) {
            _storage.layer = [_storage.layers objectAtIndex:index];
        } else {
            _storage.layer = [_storage.layers lastObject];
        }
    }

    [self _resetLayerPopUpButton];
}

- (void)moveLayerAtIndex:(NSUInteger)index toIndex:(NSUInteger)otherIndex {
    if (index != otherIndex) {
        DrawLayer *temp = [_storage.layers objectAtIndex:index];

        [_storage.layers removeObjectAtIndex:index];

        if (index < otherIndex) {
            [_storage.layers insertObject:temp atIndex:otherIndex];
        } else {
            [_storage.layers insertObject:temp atIndex:otherIndex];
        }

        [self _resetLayerPopUpButton];

        [[self.pagedView visiblePageIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [[_storage.pages objectAtIndex:idx] setNeedsDisplay:YES];
        }];
    }
}

- (NSUInteger)indexOfLayerWithName:(NSString *)name {
    for (NSUInteger x = 0; x < (const NSInteger)[_storage.layers count]; x++) {
        if ([[[_storage.layers objectAtIndex:x] name] isEqualToString:name]) {
            return x;
        }
    }

    return NSNotFound;
}

- (DrawLayer *)layerWithName:(NSString *)name {
    for (NSInteger x = 0; x < (const NSInteger)[_storage.layers count]; x++) {
        DrawLayer *layer = [_storage.layers objectAtIndex:x];
        if ([layer.name isEqualToString:name]) {
            return layer;
        }
    }
    return nil;
}

- (DrawLayer *)layerAtIndex:(NSUInteger)index {
    return [_storage.layers objectAtIndex:index];
}

- (NSUInteger)layerIndex {
    return [_storage.layers indexOfObjectIdenticalTo:_storage.layer];
}

- (NSUInteger)layerCount {
    return [_storage.layers count];
}

- (void)selectLayer:(id)sender {
    _storage.layer = [self layerWithName:[sender titleOfSelectedItem]];
    [[NSNotificationCenter defaultCenter] postNotificationName:DrawLayerDidChangeNotification object:self];
}

- (void)restoreLayerFromSnapshot:(NSDictionary *)snapshot {
    DrawLayer	*aLayer = [self layerWithName:[snapshot objectForKey:@"name"]];

    if (aLayer) {
        [self registerUndoWithTarget:self selector:@selector(restoreLayerFromSnapshot:) object:[aLayer snapshot]];
        [aLayer restoreFromSnapshot:snapshot];
    }
}

- (void)replaceNameOnLayerFromName:(NSString *)oldName toName:(NSString *)newName {
    DrawLayer *aLayer = [self layerWithName:oldName];

    [aLayer setName:newName];

    [self _resetLayerPopUpButton];
}

@end
