//
//  DrawMeasurementUnit.h
//  Draw
//
//  Created by Alex Raftis on 8/24/11.
//  Copyright (c) 2011 Apple, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <AJRFoundation/AJRUniqueObject.h>

@interface DrawMeasurementUnit : NSObject

+ (NSArray *)availableMeasurementUnits;
+ (NSFormatter *)formatterForMeasurementUnit:(NSString *)measurementUnit;

- (id)initWithName:(NSString *)name abbreviation:(NSString *)abbreviation conversionFaction:(double)conversionFactor stepUpCycle:(NSArray *)stepUpCycle andStepDownCycle:(NSArray *)stepDownCycle;

@property (readonly,strong) NSString *measureName;
@property (readonly,strong) NSString *abbreviation;
@property (readonly,assign) double conversionFactor;
@property (readonly,strong) NSArray *stepUpCycle;
@property (readonly,strong) NSArray *stepDownCycle;
@property (strong) NSFormatter *formatter;

@end
