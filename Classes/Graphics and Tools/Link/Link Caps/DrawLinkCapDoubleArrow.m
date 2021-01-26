/* DrawLinkCapDoubleArrow.m created by alex on Thu 18-Feb-1999 */

#import "DrawLinkCapDoubleArrow.h"

#import "DrawLink.h"
#import "DrawLinkTool.h"

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

@implementation DrawLinkCapDoubleArrow

#pragma mark - DrawLinkTool

- (void)update {
    CGFloat angle = 0.0;
    NSAffineTransform *transform;
    NSPoint point;
    CGFloat l1, l2;

    l1 = self.length * self.divit;
    l2 = self.length * (1.0 - self.divit);

    [self.path removeAllPoints];

    switch (self.capType) {
        case DrawLinkCapTypeHead:
            angle = [self.link angleInDegreesOfSourceSegment] + 90.0;
            point = [self.link adjustedSourcePoint];
            break;
        case DrawLinkCapTypeTail:
            angle = [self.link angleInDegreesOfDestinationSegment] - 90.0;
            point = [self.link adjustedDestinationPoint];
            break;
    }

    [self.path moveToPoint:(NSPoint){0.0, 0.0}];
    [self.path lineToPoint:(NSPoint){self.thickness / 2.0, -l1}];
    [self.path lineToPoint:(NSPoint){0.0, l2}];
    [self.path lineToPoint:(NSPoint){self.thickness / 2.0, l2 - l1}];
    [self.path lineToPoint:(NSPoint){0.0, l2 + self.length}];
    [self.path lineToPoint:(NSPoint){-self.thickness / 2.0, l2 - l1}];
    [self.path lineToPoint:(NSPoint){0.0, l2}];
    [self.path lineToPoint:(NSPoint){-self.thickness / 2.0, -l1}];

    [self.path closePath];

    transform = [[NSAffineTransform alloc] init];
    [transform rotateByDegrees:angle];
    [self.path transformUsingAffineTransform:transform];
    transform = [[NSAffineTransform alloc] init];
    [transform translateXBy:point.x yBy:point.y];
    [self.path transformUsingAffineTransform:transform];
}

- (NSPoint)initialPointFromPoint:(NSPoint)originalPoint {
    CGFloat angle = 0.0;
    CGFloat tLength = (self.length * (1.0 - self.divit)) + self.length;

    switch (self.capType) {
        case DrawLinkCapTypeHead:
            angle = [self.link angleInDegreesOfSourceSegment];
            break;
        case DrawLinkCapTypeTail:
            angle = [self.link angleInDegreesOfDestinationSegment] + 180.0;
            break;
    }

    return (NSPoint){originalPoint.x + AJRCos(angle) * tLength, originalPoint.y + AJRSin(angle) * tLength};
}

+ (NSString *)ajr_nameForXMLArchiving {
    return @"linkCapDoubleArrow";
}

@end
