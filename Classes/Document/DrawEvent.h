//
//  DrawEvent.h
//  Draw
//
//  Created by Alex Raftis on 7/1/11.
//  Copyright 2011 Apple, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DrawDocument, DrawLayer, DrawPage;

NS_ASSUME_NONNULL_BEGIN

@interface DrawEvent : NSObject

+ (DrawEvent *)eventWithOriginalEvent:(NSEvent *)event document:(DrawDocument *)document page:(DrawPage *)page;

@property (nonatomic,readonly) NSEvent *event;
@property (nonatomic,readonly) DrawDocument *document;
@property (nonatomic,readonly) DrawPage *page;
@property (nonatomic,readonly) DrawLayer *layer;

- (NSPoint)locationOnPage;
- (NSPoint)locationOnPageSnappedToGrid;
- (NSString *)characters;
- (NSUInteger)modifierFlags;
- (NSUInteger)clickCount;

- (BOOL)layerIsLockedOrNotVisible;

@end

NS_ASSUME_NONNULL_END
