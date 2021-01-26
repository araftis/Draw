/* DrawRulerView.m created by alex on Thu 12-Nov-1998 */

#import "DrawRulerView.h"

#import "DrawDocument.h"
#import "DrawPage.h"

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>
#import <AJRInterface/AJRInterface.h>

@interface NSRulerView ()

+ (NSDictionary *)_registrationDictionaryForUnitNamed:(NSString *)name;

@end

#define RULE_THICKNESS 0.0
#define MARKER_THICKNESS 16.0
#define ACCESSORY_MARGIN 0.0

@implementation DrawRulerView

#pragma mark - Creation

- (id)initWithScrollView:(NSScrollView *)scrollView orientation:(NSRulerOrientation)orientation {
    if ((self = [super initWithScrollView:scrollView orientation:orientation])) {
        self.backgroundColor = [NSColor windowBackgroundColor];
        self.rulerBackgroundColor = [NSColor whiteColor];
        self.rulerMarginBackgroundColor = [NSColor colorWithDeviceWhite:0.9 alpha:1.0];
        self.tickColor = [NSColor colorWithCalibratedWhite:0.47 alpha:1.0];
        self.unitColor = [NSColor colorWithCalibratedWhite:0.1 alpha:1.0];

        _unitAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                           [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeMini]], NSFontAttributeName,
                           _unitColor, NSForegroundColorAttributeName, nil];
    }
    return self;
}

#pragma mark - Properties

- (NSString *)rulerUnitAbbreviation {
    return [[NSRulerView _registrationDictionaryForUnitNamed:[self measurementUnits]] objectForKey:@"NSRulerUnitAbbreviation"];
}

- (CGFloat)rulerUnitConversionFactor {
    return [[[NSRulerView _registrationDictionaryForUnitNamed:[self measurementUnits]] objectForKey:@"NSRulerUnitConversionFactor"] floatValue];
}

#pragma mark - Utilities

- (NSRulerMarker *)markerAtPoint:(NSPoint)point {
    for (NSRulerMarker *marker in [self markers]) {
        if ([self mouse:point inRect:[marker imageRectInRuler]]) {
            return marker;
        }
    }

    return nil;
}

#pragma mark - NSRulerView

- (void)drawHorizontalRulerInRect:(NSRect)rect {
    NSRect rulerBounds = [self bounds];
    DrawPage *page = (DrawPage *)[self clientView];
    NSDictionary *ticks = [NSRulerView _registrationDictionaryForUnitNamed:[self measurementUnits]];
    CGFloat tickConversionFactor = [[ticks objectForKey:@"NSRulerUnitConversionFactor"] floatValue];
    NSArray *stepDownCycle = [ticks objectForKey:@"NSRulerUnitStepDownCycle"];
    NSInteger sdcCount = [stepDownCycle count];
    NSInteger sdcIndex = NSNotFound;
    CGFloat sdcValue = 1.0;

    [_backgroundColor set];
    NSRectFill(rect);

    if (page) {
        NSRect frame = [self convertRect:[page bounds] fromView:page];
        NSRect pageBounds = [page bounds];
        CGFloat tickHeight = rulerBounds.size.height;
        CGFloat tickStep = tickConversionFactor;
        CGFloat pageScale = [page frame].size.width / [page bounds].size.width;

        if (self.accessoryView != nil) {
            if (self.orientation == NSHorizontalRuler) {
                CGFloat offset = self.accessoryView.frame.size.height + ACCESSORY_MARGIN;

                tickHeight -= offset;
            }
        }

        [_rulerBackgroundColor set];
        if (self.accessoryView != nil) {
            NSRectFill((NSRect){{frame.origin.x, self.frame.size.height - (tickHeight + ACCESSORY_MARGIN)}, {frame.size.width, tickHeight + ACCESSORY_MARGIN}});
        }
        [_tickColor set];
        NSRectFill((NSRect){{frame.origin.x, 0.0}, {1.0, pageBounds.size.height}});
        NSRectFill((NSRect){{frame.origin.x + frame.size.width, 0.0}, {1.0, pageBounds.size.height}});

        [_rulerMarginBackgroundColor set];
        for (NSValue *rangeValue in [page horizontalMarginRanges]) {
            NSRange range = [rangeValue rangeValue];
            frame = [page frame];
            frame.origin.x = range.location;
            frame.size.width = range.length;
            frame = [self convertRect:frame fromView:page];
            NSRectFill((NSRect){{frame.origin.x, 0.0}, {frame.size.width, pageBounds.size.height}});
        }

        do {
            for (CGFloat x = pageBounds.origin.x; x <= pageBounds.origin.x + pageBounds.size.width; x += tickStep) {
                NSRect tickRect = (NSRect){{x, pageBounds.origin.y}, {1.0, pageBounds.origin.y + tickHeight}};
                NSString *unit;
                NSPoint unitPoint;

                [_tickColor set];

                tickRect = [self convertRect:tickRect fromView:page];
                tickRect.origin.y = rulerBounds.origin.y + rulerBounds.size.height - tickHeight;
                tickRect.size.width = 1.0;
                tickRect.size.height = tickHeight;
                NSFrameRect([self centerScanRect:tickRect]);

                if (sdcIndex == NSNotFound) { // For now, only label the top most unit.
                    unit = [NSString stringWithFormat:@"%.0f", x / 72.0];
                    unitPoint.x = tickRect.origin.x + 3.0;
                    unitPoint.y = tickRect.origin.y - 2.0;
                    [unit drawAtPoint:unitPoint withAttributes:_unitAttributes];
                }
            }

            if (sdcIndex == NSNotFound) {
                tickHeight /= 2.0;
            } else {
                tickHeight -= 2.0;
                if (tickHeight < 2.0) {
                    tickHeight = 2.0;
                }
            }

            sdcIndex = sdcIndex == NSNotFound ? 0 : sdcIndex + 1;
            if (sdcIndex >= sdcCount) sdcIndex = sdcCount - 1;
            sdcValue = [[stepDownCycle objectAtIndex:sdcIndex] floatValue];

            tickStep *= sdcValue;

        } while (tickStep >= 5.0 / pageScale);
    }

    [_tickColor set];
    [NSBezierPath strokeLineFromPoint:(NSPoint){rulerBounds.origin.x, rulerBounds.origin.y + rulerBounds.size.height - 0.5} toPoint:(NSPoint){rulerBounds.origin.x + rulerBounds.size.width, rulerBounds.origin.y + rulerBounds.size.height - 0.5}];
}

