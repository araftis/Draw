/*
 DrawPenBezierAspect.m
 Draw

 Copyright © 2022, AJ Raftis and Draw authors
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

#import "DrawPenBezierAspect.h"

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

NSString *DrawPenBezierAspectKey = @"DrawPenBezierAspectKey";

@implementation DrawPenBezierAspect

- (DrawGraphicCompletionBlock)drawPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    NSInteger operation;
    NSPoint points[3];
    NSPoint previous = (NSPoint){0.0, 0.0};
    AJRBezierPath *workPath;

    workPath = [[AJRBezierPath alloc] init];
    [workPath setLineWidth:AJRHairLineWidth];

    if ([self.graphic editing]) {
        [[NSColor lightGrayColor] set];

        for (operation = 0; operation < (const NSInteger)[path elementCount]; operation++) {
            switch ([path elementAtIndex:operation associatedPoints:points]) {
                case AJRBezierPathElementMoveTo:
                case AJRBezierPathElementLineTo:
                    previous = points[0];
                    break;
                case AJRBezierPathElementCubicCurveTo:
                    [workPath removeAllPoints];
                    [workPath moveToPoint:previous];
                    [workPath lineToPoint:points[0]];
                    [workPath moveToPoint:points[1]];
                    [workPath lineToPoint:points[2]];
                    [workPath stroke];
                    previous = points[2];
                    break;
                default:
                    break;
            }
        }
    }

    return NULL;
}

- (BOOL)isPoint:(NSPoint)aPoint inPath:(AJRBezierPath *)path {
    return NO;
}

#pragma mark - AJRXMLCoding

+ (NSString *)ajr_nameForXMLArchiving {
    return @"penBezierAspect";
}

@end
