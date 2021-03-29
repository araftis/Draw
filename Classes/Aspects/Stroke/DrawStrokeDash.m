/*
DrawStrokeDash.m
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

#import "DrawStrokeDash.h"

#import "DrawStroke.h"
#import "DrawDocument.h"

#import <AJRInterface/AJRInterface.h>

@implementation DrawStrokeDash {
    CGFloat *_dash;
    NSImage *_image;
}

+ (NSArray *)defaultDashes {
    static NSMutableArray *dashes;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        NSArray		*prefDashes;
        NSInteger	x;

        dashes = [[NSMutableArray alloc] init];

        prefDashes = [[NSUserDefaults standardUserDefaults] arrayForKey:DrawStrokeDashesKey];
        for (x = 0; x < (const NSInteger)[prefDashes count]; x++) {
            [dashes addObject:[[DrawStrokeDash alloc] initWithString:[prefDashes objectAtIndex:x]]];
        }
    });

    return dashes;
}

#pragma mark - Creation

- (id)initWithString:(NSString *)string {
    if ((self = [super init])) {
        _dash = NULL;
        _count = 0;

        [self setStringValue:string];
    }

    return self;
}

#pragma mark - Destruction

- (void)dealloc {
    NSZoneFree(NULL, _dash);
}

#pragma mark - Utilities

- (NSNumberFormatter *)formatter {
    static NSNumberFormatter *formatter;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        formatter = [[NSNumberFormatter alloc] init];
        [formatter setPositiveFormat:@"###0.######"];
        [formatter setNegativeFormat:@"###0.######"];
    });

    return formatter;
}

- (void)addToPath:(AJRBezierPath *)path; {
    if (_dash == NULL) {
        [path setLineDash:NULL count:0 phase:0];
    } else {
        CGFloat	*dash = NSZoneCalloc(NULL, _count, sizeof(CGFloat));
        CGFloat width = [path lineWidth];
        for (NSInteger x = 0; x < _count; x++) {
            dash[x] = _dash[x] * width;
        }
        [path setLineDash:dash count:_count phase:_offset * width];
        NSZoneFree(NULL, dash);
    }
}

- (void)setStringValue:(NSString *)string {
    NSArray *parts;
    NSString *part;
    NSInteger x;
    NSInteger shrink = 0;

    if (_dash != NULL) {
        NSZoneFree(NULL, _dash);
        _dash = NULL;
        _count = 0;
    }
    if (string == nil) return;

    parts = [string componentsSeparatedByString:@" "];
    _count = [parts count];
    _dash = NSZoneMalloc(NULL, _count * sizeof(CGFloat));
    for (x = 0; x < _count; x++) {
        part = [parts objectAtIndex:x];
        if ([part length]) {
            _dash[x] = [[parts objectAtIndex:x] floatValue];
        } else {
            shrink++;
        }
    }
    if (shrink != 0) {
        _count -= shrink;
        _dash = NSZoneRealloc(NULL, _dash, _count * sizeof(CGFloat));
    }
}

- (NSString *)stringValue {
    NSMutableString *string = nil;
    NSInteger x;
    NSNumberFormatter *formatter = [self formatter];

    for (x = 0; x < _count; x++) {
        if (x == 0) {
            string = [NSMutableString string];
        } else {
            [string appendString:@" "];
        }
        [string appendString:[formatter stringFromNumber:[NSNumber numberWithFloat:_dash[x]]]];
    }
    
    if (!string) return @"";
    
    return string;
}

- (NSString *)description {
    return [self stringValue];
}

- (NSImage *)image {
    if (!_image) {
        AJRBezierPath *path;
        NSAffineTransform *transform;
        NSShadow *shadow;
        
        shadow = [[NSShadow alloc] init];
        [shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:2.0/3.0]];
        [shadow setShadowBlurRadius:3.0];
        [shadow setShadowOffset:(NSSize){0.0, -1.5}];

        _image = [[NSImage alloc] initWithSize:(NSSize){90.0, 9.0}];
        [_image lockFocus];
        [shadow set];
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.0] set];
        NSRectFill((NSRect){{0.0, 0.0}, {90.0, 90.0}});
        [[NSColor blackColor] set];
        transform = [[NSAffineTransform alloc] init];
        [transform scaleBy:3.0];
        [transform concat];
        path = [[AJRBezierPath alloc] init];
        [path setLineDash:_dash count:_count phase:_offset];
        [path moveToPoint:(NSPoint){1.0, 1.5}];
        [path relativeLineToPoint:(NSPoint){26.0, 0.0}];
        [self addToPath:path];
        [path stroke];
        [_image unlockFocus];
        [_image setTemplate:YES];
    }
    
    return _image;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    DrawStrokeDash *new;
    
    new = [DrawStrokeDash alloc];
    new->_dash = NSZoneMalloc(zone, sizeof(CGFloat) * _count);
    memcpy(new->_dash, _dash, sizeof(CGFloat) * _count);
    new->_offset = _offset;
    new->_count = _count;
    new->_image = [_image copyWithZone:zone];
    
    return new;
}

#pragma mark - NSCoding

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [coder decodeStringForKey:@"pattern" setter:^(NSString * _Nonnull string) {
        self.stringValue = string;
    }];
    [coder decodeFloatForKey:@"offset" setter:^(float value) { self->_offset = value;	}];
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)coder {
    [coder encodeString:[self stringValue] forKey:@"pattern"];
    [coder encodeFloat:_offset forKey:@"offset"];
}

+ (NSString *)ajr_nameForXMLArchiving {
    return @"dash";
}

#pragma mark - NSObject

- (BOOL)isEqualToStrokeDash:(DrawStrokeDash *)other {
    BOOL equal = NO;

    if (_count == other->_count && _offset == other->_offset) {
        equal = YES;
        for (NSInteger x = 0; x < _count; x++) {
            if (_dash[x] != other->_dash[x]) {
                equal = NO;
                break;
            }
        }
    }

    return equal;
}

- (BOOL)isEqual:(id)other {
    BOOL equal = NO;

    if ([other isKindOfClass:[DrawStrokeDash class]]) {
        equal = [self isEqualToStrokeDash:other];
    }

    return equal;
}

- (NSUInteger)hash {
    return [[self description] hash];
}

@end
