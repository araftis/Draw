
#import "DrawStroke.h"

#import "DrawFunctions.h"
#import "DrawGraphic.h"
#import "DrawPage.h"
#import "DrawStroke.h"
#import "DrawStrokeDash.h"
#import "DrawDocument.h"

#import <AJRInterface/AJRInterface.h>

NSString * const DrawStrokeIdentifier = @"stroke";

NSString * const DrawStrokeColorKey = @"StrokeColor";
NSString * const DrawStrokeWidthKey = @"StrokeWidth";
NSString * const DrawStrokeMiterLimitKey = @"StrokeMiterLimit";
NSString * const DrawStrokeLineJoinKey = @"StrokeLineJoin";
NSString * const DrawStrokeLineCapKey = @"StrokeLineCap";
NSString * const DrawStrokeAspectKey = @"StrokeAspect";
NSString * const DrawStrokeDashesKey = @"StrokeDashes";
NSString * const DrawStrokeDashKey = @"StrokeDash";

NSString * const DrawStrokeKey = @"DrawStrokeKey";

const NSInteger DrawStrokeVersion = 2;

@implementation DrawStroke

+ (void)initialize {
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                // The Compose Defaults
                                @"NSCalibratedWhiteColorSpace 0 1", DrawStrokeColorKey,
                                @"1.0", DrawStrokeWidthKey,
                                @"10.0", DrawStrokeMiterLimitKey,
                                @"0", DrawStrokeLineJoinKey,
                                @"0", DrawStrokeLineCapKey,
                                [NSArray arrayWithObjects:
                                 @"",
                                 @"1.000000 3.000000",
                                 @"3.000000 4.000000",
                                 @"3.000000 6.000000",
                                 @"4.000000 3.000000 1.000000 3.000000",
                                 @"4.000000 3.000000 2.000000 3.000000",
                                 @"4.000000 3.000000 1.000000 3.000000 1.000000 3.000000",
                                 nil], DrawStrokeDashesKey,
                                @"", DrawStrokeDashKey,
                                nil
                                ];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];

    [self setVersion:DrawStrokeVersion];
}

#pragma mark - Creation

- (id)initWithGraphic:(DrawGraphic *)graphic {
    if ((self = [super initWithGraphic:graphic])) {
        _width = [[NSUserDefaults standardUserDefaults] floatForKey:DrawStrokeWidthKey];
        _color = [[NSUserDefaults standardUserDefaults] colorForKey:DrawStrokeColorKey];
        _miterLimit = [[NSUserDefaults standardUserDefaults] floatForKey:DrawStrokeMiterLimitKey];
        _lineJoin = (AJRLineJoinStyle)[[NSUserDefaults standardUserDefaults] integerForKey:DrawStrokeLineJoinKey];
        _lineCap = (AJRLineCapStyle)[[NSUserDefaults standardUserDefaults] integerForKey:DrawStrokeLineCapKey];
        _dash = [[DrawStrokeDash alloc] initWithString:[[NSUserDefaults standardUserDefaults] stringForKey:DrawStrokeDashKey]];
    }
    return self;
}

+ (DrawAspect *)defaultAspectForGraphic:(DrawGraphic *)graphic {
    return [[self alloc] initWithGraphic:graphic];
}

#pragma mark - Properties

- (AJRBezierPath *)_configurePath:(AJRBezierPath *)path {
    CGFloat error = [[self.graphic page] error];

    path.lineJoinStyle = (AJRLineJoinStyle)_lineJoin;
    path.lineCapStyle = (AJRLineCapStyle)_lineCap;
    path.miterLimit = _miterLimit;
    path.flatness = self.graphic.flatness;
    path.lineWidth = _width < error ? error : _width;
    if (_dash) {
        [_dash addToPath:path];
    }

    return path;
}

- (DrawGraphicCompletionBlock)drawPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    DrawGraphic	*focused = [[self.graphic document] focusedGroup];

    if ([self.graphic isDescendantOf:focused]) {
        [_color set];
    } else {
        [[NSColor darkGrayColor] set];
    }
    [[self _configurePath:path] stroke];

    return NULL;
}

- (AJRBezierPath *)renderPathForPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    return [[self _configurePath:path] bezierPathFromStrokedPath];
}

