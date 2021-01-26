//
//  DrawSelectionActions.m
//  Draw
//
//  Created by Alex Raftis on 7/7/11.
//  Copyright 2011 Apple, Inc. All rights reserved.
//

#import "DrawSelectionActions.h"

#import "DrawDocument.h"
#import "DrawGraphic.h"

#import <AJRFoundation/AJRFunctions.h>

@implementation DrawSelectionActions {
    NSMutableDictionary<NSString *, NSMenuItem *> *_menuItems;
}

+ (id)sharedInstance {
    static DrawSelectionActions *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[DrawSelectionActions alloc] init];
    });
    return _sharedInstance;
}

#pragma mark - Creation

- (id)init {
    if ((self = [super init])) {
        _menuItems = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - Activation

- (NSMenuItem *)itemWithTitle:(NSString *)title action:(SEL)action keyEquivalent:(NSString *)keyEquivalent modifierMask:(NSUInteger)modifierMask key:(NSString *)key {
    NSMenuItem  *item = [_menuItems objectForKey:key];
    
    if (item == nil) {
        if ([title isEqualToString:@"-"]) {
            item = [NSMenuItem separatorItem];
        } else {
            item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:keyEquivalent];
            [item setTarget:self];
            if (modifierMask) [item setKeyEquivalentModifierMask:modifierMask];
        }
        [_menuItems setObject:item forKey:key];
    }
    
    return item;
}

- (void)activate {
    if ([_menuItems count] == 0) {
        NSMutableArray *items = [NSMutableArray array];

        [items addObject:[self itemWithTitle:@"Bring Forward" action:@selector(bringForward:) keyEquivalent:@"f" modifierMask:NSEventModifierFlagOption | NSEventModifierFlagShift | NSEventModifierFlagCommand key:@"bringForward"]];
        [items addObject:[self itemWithTitle:@"Bring to Front" action:@selector(bringToFront:) keyEquivalent:@"f" modifierMask:NSEventModifierFlagShift | NSEventModifierFlagCommand key:@"bringToFront"]];
        [items addObject:[self itemWithTitle:@"Send Backward" action:@selector(sendBackward:) keyEquivalent:@"b" modifierMask:NSEventModifierFlagOption | NSEventModifierFlagShift | NSEventModifierFlagCommand key:@"sendBackward"]];
        [items addObject:[self itemWithTitle:@"Send to Back" action:@selector(sendToBack:) keyEquivalent:@"b" modifierMask:NSEventModifierFlagShift | NSEventModifierFlagCommand key:@"sendToBack"]];

        [DrawDocument addItems:items toMenu:[DrawDocument arrangeMenu]];
        [items removeAllObjects];

        [items addObject:[self itemWithTitle:@"Flip Horizontally" action:@selector(flipHorizontal:) keyEquivalent:@"" modifierMask:0 key:@"flipHorizontal"]];
        [items addObject:[self itemWithTitle:@"Flip Vertically" action:@selector(flipVertical:) keyEquivalent:@"" modifierMask:0 key:@"flipVertical"]];

        [DrawDocument addItems:items toMenu:[DrawDocument arrangeMenu]];
    }
    
    for (NSMenuItem *item in [_menuItems objectEnumerator]) {
        [item setHidden:NO];
    }
}

- (void)deactivate {
    for (NSMenuItem *item in [_menuItems objectEnumerator]) {
        [item setHidden:YES];
    }
}

#pragma mark - Actions

- (IBAction)flipVertical:(id)sender {
    NSSet *selection = [[DrawDocument focusedDocument] selection];
    NSRect frame;
    NSRect subframe;
    
    frame = DrawFrameForGraphics(selection);
    
    for (DrawGraphic *graphic in selection) {
        subframe = [graphic frame];
        subframe.origin.y = (frame.origin.y + frame.size.height) - (subframe.origin.y - frame.origin.y);
        subframe.size.height *= -1.0;
        [graphic setFrame:subframe];
    }
}

- (IBAction)flipHorizontal:(id)sender {
    NSSet *selection = [[DrawDocument focusedDocument] selection];
    NSRect frame;
    NSRect subframe;
    
    frame = DrawFrameForGraphics(selection);
    
    for (DrawGraphic *graphic in selection) {
        subframe = [graphic frame];
        subframe.origin.x = (frame.origin.x + frame.size.width) - (subframe.origin.x - frame.origin.x);
        subframe.size.width *= -1.0;
        [graphic setFrame:subframe];
    }
}

- (void)makeSquare:(id)sender {
    AJRPrintf(@"%@: %@%@\n", [self class], NSStringFromSelector(_cmd), sender);
}

- (void)snapToGrid:(id)sender {
    AJRPrintf(@"%@: %@%@\n", [self class], NSStringFromSelector(_cmd), sender);
}

- (void)editGraphic:(id)sender {
    NSSet *selection = [[DrawDocument focusedDocument] selection];

    for (DrawGraphic *graphic in selection) {
        [graphic setEditing:YES];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    DrawDocument *document = [DrawDocument focusedDocument];
    
    return [[document selection] count] != 0;
}

- (IBAction)bringForward:(id)sender {
    AJRPrintf(@"%@: %@%@\n", [self class], NSStringFromSelector(_cmd), sender);
}

- (IBAction)bringToFront:(id)sender {
    AJRPrintf(@"%@: %@%@\n", [self class], NSStringFromSelector(_cmd), sender);
}

- (IBAction)sendBackward:(id)sender {
    AJRPrintf(@"%@: %@%@\n", [self class], NSStringFromSelector(_cmd), sender);
}

- (IBAction)sendToBack:(id)sender {
    AJRPrintf(@"%@: %@%@\n", [self class], NSStringFromSelector(_cmd), sender);
}

@end
