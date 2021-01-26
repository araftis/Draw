/* DrawFunctions.h created by alex on Fri 09-Oct-1998 */

#import <AppKit/AppKit.h>

#define DrawAbstract(retval) { NSAssert(NO, @"Subclasses of %@ must implement %@.", NSStringFromClass([self class]), NSStringFromSelector(_cmd)); return retval; }

extern NSRect DrawBoundsForGraphics(id <NSFastEnumeration> graphics);
extern NSRect DrawFrameForGraphics(id <NSFastEnumeration> graphics);

extern CGContextRef DrawBeginImageContext(NSSize size, CGFloat scale, BOOL flipped);
extern NSImage *DrawGetImageFromContext(CGContextRef context, NSSize size, CGFloat scale);
extern void DrawEndImageContext(CGContextRef context);
