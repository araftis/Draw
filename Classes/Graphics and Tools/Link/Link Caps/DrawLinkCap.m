/*
 DrawLinkCap.m
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

#import "DrawLinkCap.h"

#import "DrawDocument.h"
#import "DrawLink.h"
#import <Draw/Draw-Swift.h>

#import "AJRBezierPath-DrawExtensions.h"

#import <AJRInterface/AJRInterface.h>

NSString *DrawLinkCapHeadStyleKey = @"DrawLinkCapHeadStyleKey";
NSString *DrawLinkCapHeadThicknessKey = @"DrawLinkCapHeadThicknessKey";
NSString *DrawLinkCapHeadLengthKey = @"DrawLinkCapHeadLengthKey";
NSString *DrawLinkCapHeadFilledKey = @"DrawLinkCapHeadFilled";
NSString *DrawLinkCapTailStyleKey = @"DrawLinkCapTailStyleKey";
NSString *DrawLinkCapTailThicknessKey = @"DrawLinkCapTailThicknessKey";
NSString *DrawLinkCapTailLengthKey = @"DrawLinkCapTailLengthKey";
NSString *DrawLinkCapTailFilledKey = @"DrawLinkCapTailFilled";

@interface _DrawLinkFakeGraphic : DrawLink

- (id)initWithSize:(NSSize)size filled:(BOOL)flag;

@end

@implementation _DrawLinkFakeGraphic

- (id)initWithSize:(NSSize)size filled:(BOOL)flag {
    if ((self = [super initWithSource:nil])) {
        _path = [[AJRBezierPath alloc] init];
        [_path moveToPoint:(NSPoint){1.0, size.height / 2.0}];
        [_path lineToPoint:(NSPoint){size.width - 1.0, size.height / 2.0}];

        [self removeAllAspects];

        if (flag) {
            DrawFill *fill = [[DrawFill alloc] initWithGraphic:self color:NSColor.blackColor];
            [self addAspect:fill withPriority:DrawAspectPriorityBackground];
        }

        DrawStroke *stroke = [[DrawStroke alloc] initWithGraphic:self];
        [stroke setLineJoin:AJRLineJoinStyleMitered];
        [stroke setLineCap:AJRLineCapStyleButt];
        [stroke setWidth:1.0];
        [stroke setColor:[NSColor blackColor]];
        [self addAspect:stroke withPriority:DrawAspectPriorityForeground];
    }
    return self;
}

+ (NSString *)ajr_nameForXMLArchiving {
    return @"_fake";
}

@end

@implementation DrawLinkCap

+ (void)initialize {
    [NSUserDefaults.standardUserDefaults registerDefaults:@{DrawLinkCapHeadThicknessKey:@"10.0",
                                                            DrawLinkCapHeadLengthKey:@"10.0",
                                                            DrawLinkCapHeadFilledKey:@(YES),
                                                            DrawLinkCapTailThicknessKey:@"10.0",
                                                            DrawLinkCapTailLengthKey:@"10.0",
                                                            DrawLinkCapTailFilledKey:@(YES)}];
}

#pragma mark - Creation

- (id)init {
    if ((self = [super init])) {
        _path = [[AJRBezierPath alloc] init];
        _thickness = 10.0;
        _length = 10.0;
        _filled = YES;
    }
    return self;
}

- (id)initWithType:(DrawLinkCapType)type {
    if ((self = [super init])) {
        _thickness = [NSUserDefaults.standardUserDefaults doubleForKey:type == DrawLinkCapTypeHead ? DrawLinkCapHeadThicknessKey : DrawLinkCapTailThicknessKey];
        _length = [NSUserDefaults.standardUserDefaults doubleForKey:type == DrawLinkCapTypeHead ? DrawLinkCapHeadLengthKey : DrawLinkCapTailLengthKey];
        _path = [[AJRBezierPath alloc] init];
        _filled = [NSUserDefaults.standardUserDefaults boolForKey:type == DrawLinkCapTypeHead ? DrawLinkCapHeadFilledKey : DrawLinkCapTailFilledKey];
    }
    return self;
}

#pragma mark - Properties

- (void)setThickness:(CGFloat)thickness {
    if (_thickness != thickness) {
        [(DrawLinkCap *)[[_link document] prepareWithInvocationTarget:self] setThickness:_thickness];

        _thickness = thickness;

        if (_capType == DrawLinkCapTypeHead) {
            [_link updateSourcePoint];
        } else {
            [_link updateDestinationPoint];
        }
        [_link setNeedsDisplay];
    }
}

- (void)setLength:(CGFloat)length {
    if (_length != length) {
        [(DrawLinkCap *)[[_link document] prepareWithInvocationTarget:self] setLength:_length];

        _length = length;

        if (_capType == DrawLinkCapTypeHead) {
            [_link updateSourcePoint];
        } else {
            [_link updateDestinationPoint];
        }
        [_link setNeedsDisplay];
    }
}

- (void)setFilled:(BOOL)filled {
    if (filled != _filled) {
        _filled = filled;
        [_link setNeedsDisplay];
    }
}

#pragma mark - Notifications

- (void)graphicDidChangeShape:(DrawGraphic *)aGraphic {
}

- (void)linkCapWillAddToLink:(DrawLink *)link asType:(DrawLinkCapType)type {
    _link = link;
    _capType = type;
}

- (void)linkCapDidAddToLink:(DrawLink *)aLink asType:(DrawLinkCapType)type {
}

- (void)linkCapWillRemoveFromLink:(DrawLink *)link {
    _link = nil;
}

- (void)linkCapDidRemoveFromLink:(DrawLink *)link {
}

#pragma mark - Geometry

- (NSPoint)initialPointFromPoint:(NSPoint)originalPoint {
    CGFloat angle = 0.0;

    switch (_capType) {
        case DrawLinkCapTypeHead:
            angle = [_link angleInDegreesOfSourceSegment];
            break;
        case DrawLinkCapTypeTail:
            angle = [_link angleInDegreesOfDestinationSegment] + 180.0;
            break;
    }

    return (NSPoint){originalPoint.x + (AJRCos(angle) * _length), originalPoint.y + (AJRSin(angle) * _length)};
}

- (void)update {
    NSPoint point;

    switch (_capType) {
        case DrawLinkCapTypeHead:
            point = [_link sourcePoint];
            break;
        case DrawLinkCapTypeTail:
            point = [_link destinationPoint];
            break;
    }

    [_path removeAllPoints];
    [_path appendBezierPathWithOvalInRect:(NSRect){{point.x - _thickness / 2.0, point.y - _thickness / 2.0}, {_thickness * 2.0, _thickness * 2.0}}];
    [_path closePath];
}

#pragma mark - Inspector Utilities

static NSSize imageSize = (NSSize){25.0, 9.0};
static CGFloat capThickness = 6.0;
static CGFloat capLength = 6.0;

+ (NSImage *)sourceImageFilled:(BOOL)flag {
    static NSMutableDictionary *headImages = nil;
    static NSMutableDictionary *images = nil;
    NSImage *headImage = nil;

    if (headImages == nil) {
        headImages = [[NSMutableDictionary alloc] init];
    }
    images = [headImages objectForKey:flag ? @"filled" : @"stroked"];
    if (images == nil) {
        images = [[NSMutableDictionary alloc] init];
        [headImages setObject:images forKey:flag ? @"filled" : @"stroked"];
    }

    headImage = [images objectForKey:self];
    if (headImage == nil) {
        DrawLinkCap *cap = [[self alloc] init];
        _DrawLinkFakeGraphic *fake = [[_DrawLinkFakeGraphic alloc] initWithSize:imageSize filled:flag];

        [cap setLength:capLength];
        [cap setThickness:capThickness];
        [fake setSourceCap:cap];
        [fake setDestinationCap:nil];

        headImage = [[NSImage alloc] initWithSize:imageSize];
        //[headImage setFlipped:YES];
        [headImage lockFocus];
        [headImage ajr_flipCoordinateSystem];
        [fake draw];
        [headImage unlockFocus];

        [headImage setTemplate:YES];

        [cap linkCapWillRemoveFromLink:(id)fake];
        [cap linkCapDidRemoveFromLink:(id)fake];

        [images setObject:headImage forKey:(id)self];
    }

    return headImage;
}

+ (NSImage *)destinationImageFilled:(BOOL)flag {
    static NSMutableDictionary *tailImages = nil;
    static NSMutableDictionary *images = nil;
    NSImage *tailImage = nil;

    if (tailImages == nil) {
        tailImages = [[NSMutableDictionary alloc] init];
    }
    images = [tailImages objectForKey:flag ? @"filled" : @"stroked"];
    if (images == nil) {
        images = [[NSMutableDictionary alloc] init];
        [tailImages setObject:images forKey:flag ? @"filled" : @"stroked"];
    }

    tailImage = [images objectForKey:self];
    if (tailImage == nil) {
        DrawLinkCap *cap = [[self alloc] init];
        _DrawLinkFakeGraphic *fake = [[_DrawLinkFakeGraphic alloc] initWithSize:imageSize filled:flag];

        [cap setLength:capLength];
        [cap setThickness:capThickness];
        [fake setSourceCap:nil];
        [fake setDestinationCap:cap];

        tailImage = [[NSImage alloc] initWithSize:imageSize];
        //[tailImage setFlipped:YES];
        [tailImage lockFocus];
        [tailImage ajr_flipCoordinateSystem];
        [fake draw];
        [tailImage unlockFocus];

        [tailImage setTemplate:YES];

        [cap linkCapWillRemoveFromLink:(id)fake];
        [cap linkCapDidRemoveFromLink:(id)fake];

        [images setObject:tailImage forKey:(id)self];
    }

    return tailImage;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)aZone {
    DrawLinkCap *new = [[self class] allocWithZone:nil];

    new->_path = [_path copyWithZone:aZone];
    new->_link = _link;
    new->_thickness = _thickness;
    new->_length = _length;
    new->_capType = _capType;

    return new;
}

#pragma mark - NSCoding

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [coder decodeObjectForKey:@"link" setter:^(id  _Nonnull object) {
        self->_link = object;
    }];
    [coder decodeFloatForKey:@"thickness" setter:^(float value) {
        self->_thickness = value;
    }];
    [coder decodeFloatForKey:@"length" setter:^(float value) {
        self->_length =  value;
    }];
    [coder decodeStringForKey:@"capType" setter:^(NSString *value) {
        self->_capType = DrawLinkCapTypeFromString(value);
    }];
    [coder decodeBoolForKey:@"filled" setter:^(BOOL value) {
        self->_filled = value;
    }];
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)coder {
    [coder encodeObjectIfNotNil:_link forKey:@"link"];
    [coder encodeFloat:_thickness forKey:@"thickness"];
    [coder encodeFloat:_length forKey:@"length"];
    [coder encodeBool:_filled forKey:@"filled"];
    [coder encodeString:DrawStringFromLinkCapType(_capType) forKey:@"capType"];
}

#pragma mark - NSComparison

- (BOOL)isEqualToLinkCap:(DrawLinkCap *)other {
    return (self.class == other.class
            && AJREqual(_path, other->_path)
            //&& AJREqual(_link, other->_link) // Causes infinite recursion if compared.
            && _thickness == other->_thickness
            && _length == other->_length
            && _capType == other->_capType);

}

- (BOOL)isEqual:(id)other {
    return self == other || ([other isKindOfClass:DrawLinkCap.class] && [self isEqualToLinkCap:other]);
}

+ (NSComparisonResult)compare:(id)other {
    return [NSStringFromClass([self class]) compare:NSStringFromClass([other class])];
}

@end

NSString *DrawStringFromLinkCapType(DrawLinkCapType type) {
    switch (type) {
        case DrawLinkCapTypeHead:
            return @"head";
        case DrawLinkCapTypeTail:
            return @"tail";
    }
    return @"tail";
}

DrawLinkCapType DrawLinkCapTypeFromString(NSString *string) {
    if ([string isEqualToString:@"head"]) {
        return DrawLinkCapTypeHead;
    }
    if ([string isEqualToString:@"tail"]) {
        return DrawLinkCapTypeTail;
    }
    return DrawLinkCapTypeTail;
}
