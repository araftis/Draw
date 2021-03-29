
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
