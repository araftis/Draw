/* DrawColorFill.m created by alex on Fri 16-Oct-1998 */

#import "DrawColorFill.h"

#import "DrawDocument.h"
#import "DrawGraphic.h"

#import <AJRInterface/NSUserDefaults+Extensions.h>

NSString * const DrawColorFillIdentifier = @"DrawColorFillIdentifier";
NSString * const DrawFillColorKey = @"FillColor";

@implementation DrawColorFill

+ (void)initialize {
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     @{DrawFillColorKey:@"NSCalibratedRGBColorSpace 1 0.7 1 1"}];
}

#pragma mark - Creation

+ (DrawAspect *)defaultAspectForGraphic:(DrawGraphic *)graphic {
    return [[self alloc] initWithGraphic:graphic];
}

- (id)initWithGraphic:(DrawGraphic *)aGraphic {
    if ((self = [super initWithGraphic:aGraphic])) {
        _color = [[NSUserDefaults standardUserDefaults] colorForKey:DrawFillColorKey];
    }
    return self;
}

#pragma mark - Properties

@synthesize color = _color;

- (void)setColor:(NSColor *)color {
    if (_color != color) {
        _color = color;
        [self.graphic setNeedsDisplay];
    }
}

#pragma mark - DrawAspect

- (DrawGraphicCompletionBlock)drawPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    DrawGraphic	*focused = [self.graphic.document focusedGroup];
    
    if ([self.graphic isDescendantOf:focused]) {
        [_color set];
    } else {
        [[NSColor lightGrayColor] set];
    }
    [path setFlatness:[self.graphic flatness]];
    [path setWindingRule:self.windingRule];
    [path fill];
    
    return NULL;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    DrawColorFill	*aspect = [super copyWithZone:nil];
    
    aspect->_color = [_color copyWithZone:zone];
    
    return aspect;
}

#pragma mark - AJRXMLCoding

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super decodeWithXMLCoder:coder];

    [coder decodeObjectForKey:@"color" setter:^(id  _Nonnull object) {
        self->_color = object;
    }];
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)encoder {
    [super encodeWithXMLCoder:encoder];
    
    [encoder encodeObject:_color forKey:@"color"];
}

@end
