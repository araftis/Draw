
#import "DrawLinkCapSquare.h"

#import "DrawLink.h"
#import "DrawLinkTool.h"

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

@implementation DrawLinkCapSquare

#pragma mark - DrawLinkCap

- (void)update {
   CGFloat angle;

   [self.path removeAllPoints];

   switch (self.capType) {
      case DrawLinkCapTypeHead:
         angle = [self.link angleInDegreesOfSourceSegment];
         [self.path moveToPoint:[self.link adjustedSourcePoint]];
         [self.path lineToAngle:angle - 90.0 length:self.thickness / 2.0];
         [self.path relativeLineToAngle:90.0 length:self.length];
         [self.path relativeLineToAngle:90.0 length:self.thickness];
         [self.path relativeLineToAngle:90.0 length:self.length];
         break;
      case DrawLinkCapTypeTail:
         angle = [self.link angleInDegreesOfDestinationSegment];
         [self.path moveToPoint:[self.link adjustedDestinationPoint]];
         [self.path lineToAngle:angle + 90.0 length:self.thickness / 2.0];
         [self.path relativeLineToAngle:90.0 length:self.length];
         [self.path relativeLineToAngle:90.0 length:self.thickness];
         [self.path relativeLineToAngle:90.0 length:self.length];
         break;
   }

   [self.path closePath];
}

+ (NSString *)ajr_nameForXMLArchiving {
    return @"linkCapSquare";
}

@end
