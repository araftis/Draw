/*
DrawLinkCapDoubleArrow.m
Draw

Copyright © 2021, AJ Raftis and AJRFoundation authors
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
