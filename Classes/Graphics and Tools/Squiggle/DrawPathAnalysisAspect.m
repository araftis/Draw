//
//  DrawPathAnalysisAspect.m
//  Draw
//
//  Created by Alex Raftis on 11/8/11.
//  Copyright (c) 2011 Apple, Inc. All rights reserved.
//

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
