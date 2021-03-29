
#import "DrawFill.h"

#import "DrawFunctions.h"
#import "DrawDocument.h"

#import <AJRInterface/AJRInterface.h>

NSString * const DrawFillIdentifier = @"fill";
NSString * const DrawFillWindingRuleKey = @"DrawFillWindingRuleKey";

@implementation DrawFill

- (id)initWithGraphic:(DrawGraphic *)aGraphic {
    if (self.class == DrawFill.class) {
        AJRPrintf(@"break here\n");
    }
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
    DrawFill	*aspect = [super copyWithZone:nil];

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