- (BOOL)isPoint:(NSPoint)point inPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    [self _configurePath:path];
    CGFloat lineWidth = path.lineWidth;
    if (lineWidth < 5.0) {
        lineWidth = 5.0;
    }
    BOOL hit = [path isStrokeHitByPoint:point];
    path.lineWidth = lineWidth;
    return hit;
}

- (BOOL)doesRect:(NSRect)rect intersectPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    return [[self _configurePath:path] isStrokeHitByRect:rect];
}

- (AJRRectAdjustment)boundsAdjustment {
    return (AJRRectAdjustment){_width, _width, _width, _width};
}

- (NSRect)boundsForPath:(AJRBezierPath *)path {
    [path setLineWidth:_width];
    [path setLineJoinStyle:(AJRLineJoinStyle)_lineJoin];
    [path setLineCapStyle:(AJRLineCapStyle)_lineCap];
    [path setMiterLimit:_miterLimit];
    [path setFlatness:[self.graphic flatness]];
    [_dash addToPath:path];

    return NSIntegralRect([path strokeBounds]);
}

- (void)setWidth:(CGFloat)width {
    if (_width != width) {
        _width = width;
        [self.graphic updateBounds];
        [self.graphic setNeedsDisplay];
    }
}

- (void)setColor:(NSColor *)color {
    if (_color != color) {
        _color = color;
        [self.graphic setNeedsDisplay];
    }
}

- (void)setLineJoin:(AJRLineJoinStyle)lineJoin {
    if (_lineJoin != lineJoin) {
        _lineJoin = lineJoin;
        [self.graphic updateBounds];
        [self.graphic setNeedsDisplay];
    }
}

- (void)setLineCap:(AJRLineCapStyle)lineCap {
    if (_lineCap != lineCap) {
        _lineCap = lineCap;
        [self.graphic updateBounds];
        [self.graphic setNeedsDisplay];
    }
}

- (void)setMiterLimit:(CGFloat)miterLimit {
    if (_miterLimit != miterLimit) {
        if (_miterLimit < 1.0) {
            [NSException raise:NSInvalidArgumentException format:@"Invalid miter limit %.1f, the miter limit must be greater than 1.0", miterLimit];
        }
        _miterLimit = miterLimit;
        [self.graphic updateBounds];
        [self.graphic setNeedsDisplay];
    }
}

- (void)setDash:(DrawStrokeDash *)dash {
    if (_dash != dash) {
        _dash = dash;
        [self.graphic setNeedsDisplay];
    }
}

+ (NSImage *)image {
    return [NSImage imageNamed:@"strokeLine"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    DrawStroke	*aspect = [super copyWithZone:nil];

    aspect->_width = _width;
    aspect->_color = [_color copyWithZone:zone];
    aspect->_miterLimit = _miterLimit;
    aspect->_lineJoin = _lineJoin;
    aspect->_lineCap = _lineCap;
    aspect->_dash = [_dash copyWithZone:zone];

    return aspect;
}

#pragma mark - NSCoding

- (void)encodeWithXMLCoder:(AJRXMLCoder *)encoder {
    [super encodeWithXMLCoder:encoder];

    [encoder encodeFloat:_width forKey:@"width"];
    [encoder encodeObject:_color forKey:@"color"];
    [encoder encodeFloat:_miterLimit forKey:@"miterLimit"];
    [encoder encodeInteger:_lineJoin forKey:@"lineJoin"];
    [encoder encodeInteger:_lineCap forKey:@"lineCap"];
    [encoder encodeObject:_dash forKey:@"dash"];
}

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super decodeWithXMLCoder:coder];

    [coder decodeFloatForKey:@"width" setter:^(float value) {
        self->_width = value;
    }];
    [coder decodeObjectForKey:@"color" setter:^(id  _Nonnull object) {
        self->_color = object;
    }];
    [coder decodeFloatForKey:@"miterLimit" setter:^(float value) {
        self->_miterLimit = value;
    }];
    [coder decodeIntegerForKey:@"lineJoin" setter:^(NSInteger value) {
        self->_lineJoin = value;
    }];
    [coder decodeIntegerForKey:@"lineCap" setter:^(NSInteger value) {
        self->_lineCap = value;
    }];
    [coder decodeObjectForKey:@"dash" setter:^(id  _Nonnull object) {
        self->_dash = object;
    }];
}

@end
