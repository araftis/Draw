
#import <Draw/DrawTool.h>

#import <Draw/DrawGraphic.h>
#import <Draw/DrawSelectionTool.h>

@class DrawLinkCap;

extern NSString * const DrawLinkToolIdentifier;

@interface DrawLinkTool : DrawTool <DrawSelectionDragger>

+ (void)registerLinkCap:(Class)aClass properties:(NSDictionary *)properties;
+ (NSArray<Class> *)linkCaps;
+ (NSUInteger)indexForLinkCapClass:(Class)linkCap;
+ (NSUInteger)indexForLinkCap:(DrawLinkCap *)linkCap;
+ (NSUInteger)indexForLinkCapNamed:(NSString *)name;
+ (Class)linkCapClassAtIndex:(NSUInteger)index;

@end
