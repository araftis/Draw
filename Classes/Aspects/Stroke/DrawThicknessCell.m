/*
 DrawThicknessCell.m
 Draw

 Copyright © 2022, AJ Raftis and Draw authors
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

#import "DrawThicknessCell.h"

#import <AJRInterface/AJRInterface.h>

@implementation DrawThicknessCell

- (id)initImageCell:(NSImage *)anImage {
    if ((self = [super initImageCell:anImage])) {
        [self setBordered:YES];
        [self setBezeled:YES];
        [self setContinuous:YES];
        [self setAlignment:NSTextAlignmentRight];
        [self setFont:[NSFont userFontOfSize:12.0]];
        [self setImage:anImage];
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setFormat:@"#,###.00;0.00;(#,##0.00)"];
        [self setFormatter:formatter];
        [self setFloatValue:1.0];
    }
    return self;
}

- (id)initTextCell:(NSString *)aString {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"strokeThickness" ofType:@"tiff"];
    NSImage *image = nil;

    if (path) {
        image = [[NSImage alloc] initWithContentsOfFile:path];
    }

    return [super initImageCell:image];
}

- (id)init {
    NSMutableParagraphStyle	*style;

    attributes = [[NSMutableDictionary alloc] init];
    style = [[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:nil];
    [style setAlignment:NSTextAlignmentRight];
    [attributes setObject:style forKey:NSParagraphStyleAttributeName];

    return [super initTextCell:@""];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSImage *image = [self image];
    NSRect workFrame = [self drawingRectForBounds:cellFrame];
    NSRect barRect;
    NSString *string;
    NSFont *font;
    CGFloat value = [self floatValue];

    [[NSColor controlBackgroundColor] set];
    NSRectFill(workFrame);

    [image drawAtPoint:(NSPoint){workFrame.origin.x + workFrame.size.width / 2.0 - workFrame.size.width / 2.0, workFrame.origin.y + workFrame.size.height / 2.0 - workFrame.size.height / 2.0}
              fromRect:(NSRect){NSZeroPoint, [image size]}
             operation:NSCompositingOperationSourceOver
              fraction:1.0];

    barRect = (NSRect){{rint(workFrame.origin.x + value * 4.0), workFrame.origin.y}, { 4.0, workFrame.size.height}};

    [[NSGraphicsContext currentContext] saveGraphicsState];
    NSRectClip(workFrame);
    [[NSColor selectedControlColor] set];
    NSRectFill(barRect);
    [[NSGraphicsContext currentContext] restoreGraphicsState];

    font = [self font];
    if (!font) {
        font = [NSFont systemFontOfSize:12.0];
    }
    if ([font screenFont]) font = [font screenFont];
    [attributes setObject:font forKey:NSFontAttributeName];
    [attributes setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];

    workFrame.size.height -= 6.0;
    workFrame.size.width -= 10.0;
    string = [[self formatter] stringForObjectValue:[self objectValue]];
    [string drawInRect:workFrame withAttributes:attributes];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    NSRectClip(barRect);
    [attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
    [string drawInRect:workFrame withAttributes:attributes];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if ([self isBezeled]) {
        NSDrawDarkBezel(cellFrame, cellFrame);
        [self drawInteriorWithFrame:cellFrame inView:controlView];
    } else {
        [super drawWithFrame:cellFrame inView:controlView];
    }
}

- (NSRect)drawingRectForBounds:(NSRect)theRect {
    NSRect work = [super drawingRectForBounds:theRect];

    if ([self isBezeled]) {
        work = NSInsetRect(work, -1.0, -1.0);
    }

    return work;
}

- (void)setFloatValue:(float)aValue {
    thickness = aValue;
}

- (float)floatValue {
    return thickness;
}

- (void)setObjectValue:(id)anObject {
    [self setFloatValue:[anObject floatValue]];
}

- (id)objectValue {
    return [NSNumber numberWithFloat:thickness];
}

- (void)updateValueForPoint:(NSPoint)point inView:(NSView *)controlView {
    CGFloat value;

    value = rint((point.x - 4.0) / 4.0);
    if (value < 0.0) value = 0.0;
    [self setFloatValue:value];

    [controlView setNeedsDisplay:YES];
}

- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView {
    [self updateValueForPoint:startPoint inView:controlView];
    return YES;
}

- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView {
    [self updateValueForPoint:currentPoint inView:controlView];
    return YES;
}

@end
