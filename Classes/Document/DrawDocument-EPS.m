/*
DrawDocument-EPS.m
Draw

Copyright © 2021, AJ Raftis and AJRFoundation authors
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this 
  list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, 
  this list of conditions and the following disclaimer in the documentation 
  and/or other materials provided with the distribution.
* Neither the name of Draw nor the names of its contributors may be 
  used to endorse or promote products derived from this software without 
  specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL AJ RAFTIS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

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

- (NSImage *)imageForGraphicsArray:(NSArray<DrawGraphic *> *)graphics {
    NSData *data = [self PDFForGraphics:graphics];
    NSImage *image = nil;

    if (data) {
        image = [[NSImage alloc] initWithData:data];
    }

    return image;
}

- (NSData *)PDFForGraphics:(NSArray<DrawGraphic *> *)graphics {
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
    operation = [NSPrintOperation PDFOperationWithView:temp.contentView insideRect:temp.contentView.bounds toData:data];
    [operation setShowsPrintPanel:NO];
    [operation runOperation];

    [miniView removeFromSuperview];

    return data;
}

@end
