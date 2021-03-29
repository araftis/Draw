
#import <AppKit/AppKit.h>

@interface NSPasteboard (DrawExtensions)

- (void)setDrawGraphics:(NSArray *)graphics forType:(NSString *)dataType;
- (NSArray *)drawGraphicsForType:(NSString *)dataType;

@end
