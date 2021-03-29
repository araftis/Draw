
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DrawDocument;

@interface DrawFilter : NSObject

#pragma mark - Factory

+ (void)registerFilter:(Class)filterClass properties:(NSDictionary<NSString *, id> *)properties;

+ (DrawFilter *)readFilterForType:(NSString *)type;
+ (DrawFilter *)writeFilterForType:(NSString *)type;

+ (NSArray<NSString *> *)readableFilterTypes;
+ (NSArray<NSString *> *)writableFilterTypes;

#pragma mark - Information

- (NSArray<NSString *> *)readableTypes;
- (NSArray<NSString *> *)writableTypes;

#pragma mark - I/O

- (BOOL)readDocument:(DrawDocument *)document fromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)error;
- (nullable NSFileWrapper *)fileWrapperForDocument:(DrawDocument *)document error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
