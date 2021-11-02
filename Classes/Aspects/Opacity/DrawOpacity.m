/*
DrawOpacity.m
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

#import "DrawOpacity.h"

@implementation DrawOpacity

NSString * const DrawOpacityIdentifier = @"opacity";

#pragma mark - Creation

- (id)initWithGraphic:(DrawGraphic *)graphic {
    if ((self = [super initWithGraphic:graphic])) {
        _opacity = 1.0;
    }
    return self;
}

#pragma mark - Properties

- (void)setOpacity:(CGFloat)opacity {
    if (opacity != _opacity) {
        _opacity = opacity;
        [self.graphic setNeedsDisplay];
    }
}

#pragma mark - DrawAspect

- (BOOL)rendersToCanvas {
    return NO;
}

- (DrawGraphicCompletionBlock)drawPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    CGContextSetAlpha([[NSGraphicsContext currentContext] CGContext], _opacity);
    CGContextBeginTransparencyLayerWithRect([[NSGraphicsContext currentContext] CGContext], [self.graphic dirtyBounds], NULL);
    return ^() {
        CGContextEndTransparencyLayer([[NSGraphicsContext currentContext] CGContext]);
    };
}

+ (DrawAspect *)defaultAspectForGraphic:(DrawGraphic *)graphic {
    return [[self alloc] initWithGraphic:graphic];
}

#pragma mark - NSCoding

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super decodeWithXMLCoder:coder];

    [coder decodeFloatForKey:@"opacity" setter:^(float value) {
        self->_opacity = value;
    }];
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super encodeWithXMLCoder:coder];
    
    [coder encodeFloat:_opacity forKey:@"opacity"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    DrawOpacity *new = [super copyWithZone:zone];
    
    new->_opacity = _opacity;
    
    return new;
}

@end
