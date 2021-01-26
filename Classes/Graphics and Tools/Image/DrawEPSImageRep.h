/* DrawEPSImageRep.h created by alex on Wed 28-Oct-1998 */

#import <AppKit/AppKit.h>

// This object just overrides some drawing to make it work correctly.
@interface DrawEPSImageRep : NSEPSImageRep
{
}

- (NSMutableArray *)actions;
- (void)setActions:(NSMutableArray *)actions;

@end
