
#import <Draw/DrawAspect.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const DrawOpacityIdentifier;

@interface DrawOpacity : DrawAspect <AJRXMLCoding>

@property (nonatomic,assign) CGFloat opacity;

@end

NS_ASSUME_NONNULL_END
