//
//  DrawShadow.m
//  Draw
//
//  Created by Alex Raftis on 8/31/11.
//  Copyright (c) 2011 Apple, Inc. All rights reserved.
//

#import "DrawShadow.h"

#import "DrawGraphic.h"

NSString * const DrawShadowIdentifier = @"shadow";

@implementation DrawShadow {
    NSShadow *_shadow;
}

#pragma mark - Creation

- (id)initWithGraphic:(DrawGraphic *)graphic {
    if ((self = [super initWithGraphic:graphic])) {
        _shadow = [[NSShadow alloc] init];
        [_shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0/4.0]];
        [_shadow setShadowOffset:(NSSize){0.0, -4.0}];
        [_shadow setShadowBlurRadius:10.0];
    }
    return self;
}

#pragma mark - Properties

- (void)setColor:(NSColor *)color {
    [_shadow setShadowColor:color];
    [self.graphic setNeedsDisplay];
}

- (NSColor *)color {
    return [_shadow shadowColor];
}

- (void)setOffset:(NSSize)offset {
    [_shadow setShadowOffset:offset];
    [self.graphic setNeedsDisplay];
}

- (NSSize)offset {
    return [_shadow shadowOffset];
}

- (void)setBlurRadius:(CGFloat)blurRadius {
    [_shadow setShadowBlurRadius:blurRadius];
    [self.graphic setNeedsDisplay];
}

- (CGFloat)blurRadius {
    return [_shadow shadowBlurRadius];
}

#pragma mark - DrawAspect

- (DrawGraphicCompletionBlock)drawPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    CGContextSaveGState([[NSGraphicsContext currentContext] CGContext]);
    [_shadow set];
    CGContextBeginTransparencyLayerWithRect([[NSGraphicsContext currentContext] CGContext], [self.graphic dirtyBounds], NULL);
    return ^() {
        CGContextEndTransparencyLayer([[NSGraphicsContext currentContext] CGContext]);
        CGContextRestoreGState([[NSGraphicsContext currentContext] CGContext]);
    };
}

- (NSRect)boundsForGraphicBounds:(NSRect)graphicBounds {
    NSRect	bounds = graphicBounds;

    bounds = NSInsetRect(bounds, -([_shadow shadowBlurRadius] + 2.0), -([_shadow shadowBlurRadius] + 2.0));
    bounds.origin.x += [_shadow shadowOffset].width;
    bounds.origin.y += [_shadow shadowOffset].height;

    return NSUnionRect(graphicBounds, bounds);
}

- (BOOL)boundsExpandsGraphicBounds {
    return YES;
}

+ (DrawAspect *)defaultAspectForGraphic:(DrawGraphic *)graphic {
    return [[self alloc] initWithGraphic:graphic];
}

#pragma mark - AJRXMLCoding

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super decodeWithXMLCoder:coder];

    [coder decodeObjectForKey:@"shadow" setter:^(id  _Nonnull object) {
        self->_shadow = object;
    }];
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super encodeWithXMLCoder:coder];

    [coder encodeObject:_shadow forKey:@"shadow"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    DrawShadow	*new = [super copyWithZone:zone];

    new->_shadow = [_shadow copyWithZone:zone];

    return new;
}

@end
