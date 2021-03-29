
#import <Draw/DrawAspect.h>

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const DrawStrokeIdentifier;

extern NSString * const DrawStrokeColorKey;
extern NSString * const DrawStrokeWidthKey;
extern NSString * const DrawStrokeMiterLimitKey;
extern NSString * const DrawStrokeLineJoinKey;
extern NSString * const DrawStrokeLineCapKey;
extern NSString * const DrawStrokeAspectKey;
extern NSString * const DrawStrokeDashesKey;
extern NSString * const DrawStrokeDashKey;

extern NSString * const DrawStrokeKey;

const extern NSInteger DrawStrokeVersion;

@class DrawStrokeDash;

@interface DrawStroke : DrawAspect

@property (nonatomic,assign) CGFloat width;
@property (nonatomic,strong) NSColor *color;
@property (nonatomic,assign) CGFloat miterLimit;
@property (nonatomic,strong) DrawStrokeDash *dash;
@property (nonatomic,assign) AJRLineJoinStyle lineJoin;
@property (nonatomic,assign) AJRLineCapStyle lineCap;

@end

NS_ASSUME_NONNULL_END
