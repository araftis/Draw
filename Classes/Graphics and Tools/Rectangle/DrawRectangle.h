
#import <Draw/DrawGraphic.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *DrawRectangleRadiusKey;

extern const AJRInspectorIdentifier AJRInspectorIdentifierRectangle;

extern const CGFloat DrawRectanglePillRadius;

@interface DrawRectangle : DrawGraphic

- (void)updatePath;

@property (nonatomic,assign) CGFloat radius;
@property (nonatomic,assign) BOOL isPill;

@end

NS_ASSUME_NONNULL_END
