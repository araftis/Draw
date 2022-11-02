/*
 AJRBezierPath-DrawExtensions.m
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

#import "AJRBezierPath-DrawExtensions.h"

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

@implementation AJRBezierPath (DrawExtensions)

- (BOOL)_isPoint:(NSPoint)point inPoint:(NSPoint)inPoint error:(CGFloat)error {
    return ((point.x >= (inPoint.x - error)) && (point.x <= (inPoint.x + error)) &&
            (point.y >= (inPoint.y - error)) && (point.y <= (inPoint.y + error)));
}

- (DrawHandle)drawHandleForPoint:(NSPoint)aPoint error:(CGFloat)error {
    NSInteger pointIndex;
    DrawHandle handle;
    BOOL found = NO;

    handle.type = DrawHandleTypeMissed;
    handle.subindex = 0;

    for (NSInteger x = 1; (x < _elementCount) && !found; x++) {

        pointIndex = _elementToPointIndex[x];

        switch (_elements[x]) {
            case AJRBezierPathElementMoveTo:
                if ([self _isPoint:aPoint inPoint:_points[pointIndex] error:error]) {
                    found = YES;
                    handle.type = DrawHandleTypeIndexed;
                    handle.elementIndex = x - 1;
                }
                break;
            case AJRBezierPathElementLineTo:
                if ([self _isPoint:aPoint inPoint:_points[pointIndex] error:error]) {
                    found = YES;
                    handle.type = DrawHandleTypeIndexed;
                    handle.elementIndex = x - 1;
                }
                break;
            case AJRBezierPathElementCurveTo:
                if ([self _isPoint:aPoint inPoint:_points[pointIndex] error:error]) {
                    found = YES;
                    handle.type = DrawHandleTypeIndexed;
                    handle.elementIndex = x - 1;
                    handle.subindex = 0;
                }
                if ([self _isPoint:aPoint inPoint:_points[pointIndex + 1] error:error]) {
                    found = YES;
                    handle.type = DrawHandleTypeIndexed;
                    handle.elementIndex = x - 1;
                    handle.subindex = 1;
                }
                if ([self _isPoint:aPoint inPoint:_points[pointIndex + 2] error:error]) {
                    found = YES;
                    handle.type = DrawHandleTypeIndexed;
                    handle.elementIndex = x - 1;
                    handle.subindex = 2;
                }
                break;
            default:
                break;
        }
    }

    return handle;
}

- (CGFloat)_angleInDegreesForLine:(AJRLine)line {
    return AJRArctan(line.start.y - line.end.y, line.start.x - line.end.x);
}

- (CGFloat)angleInDegreesOfInitialLineSegment {
    AJRLine		line;

    line.start = _points[2];
    line.end = _points[3];

    return [self _angleInDegreesForLine:line];
}

- (CGFloat)angleInDegreesOfTerminatingLineSegment {
    AJRLine		line;

    line.start = _points[_elementToPointIndex[_elementCount - 1]];
    line.end = _points[_elementToPointIndex[_elementCount - 2]];

    return [self _angleInDegreesForLine:line];
}

@end
