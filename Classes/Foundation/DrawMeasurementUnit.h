
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
