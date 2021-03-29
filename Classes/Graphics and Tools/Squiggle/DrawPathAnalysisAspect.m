/*
DrawPathAnalysisAspect.m
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

#import "DrawPathAnalysisAspect.h"

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>
#import <AJRInterface/AJRInterface.h>

NSString * const DrawPathAnalysisIdentifier = @"pathAnalysis";

@implementation DrawPathAnalysisAspect

#pragma mark - Creation

- (id)initWithGraphic:(DrawGraphic *)aGraphic {
    if ((self = [super initWithGraphic:aGraphic])) {
        _analyzer = [[AJRPathAnalyzer alloc] initWithPath:[aGraphic path]];
    }
    return self;
}

#pragma mark - DrawAspect

- (DrawGraphicCompletionBlock)drawPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    CGFloat scale = [NSAffineTransform currentScale];
    AJRBezierPath *thickPath = [[AJRBezierPath alloc] init];
    AJRBezierPath *thinPath = [[AJRBezierPath alloc] init];
    NSPoint previousPoint;

    for (AJRPathAnalysisContour *contour in [_analyzer contours]) {
        BOOL first = YES;
        for (AJRPathAnalysisCorner *corner in [contour corners]) {
            if (first) {
                previousPoint = [corner point];
                first = NO;
            } else {
                [thickPath moveToPoint:previousPoint];
                [thickPath lineToPoint:[corner point]];
                previousPoint = [corner point];
            }
        }
    }

    [[NSColor blueColor] set];
    [thickPath setLineWidth:4.0 / scale];
    [thickPath stroke];

    [[NSColor purpleColor] set];
    [thinPath setLineWidth:1.0 / scale];
    [thinPath stroke];
    
    return NULL;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    DrawPathAnalysisAspect	*aspect = [super copyWithZone:nil];

    aspect->_analyzer = [[AJRPathAnalyzer alloc] initWithPath:[_analyzer path]];

    return aspect;
}

#pragma mark - NSCoding

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super decodeWithXMLCoder:coder];
    [coder decodeObjectForKey:@"width" setter:^(id  _Nonnull object) {
        self->_analyzer = object;
    }];
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)encoder {
    [super encodeWithXMLCoder:encoder];

    [encoder encodeObject:_analyzer forKey:@"width"];
}

@end
