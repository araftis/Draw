/*
 DrawLinkCapCircle.m
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
