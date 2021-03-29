/*
DrawColorFill.m
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

#import "DrawColorFill.h"

#import "DrawDocument.h"
#import "DrawGraphic.h"

#import <AJRInterface/NSUserDefaults+Extensions.h>

NSString * const DrawColorFillIdentifier = @"DrawColorFillIdentifier";
NSString * const DrawFillColorKey = @"FillColor";

@implementation DrawColorFill

+ (void)initialize {
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     @{DrawFillColorKey:@"NSCalibratedRGBColorSpace 1 0.7 1 1"}];
}

#pragma mark - Creation

+ (DrawAspect *)defaultAspectForGraphic:(DrawGraphic *)graphic {
    return [[self alloc] initWithGraphic:graphic];
}

- (id)initWithGraphic:(DrawGraphic *)aGraphic {
    if ((self = [super initWithGraphic:aGraphic])) {
        _color = [[NSUserDefaults standardUserDefaults] colorForKey:DrawFillColorKey];
    }
    return self;
}

#pragma mark - Properties

@synthesize color = _color;

- (void)setColor:(NSColor *)color {
    if (_color != color) {
        _color = color;
        [self.graphic setNeedsDisplay];
    }
}

#pragma mark - DrawAspect

- (DrawGraphicCompletionBlock)drawPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    DrawGraphic	*focused = [self.graphic.document focusedGroup];
    
    if ([self.graphic isDescendantOf:focused]) {
        [_color set];
    } else {
        [[NSColor lightGrayColor] set];
    }
    [path setFlatness:[self.graphic flatness]];
    [path setWindingRule:self.windingRule];
    [path fill];
    
    return NULL;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    DrawColorFill	*aspect = [super copyWithZone:nil];
    
    aspect->_color = [_color copyWithZone:zone];
    
    return aspect;
}

#pragma mark - AJRXMLCoding

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super decodeWithXMLCoder:coder];

    [coder decodeObjectForKey:@"color" setter:^(id  _Nonnull object) {
        self->_color = object;
    }];
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)encoder {
    [super encodeWithXMLCoder:encoder];
    
    [encoder encodeObject:_color forKey:@"color"];
}

@end
