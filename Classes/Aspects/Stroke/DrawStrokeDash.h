/* DrawStrokeDash.h created by alex on Tue 09-Mar-1999 */

#import <AppKit/AppKit.h>
#import <AJRFoundation/AJRFoundation.h>

@class AJRBezierPath, DrawStroke;

NS_ASSUME_NONNULL_BEGIN

@interface DrawStrokeDash : NSObject <NSCopying, AJRXMLCoding>

@property (nonatomic,class,readonly) NSArray *defaultDashes;

- (instancetype)initWithString:(NSString *)string;

@property (nonatomic,assign) CGFloat offset;
@property (nonatomic,readonly) NSUInteger count;
@property (nonatomic,readonly) CGFloat *values;
@property (nonatomic,strong) NSString *stringValue;

- (void)addToPath:(AJRBezierPath *)path;

@property (nonatomic,readonly) NSImage *image;

- (BOOL)isEqualToStrokeDash:(DrawStrokeDash *)other;

@end

NS_ASSUME_NONNULL_END
