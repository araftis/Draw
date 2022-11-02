/*
 DrawMeasurementUnit.m
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
