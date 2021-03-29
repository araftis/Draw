
#import "DrawLinkCapArrow.h"

#import "DrawLink.h"
#import "DrawLinkTool.h"

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

@implementation DrawLinkCapArrow

#pragma mark - Creation

- (id)initWithType:(DrawLinkCapType)type {
    if ((self = [super initWithType:type])) {
        self.divit = 0.2;
    }
    return self;
}

#pragma mark - DrawLink

- (void)update {
    CGFloat angle = 0.0;
    NSAffineTransform *transform;
    NSPoint point;

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
    [self.path lineToPoint:(NSPoint){self.thickness / 2.0, -self.length * self.divit}];
    [self.path lineToPoint:(NSPoint){0.0, self.length * (1.0 - self.divit)}];
    [self.path lineToPoint:(NSPoint){-self.thickness / 2.0, -self.length * self.divit}];
    [self.path closePath];

    transform = [[NSAffineTransform alloc] init];
    [transform rotateByDegrees:angle];
    [self.path transformUsingAffineTransform:transform];
    transform = [[NSAffineTransform alloc] init];
    [transform translateXBy:point.x yBy:point.y];
    [self.path transformUsingAffineTransform:transform];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)aZone {
    DrawLinkCapArrow *new = [super copyWithZone:aZone];

    new->_divit = _divit;

    return new;
}

#pragma mark - NSCoding

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super decodeWithXMLCoder:coder];
    [coder decodeFloatForKey:@"divit" setter:^(float value) {
        self->_divit = value;
    }];
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super encodeWithXMLCoder:coder];
    [coder encodeFloat:_divit forKey:@"divit"];
}

+ (NSString *)ajr_nameForXMLArchiving {
    return @"linkCapArrow";
}

@end
