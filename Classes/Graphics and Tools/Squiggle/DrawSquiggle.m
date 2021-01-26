/* DrawSquiggle.m created by alex on Wed 28-Oct-1998 */

#import "DrawSquiggle.h"

#import "DrawPage.h"

@implementation DrawSquiggle

- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint {
    if (self.creating) {
        self.ignore = YES;
        [self.page displayRect:[self bounds]];
        self.ignore = NO;
        _handle.type = DrawHandleTypeIndexed;
        [self setHandle:_handle toLocation:currentPoint];
        _handle.elementIndex++;
        [self.page displayRect:[self bounds]];
        return YES;
    }
    return [super continueTracking:lastPoint at:currentPoint];
}

- (BOOL)isEqualToSquiggle:(DrawSquiggle *)other {
    return (self.class == other.class
            && [super isEqualToPen:other]);
}

- (BOOL)isEqual:(id)other {
    return self == other || ([other isKindOfClass:DrawSquiggle.class] && [self isEqualToPen:other]);
}

#pragma mark - AJRXMLCoding

+ (NSString *)ajr_nameForXMLArchiving {
    return @"squiggle";
}

@end
