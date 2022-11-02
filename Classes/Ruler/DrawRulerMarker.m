/*
 DrawRulerMarker.m
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

#import "DrawRulerMarker.h"

#import "DrawRulerView.h"

#import <AJRInterface/AJRInterface.h>

@interface NSColor ()

+ (NSColor *)toolTipColor;
+ (NSColor *)toolTipTextColor;

@end

@interface DrawMeasureView : NSView {
    NSDictionary *_textAttributes;
    NSString *_units;
    NSNumberFormatter *_formatter;
    double _measure;
    double _minimumDenominator;
    double _conversionFactor;
}

@property (nonatomic,strong) NSString *units;
@property (nonatomic,assign) double measure;
@property (nonatomic,assign) double minimumDenominator;
@property (nonatomic,assign) double conversionFactor;

@end

@implementation DrawMeasureView

#pragma mark - Destruction


#pragma mark - Properties

@synthesize units = _units;
@synthesize measure = _measure;
@synthesize minimumDenominator = _minimumDenominator;
@synthesize conversionFactor = _conversionFactor;

- (void)setMeasure:(double)measure {
    if (measure != _measure) {
        _measure = measure;
        [self setNeedsDisplay:YES];
    }
}

#pragma mark - Utilities

- (NSString *)displayString {
    if (_textAttributes == nil) {
        _textAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                           [NSFont toolTipsFontOfSize:11.0], NSFontAttributeName,
                           [NSColor toolTipTextColor], NSForegroundColorAttributeName,
                           nil];
    }

    if (_minimumDenominator) {
        return [NSString stringWithFormat:@"%@ %@", AJRFractionFromDouble(_measure / _conversionFactor, _minimumDenominator), _units];
    }

    if (_formatter == nil) {
        _formatter = [[NSNumberFormatter alloc] init];
        [_formatter setPositiveFormat:@"#,##0.#"];
        [_formatter setNegativeFormat:@"-#,##0.#"];
    }

    return [NSString stringWithFormat:@"%@ %@", [_formatter stringFromNumber:[NSNumber numberWithDouble:_measure]], _units];
}

#pragma mark - NSView

- (void)viewWillDraw {
    NSWindow *window = [self window];
    NSString *string = [self displayString];
    NSSize size = [string sizeWithAttributes:_textAttributes];

    size.width += 6.0;
    size.height += 4.0;
    if (!NSEqualSizes([[window contentView] frame].size, size)) {
        [window setContentSize:size];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = [self bounds];
    NSPoint point;

    [[NSColor toolTipColor] set];
    NSRectFill(bounds);
    [[NSColor blackColor] set];
    NSFrameRect(bounds);

    point.x = bounds.origin.x + 3.0;
    point.y = bounds.origin.y + 2.0;
    [[self displayString] drawAtPoint:point withAttributes:_textAttributes];
}

@end


@implementation DrawRulerMarker

- (NSPoint)_pointForEvent:(NSEvent *)event {
    NSRulerView *rulerView = [self ruler];
    NSView *clientView = [rulerView clientView];
    NSPoint where = [clientView convertPoint:[event locationInWindow] fromView:nil];

    return where;
}

- (CGFloat)_locationForEvent:(NSEvent *)event {
    DrawRulerView *ruler = (DrawRulerView *)[self ruler];
    CGFloat location = [ruler orientation] == NSHorizontalRuler ? [self _pointForEvent:event].x : [self _pointForEvent:event].y;

    if ([[[self ruler] measurementUnits] isEqualToString:@"Inches"]) {
        double	conversion = [ruler rulerUnitConversionFactor];

        location = AJRRoundToNearestFraction(location / conversion, 32.0) * conversion;
    }

    return location;
}

- (void)_locateMeasureWindowForEvent:(NSEvent *)event {
    NSRulerView *rulerView = [self ruler];
    NSPoint where = [rulerView convertPoint:[event locationInWindow] fromView:nil];

    if ([rulerView orientation] == NSHorizontalRuler) {
        where.x += ([[self image] size].width - [self imageOrigin].x) + 2.0;
        where.y = [rulerView bounds].origin.y + 3.0;
    } else {
        where.x = [rulerView bounds].origin.x + [rulerView bounds].size.width;
        where.y -= 5.0;
    }

    where = [[rulerView window] ajr_convertPointToScreen:[rulerView convertPoint:where toView:nil]];

    [_measureWindow setFrameOrigin:where];
}

- (void)_createMeasureWindowForEvent:(NSEvent *)event {
    DrawMeasureView *view;

    view = [[DrawMeasureView alloc] initWithFrame:(NSRect){{0.0, 0.0}, {10.0, 10.0}}];
    [view setUnits:[(DrawRulerView *)[self ruler] rulerUnitAbbreviation]];
    if ([[[self ruler] measurementUnits] isEqualToString:@"Inches"]) {
        [view setMinimumDenominator:32.0];
    }
    [view setConversionFactor:[(DrawRulerView *)[self ruler] rulerUnitConversionFactor]];
    _measureWindow = [[NSWindow alloc] initWithContentRect:(NSRect){{0.0, 0.0}, {10.0, 10.0}} styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
    [_measureWindow setContentView:view];

    [self _locateMeasureWindowForEvent:event];
    [_measureWindow orderFront:self];
}

- (BOOL)_shouldRemoveMarkerForEvent:(NSEvent *)event {
    NSRulerView *rulerView = [self ruler];
    NSPoint location = [rulerView convertPoint:[event locationInWindow] fromView:nil];
    BOOL shouldRemove = NO;

    if ([self isRemovable]) {
        if ([[self ruler] orientation] == NSHorizontalRuler) {
            if (location.y < -20.0 || location.y > [rulerView bounds].size.height + 20.0) {
                shouldRemove = YES;
            }
        } else {
            if (location.x < -20.0 || location.x > [rulerView bounds].size.width + 20.0) {
                shouldRemove = YES;
            }
        }

        if (shouldRemove && [[rulerView clientView] respondsToSelector:@selector(rulerView:shouldRemoveMarker:)]) {
            shouldRemove = [[rulerView clientView] rulerView:rulerView shouldRemoveMarker:self];
        }
    }

    return shouldRemove;
}

- (BOOL)_trackMouseDragged:(NSEvent *)event initialLocation:(CGFloat)initialLocation adding:(BOOL)adding {
    NSRulerView *rulerView = [self ruler];
    NSView *clientView = [rulerView clientView];
    CGFloat location = [self _locationForEvent:event];

    if ([self isMovable]) {
        if (adding) {
            if ([clientView respondsToSelector:@selector(rulerView:willAddMarker:atLocation:)]) {
                location = [clientView rulerView:rulerView willAddMarker:self atLocation:location];
            }
        } else {
            if ([clientView respondsToSelector:@selector(rulerView:willMoveMarker:toLocation:)]) {
                location = [clientView rulerView:rulerView willMoveMarker:self toLocation:location];
            }
        }

        AJRLogDebug(@"%@: %.0f\n", adding ? @"Add" : @"Move", location);

        if ([self _shouldRemoveMarkerForEvent:event]) {
            if (!_isRemoving) {
                _isRemoving = YES;
                [[NSCursor disappearingItemCursor] set];
                [_measureWindow orderOut:self];
                [rulerView removeMarker:self];
            }
        } else {
            if (_isRemoving) {
                _isRemoving = NO;
                [[NSCursor arrowCursor] set];
                [_measureWindow orderFront:self];
                [rulerView addMarker:self];
            }
            [self setMarkerLocation:location];
            [self _locateMeasureWindowForEvent:event];
            [(DrawMeasureView *)[_measureWindow contentView] setMeasure:location];
        }

        [rulerView setNeedsDisplay:YES];
        [[rulerView window] display];
    }

    return NO;
}

- (BOOL)_trackMouseUp:(NSEvent *)event adding:(BOOL)adding {
    NSRulerView *rulerView = [self ruler];

    [_measureWindow orderOut:self];
    _measureWindow = nil;

    if (_isRemoving) {
        [[NSCursor arrowCursor] set];
        [rulerView removeMarker:self];
        if ([[rulerView clientView] respondsToSelector:@selector(rulerView:didRemoveMarker:)]) {
            [[rulerView clientView] rulerView:rulerView didRemoveMarker:self];
        }
        NSShowAnimationEffect(NSAnimationEffectDisappearingItemDefault, [[rulerView window] ajr_convertPointToScreen:[event locationInWindow]], NSZeroSize, nil, NULL, NULL);
    } else {
        if (adding) {
            if ([[rulerView clientView] respondsToSelector:@selector(rulerView:didAddMarker:)]) {
                [[rulerView clientView] rulerView:rulerView didAddMarker:self];
            }
        } else {
            if ([[rulerView clientView] respondsToSelector:@selector(rulerView:didMoveMarker:)]) {
                [[rulerView clientView] rulerView:rulerView didMoveMarker:self];
            }
        }
    }

    return YES;
}

- (BOOL)_trackMouse:(NSEvent *)event adding:(BOOL)adding {
    NSRulerView *rulerView = [self ruler];
    BOOL done = NO;
    BOOL removed = NO;
    CGFloat originalLocation = [self _locationForEvent:event];

    do {
        @autoreleasepool {
            NSEvent	*nextEvent = [[rulerView window] nextEventMatchingMask:NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged | NSEventMaskPeriodic | NSEventMaskFlagsChanged];

            if ([nextEvent type] == NSEventTypeLeftMouseDragged) {
                removed = [self _trackMouseDragged:nextEvent initialLocation:originalLocation adding:adding];
            } else if ([nextEvent type] == NSEventTypeLeftMouseUp) {
                [self _trackMouseUp:nextEvent adding:adding];
                done = YES;
            } else if ([nextEvent type] == NSEventTypePeriodic) {
            }
        }
    } while (!done);

    return removed;
}

- (BOOL)trackMouse:(NSEvent *)event adding:(BOOL)adding {
    NSRulerView *rulerView = [self ruler];
    id clientView = [rulerView clientView];
    BOOL track = YES;
    BOOL result = NO;

    if (clientView == nil) track = NO;
    
    if (track) {
        if (adding) {
            if ([clientView respondsToSelector:@selector(rulerView:shouldAddMarker:)] && ![clientView rulerView:rulerView shouldAddMarker:self]) {
                track = NO;
            }
        } else {
            if ([clientView respondsToSelector:@selector(rulerView:shouldMoveMarker:)] && ![clientView rulerView:rulerView shouldMoveMarker:self]) {
                track = NO;
            }
        }

        if (track) {
            [self _createMeasureWindowForEvent:event];
            result = [self _trackMouse:event adding:adding];
        }
    }

    return result;
}

@end
