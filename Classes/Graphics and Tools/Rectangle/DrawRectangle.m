
#import "DrawRectangle.h"

#import "DrawFunctions.h"
#import "DrawDocument.h"
#import <AJRInterface/AJRInterface.h>

NSString *DrawRectangleRadiusKey = @"DrawRectangleRadiusKey";

const AJRInspectorIdentifier AJRInspectorIdentifierRectangle = @"rectangle";
const CGFloat DrawRectanglePillRadius = 1000000.0;

@implementation DrawRectangle {
    CGFloat _prepillRadius;
}

#pragma mark - Initialization

+ (void)initialize {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{DrawRectangleRadiusKey : @"9.0"}];
}

#pragma mark - Creation

- (id)initWithFrame:(NSRect)aFrame {
    if ((self = [super initWithFrame:aFrame])) {
        [self updatePath];
        _radius = 0;
        _prepillRadius = 0;
    }
    return self;
}

#pragma mark - Utilities

- (void)_createCircle {
    [_path removeAllPoints];
    [_path appendBezierPathWithOvalInRect:self.frame];
}

- (void)_createRectangle {
    [_path removeAllPoints];
    [_path appendBezierPathWithRect:self.frame];
}

- (void)_createRoundedRectangle {
    [_path removeAllPoints];
    [_path appendBezierPathWithRoundedRect:self.frame xRadius:_radius yRadius:_radius];
}

- (void)updatePath {
    float diameter = _radius * 2.0;

    if (diameter > 0.0) {
        if ((diameter > self.frame.size.width) || (diameter > self.frame.size.height)) {
            if (self.frame.size.width == self.frame.size.height) {
                [self _createCircle];
            } else {
                float	temp = _radius;
                if (diameter > self.frame.size.width) diameter = self.frame.size.width;
                if (diameter > self.frame.size.height) diameter = self.frame.size.height;
                _radius = diameter / 2.0;
                [self _createRoundedRectangle];
                _radius = temp;
            }
        } else {
            [self _createRoundedRectangle];
        }
    } else {
        [self _createRectangle];
    }
}

#pragma mark - DrawTool

- (void)setFrame:(NSRect)frame {
    [super setFrame:frame];
    [self updatePath];
    [self updateBounds];
}

- (void)setRadius:(CGFloat)radius {
    if (_radius != radius) {
        [(DrawRectangle *)[self.document prepareWithInvocationTarget:self] setRadius:_radius];
        if (radius == DrawRectanglePillRadius) {
            _prepillRadius = _radius;
        }
        _radius = radius;
        [self updatePath];
        [self setNeedsDisplay];
    }
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingIsPill {
    return [NSSet setWithObjects:@"radius", nil];
}

- (void)setIsPill:(BOOL)isPill {
    if (isPill) {
        [self setRadius:DrawRectanglePillRadius];
    } else {
        [self setRadius:_prepillRadius];
    }
}

- (BOOL)isPill {
    return _radius >= DrawRectanglePillRadius;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    DrawRectangle *new = [super copyWithZone:zone];

    new->_radius = _radius;

    return new;
}

#pragma mark - AJRXMLCoding

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super decodeWithXMLCoder:coder];
    [coder decodeBoolForKey:@"isPill" setter:^(BOOL value) {
        self->_radius = DrawRectanglePillRadius;
    }];
    [coder decodeFloatForKey:@"nonPillRadius" setter:^(float value) {
        self->_prepillRadius = value;
    }];
    [coder decodeFloatForKey:@"radius" setter:^(float value) {
        self->_radius = value;
    }];
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)encoder {
    [super encodeWithXMLCoder:encoder];
    if (self.isPill) {
        [encoder encodeBool:YES forKey:@"isPill"];
        [encoder encodeFloat:_prepillRadius forKey:@"nonPillRadius"];
    } else {
        [encoder encodeFloat:_radius forKey:@"radius"];
    }
}

- (id)finalizeXMLDecodingWithError:(NSError * _Nullable __autoreleasing *)error {
    [super finalizeXMLDecodingWithError:error];
    [self updatePath];
    return self;
}

+ (NSString *)ajr_nameForXMLArchiving {
    return @"rectangle";
}

- (BOOL)isEqualToRectangle:(DrawRectangle *)other {
    return (self.class == other.class
            && [super isEqualToGraphic:other]
            && _radius == other->_radius);
}

- (BOOL)isEqual:(id)other {
    return self == other || ([other isKindOfClass:DrawRectangle.class] && [self isEqualToRectangle:other]);
}

#pragma mark - Inspectors

- (NSArray<AJRInspectorIdentifier> *)inspectorIdentifiers {
    NSMutableArray<AJRInspectorIdentifier> *identifiers = [[super inspectorIdentifiers] mutableCopy];
    [identifiers addObject:AJRInspectorIdentifierRectangle];
    return identifiers;
}

@end
