/* DrawPenBezierAspect.m created by alex on Fri 23-Oct-1998 */

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
                case AJRBezierPathElementCurveTo:
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
