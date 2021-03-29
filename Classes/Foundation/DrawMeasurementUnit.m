
#import "DrawMeasurementUnit.h"

#import <AJRFoundation/AJRFractionFormatter.h>
#import <AJRFoundation/AJRFormat.h>

#import <objc/runtime.h>

typedef void (*DrawRulerRegisterMethod)(id, SEL, NSString *, NSString *, CGFloat, NSArray *, NSArray *);
static DrawRulerRegisterMethod _originalRegistrationMethod = NULL;

static NSMutableDictionary *_units = nil;

@interface NSRulerView (Private)

+ (void)_registerUnitWithName:(NSString *)unitName abbreviation:(NSString *)abbreviation unitToPointsConversionFactor:(CGFloat)conversionFactor stepUpCycle:(NSArray *)stepUpCycle stepDownCycle:(NSArray *)stepDownCycle;

@end

@implementation DrawMeasurementUnit

#pragma mark - Load

+ (void)load {
    Class rulerViewClass = objc_getClass("NSRulerView");
    Method method = class_getClassMethod(rulerViewClass, @selector(_registerUnitWithName:abbreviation:unitToPointsConversionFactor:stepUpCycle:stepDownCycle:));
    Method  overrideMethod = class_getClassMethod(self, @selector(draw_registerUnitWithName:abbreviation:unitToPointsConversionFactor:stepUpCycle:stepDownCycle:));
    
    _originalRegistrationMethod = (DrawRulerRegisterMethod)method_getImplementation(method);
    method_setImplementation(method, method_getImplementation(overrideMethod));
}    

+ (void)draw_registerUnitWithName:(NSString *)unitName abbreviation:(NSString *)abbreviation unitToPointsConversionFactor:(CGFloat)conversionFactor stepUpCycle:(NSArray *)stepUpCycle stepDownCycle:(NSArray *)stepDownCycle {
    DrawMeasurementUnit *entry;
    
    if (_units == nil) {
        _units = [[NSMutableDictionary alloc] init];
    }
    
    entry = [_units objectForKey:unitName];
    if (entry == nil) {
        entry = [[DrawMeasurementUnit alloc] initWithName:unitName abbreviation:abbreviation conversionFaction:conversionFactor stepUpCycle:stepUpCycle andStepDownCycle:stepDownCycle];
        [_units setObject:entry forKey:unitName];
    }

    _originalRegistrationMethod(self, _cmd, unitName, abbreviation, conversionFactor, stepUpCycle, stepDownCycle);
}

#pragma mark - Creation

- (id)initWithName:(NSString *)name abbreviation:(NSString *)abbreviation conversionFaction:(double)conversionFactor stepUpCycle:(NSArray *)stepUpCycle andStepDownCycle:(NSArray *)stepDownCycle {
    if ((self = [super init])) {
        _measureName = name;
        _abbreviation = abbreviation;
        _conversionFactor = conversionFactor;
        _stepUpCycle = stepUpCycle;
        _stepDownCycle = stepDownCycle;
    }
    
    return self;
}

#pragma mark - Factory

+ (NSArray *)availableMeasurementUnits {
    return [_units allKeys];
}

+ (NSFormatter *)formatterForMeasurementUnit:(NSString *)unitName {
    DrawMeasurementUnit	*entry = [_units objectForKey:unitName];
    NSFormatter *formatter = nil;
    
    if (entry) {
        formatter = [entry formatter];
        if (formatter == nil) {
            if ([unitName isEqualToString:@"Inches"]) {
                formatter = [[AJRFractionFormatter alloc] init];
                [(AJRFractionFormatter *)formatter setMinimumDenominator:32.0];
                [(AJRFractionFormatter *)formatter setSuffix:AJRFormat(@" %@", [entry abbreviation])];
            } else {
                formatter = [[NSNumberFormatter alloc] init];
                [(NSNumberFormatter *)formatter setPositiveFormat:AJRFormat(@"#,##0.## %@", [entry abbreviation])];
                [(NSNumberFormatter *)formatter setNegativeFormat:AJRFormat(@"-#,##0.## %@", [entry abbreviation])];
            }
            [entry setFormatter:formatter];
        }
    }
    
    return formatter;
}

@end