- (void)drawVerticalRulerInRect:(NSRect)rect {
    NSRect rulerBounds = [self bounds];
    DrawPage *page = (DrawPage *)[self clientView];
    NSDictionary *ticks = [NSRulerView _registrationDictionaryForUnitNamed:[self measurementUnits]];
    CGFloat tickConversionFactor = [[ticks objectForKey:@"NSRulerUnitConversionFactor"] floatValue];
    NSArray *stepDownCycle = [ticks objectForKey:@"NSRulerUnitStepDownCycle"];
    NSInteger sdcCount = [stepDownCycle count];
    NSInteger sdcIndex = NSNotFound;
    CGFloat sdcValue = 1.0;

    [_backgroundColor set];
    NSRectFill(rect);

    if (page) {
        NSRect frame = [self convertRect:[page bounds] fromView:page];
        NSRect pageBounds = [page bounds];
        CGFloat tickHeight = rulerBounds.size.width;
        CGFloat tickStep = tickConversionFactor;
        CGFloat pageScale = page.scale;

        [_rulerBackgroundColor set];
        NSRectFill((NSRect){{0.0, frame.origin.y}, {pageBounds.size.width, frame.size.height}});

        [_rulerMarginBackgroundColor set];
        for (NSValue *rangeValue in [page verticalMarginRanges]) {
            NSRange range = [rangeValue rangeValue];
            frame = [page frame];
            frame.origin.y = range.location;
            frame.size.height = range.length;
            frame = [self convertRect:frame fromView:page];
            NSRectFill((NSRect){{0.0, frame.origin.y}, {pageBounds.size.width, frame.size.height}});
        }

        do {
            for (CGFloat y = pageBounds.origin.y; y <= pageBounds.origin.y + pageBounds.size.height; y += tickStep) {
                NSRect tickRect = (NSRect){{0.0, y}, {1.0, 1.0}};
                NSString *unit;
                NSPoint unitPoint;

                [_tickColor set];

                tickRect = [self convertRect:tickRect fromView:page];
                //tickRect.origin.y += 1.0;
                tickRect.origin.x = rulerBounds.origin.x + rulerBounds.size.width - tickHeight;
                tickRect.size.width = tickHeight;
                tickRect.size.height = 1.0;
                NSFrameRect([self centerScanRect:tickRect]);

                if (sdcIndex == NSNotFound) { // For now, only label the top most unit.
                    [NSGraphicsContext saveGraphicsState];
                    unit = [NSString stringWithFormat:@"%.0f", y / 72.0];
                    unitPoint.x = tickRect.origin.x + 3.0;
                    unitPoint.y = tickRect.origin.y - 2.0;
                    [NSAffineTransform translateXBy:unitPoint.x yBy:unitPoint.y];
                    [NSAffineTransform rotateByDegrees:-90.0];
                    [NSAffineTransform translateXBy:0.0 yBy:-4.0];
                    [unit drawAtPoint:NSZeroPoint withAttributes:_unitAttributes];
                    [NSGraphicsContext restoreGraphicsState];
                }
            }

            if (sdcIndex == NSNotFound) {
                tickHeight /= 2.0;
            } else {
                tickHeight -= 2.0;
                if (tickHeight < 2.0) {
                    tickHeight = 2.0;
                }
            }

            sdcIndex = sdcIndex == NSNotFound ? 0 : sdcIndex + 1;
            if (sdcIndex >= sdcCount) sdcIndex = sdcCount - 1;
            sdcValue = [[stepDownCycle objectAtIndex:sdcIndex] floatValue];

            tickStep *= sdcValue;
        } while (tickStep >= 5.0 / pageScale);

        frame = [self convertRect:[page bounds] fromView:page];
        [_tickColor set];
        NSRectFill((NSRect){{0.0, frame.origin.y}, {pageBounds.size.width, 1.0}});
        NSRectFill((NSRect){{0.0, frame.origin.y + frame.size.height}, {pageBounds.size.height, 1.0}});
    }

    [_tickColor set];
    [NSBezierPath strokeLineFromPoint:(NSPoint){rulerBounds.origin.x + rulerBounds.size.width - 0.5, rulerBounds.origin.y} toPoint:(NSPoint){rulerBounds.origin.x + rulerBounds.size.width - 0.5, rulerBounds.origin.y + rulerBounds.size.height}];
}

