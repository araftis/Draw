/* DrawLinkCapDiamond.m created by alex on Thu 18-Feb-1999 */

#import "DrawLinkCapDiamond.h"

#import "DrawLink.h"
#import "DrawLinkTool.h"

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

@implementation DrawLinkCapDiamond

#pragma mark - DrawLinkCap

- (void)update {
   CGFloat angle;
   CGFloat edgeLength;
   CGFloat halfLength = self.length / 2.0, halfThickness = self.thickness / 2.0;
   CGFloat leAngle;
   CGFloat teAngle;

   [self.path removeAllPoints];

   edgeLength = sqrt((halfLength * halfLength) + (halfThickness * halfThickness));

   leAngle = AJRArccos(halfLength / edgeLength) * 2.0;
   teAngle = AJRArccos(halfThickness / edgeLength) * 2.0;
   
   switch (self.capType) {
      case DrawLinkCapTypeHead:
         angle = [self.link angleInDegreesOfSourceSegment];
         [self.path moveToPoint:[self.link adjustedSourcePoint]];
         [self.path lineToAngle:angle - 90.0 - (leAngle / 2.0) length:edgeLength];
         [self.path relativeLineToAngle:teAngle length:edgeLength];
         [self.path relativeLineToAngle:leAngle length:edgeLength];
         [self.path relativeLineToAngle:teAngle length:edgeLength];
         break;
      case DrawLinkCapTypeTail:
         angle = [self.link angleInDegreesOfDestinationSegment];
         [self.path moveToPoint:[self.link adjustedDestinationPoint]];
         [self.path lineToAngle:angle + (leAngle / 2.0) length:edgeLength];
         [self.path relativeLineToAngle:teAngle length:edgeLength];
         [self.path relativeLineToAngle:leAngle length:edgeLength];
         [self.path relativeLineToAngle:teAngle length:edgeLength];
         break;
   }

   [self.path closePath];
}

+ (NSString *)ajr_nameForXMLArchiving {
    return @"linkCapDiamond";
}

@end
