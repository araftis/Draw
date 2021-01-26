//
//  DrawShadow.h
//  Draw
//
//  Created by Alex Raftis on 8/31/11.
//  Copyright (c) 2011 Apple, Inc. All rights reserved.
//

#import <Draw/DrawAspect.h>

extern NSString * const DrawShadowIdentifier;

@interface DrawShadow : DrawAspect <AJRXMLCoding>

@property (strong) NSColor *color;
@property (assign) NSSize offset;
@property (assign) CGFloat blurRadius;

@end