- (void)drawHashMarksAndLabelsInRect:(NSRect)rect {
    if ([self orientation] == NSHorizontalRuler) {
        [self drawHorizontalRulerInRect:rect];
    } else {
        [self drawVerticalRulerInRect:rect];
    }
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
    [_backgroundColor set];
    NSRectFill(dirtyRect);
}

- (void)drawRect:(NSRect)dirtyRect {
    [self drawBackgroundInRect:dirtyRect];
    [self drawHashMarksAndLabelsInRect:dirtyRect];
    if ([[self markers] count]) {
        [self drawMarkersInRect:dirtyRect];
    }
}

- (CGFloat)baselineLocation {
    NSRect	bounds = [self bounds];

    if ([self orientation] == NSHorizontalRuler) {
        return bounds.origin.y + bounds.size.height;
    } else {
        return bounds.origin.x + bounds.size.width;
    }
}

- (void)setRuleThickness:(CGFloat)thickness {
    [super setRuleThickness:RULE_THICKNESS];
}

- (CGFloat)ruleThickness {
    return RULE_THICKNESS;
}

- (CGFloat)requiredThickness {
    CGFloat thickness = RULE_THICKNESS + MARKER_THICKNESS;

    if ([self accessoryView] != nil) {
        if (self.orientation == NSHorizontalRuler) {
            thickness += self.accessoryView.frame.size.height + ACCESSORY_MARGIN;
        } else {
            thickness += self.accessoryView.frame.size.width + ACCESSORY_MARGIN;
        }
    }

    return thickness;
}

- (void)setReservedThicknessForMarkers:(CGFloat)thickness {
    [super setReservedThicknessForMarkers:MARKER_THICKNESS];
}

- (CGFloat)reservedThicknessForMarkers {
    return MARKER_THICKNESS;
}

- (void)setReservedThicknessForAccessoryView:(CGFloat)thickness {
    [super setReservedThicknessForAccessoryView:0.0];
}

- (CGFloat)reservedThicknessForAccessoryView {
    return 0.0;
}

- (void)setClientView:(NSView *)client {
    [super setClientView:client];

    if ([[self clientView] respondsToSelector:@selector(rulerViewDidSetClientView:)]) {
        [(id <DrawRulerViewClient>)[self clientView] rulerViewDidSetClientView:self];
    }
}

#pragma mark - NSResponder

- (void)mouseDown:(NSEvent *)event {
    NSPoint where = [self convertPoint:[event locationInWindow] fromView:nil];
    NSRulerMarker *marker = [self markerAtPoint:where];

    if (marker) {
        [marker trackMouse:event adding:NO];
    } else {
        if ([[self clientView] respondsToSelector:@selector(rulerView:handleMouseDown:)]) {
            [[self clientView] rulerView:self handleMouseDown:event];
        }
    }
}

@end
