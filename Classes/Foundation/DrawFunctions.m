/* DrawFunctions.m created by alex on Fri 09-Oct-1998 */

#import "DrawFunctions.h"

#import "DrawGraphic.h"

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

NSRect DrawBoundsForGraphics(id <NSFastEnumeration> graphics) {
    NSRect bounds = NSZeroRect;

    for (DrawGraphic *graphic in graphics) {
        if (NSEqualRects(bounds, NSZeroRect)) {
            bounds = [graphic dirtyBounds];
        } else {
            bounds = NSUnionRect(bounds, [graphic dirtyBounds]);
        }
    }

    return bounds;
}

NSRect DrawFrameForGraphics(id <NSFastEnumeration> graphics) {
    NSRect frame = NSZeroRect;

    for (DrawGraphic *graphic in graphics) {
        if (NSEqualRects(frame, NSZeroRect)) {
            frame = [graphic frame];
        } else {
            frame = NSUnionRect(frame, [graphic frame]);
        }
    }

    return frame;
}
