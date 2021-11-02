/*
DrawFill.m
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

#import "DrawFill.h"

#import "DrawFunctions.h"
#import "DrawDocument.h"

#import <AJRInterface/AJRInterface.h>

NSString * const DrawFillIdentifier = @"fill";
NSString * const DrawFillWindingRuleKey = @"DrawFillWindingRuleKey";

@implementation DrawFill

- (id)initWithGraphic:(DrawGraphic *)aGraphic {
    if ((self = [super initWithGraphic:aGraphic])) {
        _windingRule = (AJRWindingRule)[[NSUserDefaults standardUserDefaults] integerForKey:DrawFillWindingRuleKey];
    }
    return self;
}

#pragma mark - DrawAspect

- (BOOL)isPoint:(NSPoint)aPoint inPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority; {
    [path setFlatness:self.graphic.flatness];
    [path setWindingRule:_windingRule];
    return [path isHitByPoint:aPoint];
}

- (id)copyWithZone:(NSZone *)zone {
    DrawFill *aspect = [super copyWithZone:nil];

    aspect->_windingRule = _windingRule;

    return aspect;
}

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super decodeWithXMLCoder:coder];

    [coder decodeIntegerForKey:@"windingRule" setter:^(NSInteger value) {
        self->_windingRule = value;
    }];
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)encoder {
    [super encodeWithXMLCoder:encoder];

    [encoder encodeInteger:_windingRule forKey:@"windingRule"];
}

@end
