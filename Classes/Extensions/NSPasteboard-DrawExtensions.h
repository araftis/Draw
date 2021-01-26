/* NSPasteboard-DrawExtensions.h created by alex on Wed 21-Oct-1998 */

#import <AppKit/AppKit.h>

@interface NSPasteboard (DrawExtensions)

- (void)setDrawGraphics:(NSArray *)graphics forType:(NSString *)dataType;
- (NSArray *)drawGraphicsForType:(NSString *)dataType;

@end
