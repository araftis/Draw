
#import <Draw/DrawGraphic.h>

#import <AJRFoundation/AJRFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(uint8_t, DrawCircleHandleIndex) {
    DrawCircleHandleFirst = 0,
    DrawCircleHandleStartAngle = 1,
    DrawCircleHandleEndAngle = 2,
    DrawCircleHandleOrigin = 3
};

typedef NS_ENUM(uint8_t, DrawCircleType) {
    DrawCircleTypeCircle,
    DrawCircleTypePie,
    DrawCircleTypeChord,
};

extern const AJRInspectorIdentifier AJRInspectorIdentifierCircle;

@interface DrawCircle : DrawGraphic <AJRXMLCoding>

@property (nonatomic,readonly) BOOL isCircle;
@property (nonatomic,assign) NSPoint origin;
@property (nonatomic,assign) CGFloat radius;
@property (nonatomic,assign) CGFloat startAngle;
@property (nonatomic,assign) CGFloat endAngle;
@property (nonatomic,assign) NSRect arcBounds;
@property (nonatomic,assign) DrawCircleType type;

@end

extern NSString *DrawStringFromDrawCircleType(DrawCircleType type);
extern DrawCircleType DrawCircleTypeFromString(NSString *type);

NS_ASSUME_NONNULL_END
