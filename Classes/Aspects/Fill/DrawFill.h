/* DrawFill.h created by alex on Fri 16-Oct-1998 */

#import <Draw/DrawAspect.h>

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const DrawFillIdentifier;

@interface DrawFill : DrawAspect <AJRXMLCoding>

@property (nonatomic,assign) AJRWindingRule windingRule;

@end

NS_ASSUME_NONNULL_END
