
#import "DrawOpacity.h"

@implementation DrawOpacity

NSString * const DrawOpacityIdentifier = @"opacity";

#pragma mark - Creation

- (id)initWithGraphic:(DrawGraphic *)graphic {
    if ((self = [super initWithGraphic:graphic])) {
        _opacity = 1.0;
    }
    return self;
}

#pragma mark - Properties

- (void)setOpacity:(CGFloat)opacity {
    if (opacity != _opacity) {
        _opacity = opacity;
        [self.graphic setNeedsDisplay];
    }
}

#pragma mark - DrawAspect

- (DrawGraphicCompletionBlock)drawPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    CGContextSetAlpha([[NSGraphicsContext currentContext] CGContext], _opacity);
    CGContextBeginTransparencyLayerWithRect([[NSGraphicsContext currentContext] CGContext], [self.graphic dirtyBounds], NULL);
    return ^() {
        CGContextEndTransparencyLayer([[NSGraphicsContext currentContext] CGContext]);
    };
}

+ (DrawAspect *)defaultAspectForGraphic:(DrawGraphic *)graphic {
    return [[self alloc] initWithGraphic:graphic];
}

#pragma mark - NSCoding

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super decodeWithXMLCoder:coder];

    [coder decodeFloatForKey:@"opacity" setter:^(float value) {
        self->_opacity = value;
    }];
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super encodeWithXMLCoder:coder];
    
    [coder encodeFloat:_opacity forKey:@"opacity"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    DrawOpacity *new = [super copyWithZone:zone];
    
    new->_opacity = _opacity;
    
    return new;
}

@end
