
#import "DrawLinkCapCircle.h"

#import "DrawLink.h"
#import "DrawLinkTool.h"

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

@implementation DrawLinkCapCircle

#pragma mark - DrawLinkCap

- (void)update {
    CGFloat angle = 0.0;
    NSPoint midpoint;
    
    [self.path removeAllPoints];
    
    switch (self.capType) {
        case DrawLinkCapTypeHead:
            angle = [self.link angleInDegreesOfSourceSegment];
            midpoint = AJRMidpointBetweenPoints([self.link adjustedSourcePoint], [self.link sourcePoint]);
            break;
        case DrawLinkCapTypeTail:
            angle = [self.link angleInDegreesOfDestinationSegment];
            midpoint = AJRMidpointBetweenPoints([self.link adjustedDestinationPoint], [self.link destinationPoint]);
            break;
    }
    
    [self.path appendBezierPathWithOvalInRect:(NSRect){{midpoint.x - (self.thickness / 2.0), midpoint.y - (self.length / 2.0)}, {self.thickness, self.length}}];
    [self.path rotateByDegrees:angle - 90.0 aroundPoint:midpoint];
    
    [self.path closePath];
}

+ (NSString *)ajr_nameForXMLArchiving {
    return @"linkCapCircle";
}

@end
