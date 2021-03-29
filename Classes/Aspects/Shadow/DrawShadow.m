/*
DrawShadow.m
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
