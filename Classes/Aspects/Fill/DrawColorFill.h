
#import <Draw/DrawFill.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const DrawColorFillIdentifier;
extern NSString * const DrawFillColorKey;

@interface DrawColorFill : DrawFill <AJRXMLCoding>

@property (nonatomic,strong) NSColor *color;

@end

NS_ASSUME_NONNULL_END
