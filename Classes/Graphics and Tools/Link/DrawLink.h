
#import <Draw/DrawPen.h>

#import <AJRFoundation/AJRFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class DrawLinkCap;

extern const AJRInspectorIdentifier AJRInspectorIdentifierLink;

@interface DrawLink : DrawPen <AJRXMLCoding>

- (id)initWithSource:(nullable DrawGraphic *)sourceGraphic;

@property (nullable,nonatomic,strong) DrawGraphic *source;
- (void)setSource:(DrawGraphic *)aSource withHandle:(DrawHandle)aHandle;
@property (nonatomic,assign) NSPoint sourcePoint;
@property (nonatomic,readonly) NSPoint adjustedSourcePoint;
@property (nonatomic,assign) DrawHandle sourceHandle;
- (void)updateSourcePoint;
@property (nullable,nonatomic,strong) DrawLinkCap *sourceCap;

@property (nullable,nonatomic,strong) DrawGraphic *destination;
- (void)setDestination:(DrawGraphic *)destination withHandle:(DrawHandle)aHandle;
@property (nonatomic,assign) NSPoint destinationPoint;
@property (nonatomic,readonly) NSPoint adjustedDestinationPoint;
@property (nonatomic,assign) DrawHandle destinationHandle;
- (void)updateDestinationPoint;
@property (nullable,nonatomic,strong) DrawLinkCap *destinationCap;

- (CGFloat)angleInDegreesOfSourceSegment;
- (CGFloat)angleInDegreesOfDestinationSegment;

#pragma mark - Equality

- (BOOL)isEqualToLink:(DrawLink *)other;

@end

NS_ASSUME_NONNULL_END
