/* DrawView-EPS.m created by alex on Tue 10-Nov-1998 */

#import "DrawDocument.h"

#import "DrawGraphic.h"

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>
#import <AJRInterface/AJRInterface.h>

@interface _drawMiniView : NSView {
    NSRect bounds;
    NSArray *graphics;
}

@end

@implementation _drawMiniView

- (id)initWithFrame:(NSRect)frame graphics:(NSArray *)someGraphics bounds:(NSRect)aRect {
    if ((self = [super initWithFrame:frame])) {
        graphics = someGraphics;
        bounds = aRect;
    }
    return self;
}

- (BOOL)isFlipped {
    return YES;
}

- (void)drawRect:(NSRect)rect {
    NSInteger	x;
    DrawGraphic	*graphic;

    //[AJRObserverCenter suppressObserverNotification];
    [NSAffineTransform translateXBy:-bounds.origin.x yBy:-bounds.origin.y];
    for (x = 0; x < (const NSInteger)[graphics count]; x++) {
        graphic = [graphics objectAtIndex:x];
        [graphic draw];
    }
    //[AJRObserverCenter enableObserverNotification];
}

@end


@implementation DrawDocument (EPS)

- (NSImage *)imageForSelection {
    return [self imageForGraphicsArray:[self sortedSelection]];
}

- (NSImage *)imageForGraphicsArray:(NSArray *)graphics {
    NSData *data = [self PDFForGraphics:graphics];
    NSImage *image = nil;

    if (data) image = [[NSImage alloc] initWithData:data];

    return image;
}

- (NSData *)PDFForGraphics:(NSArray *)graphics {
    NSWindow *temp;
    _drawMiniView *miniView;
    NSRect bounds = NSZeroRect;
    NSPrintOperation *operation;
    NSMutableData *data;

    if ([graphics count]) {
        for (DrawGraphic *graphic in graphics) {
            if (NSEqualRects(bounds, NSZeroRect)) {
                bounds = [graphic dirtyBounds];
            } else {
                bounds = NSUnionRect(bounds, [graphic dirtyBounds]);
            }
        }
    } else {
        return nil;
    }

    temp = [[NSWindow alloc] initWithContentRect:(NSRect){{0.0, 0.0}, bounds.size}
                                       styleMask:0
                                         backing:NSBackingStoreBuffered
                                           defer:NO];
    miniView = [[_drawMiniView alloc] initWithFrame:[[temp contentView] frame] graphics:graphics bounds:bounds];
    [[temp contentView] addSubview:miniView];

    data = [[NSMutableData alloc] init];
    operation = [NSPrintOperation EPSOperationWithView:[temp contentView] insideRect:[[temp contentView] bounds] toData:data];
    [operation setShowsPrintPanel:NO];
    [operation runOperation];

    [miniView removeFromSuperview];

    return data;
}

@end
