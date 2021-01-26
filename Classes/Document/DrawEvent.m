//
//  DrawEvent.m
//  Draw
//
//  Created by Alex Raftis on 7/1/11.
//  Copyright 2011 Apple, Inc. All rights reserved.
//

#import "DrawEvent.h"

#import "DrawDocument.h"
#import "DrawLayer.h"
#import "DrawPage.h"

@implementation DrawEvent

#pragma mark - Creation

+ (DrawEvent *)eventWithOriginalEvent:(NSEvent *)event document:(DrawDocument *)document page:(DrawPage *)page {
    DrawEvent *drawEvent = [[DrawEvent alloc] init];

    drawEvent->_event = event;
    drawEvent->_document = document;
    drawEvent->_page = page;

    return drawEvent;
}

#pragma mark - Properties

- (DrawLayer *)layer {
    return [_document layer];
}

#pragma mark - Utilities

- (NSPoint)locationOnPage {
    return [_page convertPoint:[_event locationInWindow] fromView:nil];
}

- (NSPoint)locationOnPageSnappedToGrid {
    return [_document snapPointToGrid:[self locationOnPage]];
}

- (NSString *)characters {
    return [_event characters];
}

- (NSUInteger)modifierFlags {
    return [_event modifierFlags];
}

- (NSUInteger)clickCount {
    return [_event clickCount];
}

- (BOOL)layerIsLockedOrNotVisible {
    DrawLayer *layer = [self layer];

    return [layer locked] || ![layer visible];
}

@end
