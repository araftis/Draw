//
//  DrawOpacity.h
//  Draw
//
//  Created by Alex Raftis on 9/8/11.
//  Copyright (c) 2011 Apple, Inc. All rights reserved.
//

#import <Draw/DrawAspect.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const DrawOpacityIdentifier;

@interface DrawOpacity : DrawAspect <AJRXMLCoding>

@property (nonatomic,assign) CGFloat opacity;

@end

NS_ASSUME_NONNULL_END
