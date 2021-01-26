
#import "DrawDocument.h"

#import "DrawDocumentStorage.h"
#import "DrawPage.h"
#import "DrawViewRulerAccessory.h"

#import <AJRFoundation/AJRFoundation.h>
#import <AJRInterface/AJRInterface.h>
#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

@implementation DrawDocument (Grid)

static inline CGFloat SNAP(CGFloat a, CGFloat b) {
    //AJRPrintf(@"Snap %.3f to spacing %.3f = %.3f\n", a, b, rint(rint((a / b) * 10000.0) / 10000.0) * b);
    return rint(rint((a / b) * 10000.0) / 10000.0) * b;
}

- (void)updateGrid {
    NSInteger x, y, i;
    short w, h;
    NSRect bounds = {{0.0, 0.0}, [[self printInfo] paperSize]};

    if (_storage.gridSpacing <= (0.1 * [self scale])) return;

    x = (NSInteger)floor(bounds.size.width / _storage.gridSpacing);
    y = (NSInteger)floor(bounds.size.height / _storage.gridSpacing);

    if (_grid) {
        [_grid removeAllPoints];
    } else {
        _grid = [[AJRBezierPath alloc] init];
        [_grid setLineWidth:AJRHairLineWidth];
    }
    w = bounds.size.width;
    h = bounds.size.height;
    for (i = 1; i <= y; i++) {
        [_grid moveToPoint:(NSPoint){0, i * _storage.gridSpacing}];
        [_grid lineToPoint:(NSPoint){w, i * _storage.gridSpacing}];
    }
    for (i = 1; i <= x; i++) {
        [_grid moveToPoint:(NSPoint){i * _storage.gridSpacing, 0}];
        [_grid lineToPoint:(NSPoint){i * _storage.gridSpacing, h}];
    }

    [self.gridSegments setSelected:self.gridVisible forSegment:0];
    [self.gridSegments setSelected:self.gridEnabled forSegment:1];
}

- (NSPoint)snapPointToGrid:(NSPoint)point {
    if (!_storage.gridEnabled) {
        if (_storage.marksEnabled) {
            NSInteger x;
            CGFloat position;
            CGFloat scale = [(DrawPage *)[_storage.pages lastObject] scale];
            CGFloat offset = 3.0 / scale;

            for (x = 0; x < (const NSInteger)[_storage.verticalMarks count]; x++) {
                position = [[_storage.verticalMarks objectAtIndex:x] doubleValue];
                if ((position >= point.y - offset) && (position <= point.y + offset)) {
                    point.y = position;
                }
            }
            position = [[self printInfo] bottomMargin];
            if ((position >= point.y - offset) && (position <= point.y + offset)) {
                point.y = position;
            }
            position = [[self printInfo] paperSize].height - [[self printInfo] topMargin];
            if ((position >= point.y - offset) && (position <= point.y + offset)) {
                point.y = position;
            }
            for (x = 0; x < (const NSInteger)[_storage.horizontalMarks count]; x++) {
                position = [[_storage.horizontalMarks objectAtIndex:x] doubleValue];
                if ((position >= point.x - offset) && (position <= point.x + offset)) {
                    point.x = position;
                }
            }
            position = [[self printInfo] leftMargin];
            if ((position >= point.x - offset) && (position <= point.x + offset)) {
                point.x = position;
            }
            position = [[self printInfo] paperSize].width - [[self printInfo] rightMargin];
            if ((position >= point.x - offset) && (position <= point.x + offset)) {
                point.x = position;
            }
        }
        return point;
    }

    return (NSPoint){SNAP(point.x, _storage.gridSpacing), SNAP(point.y, _storage.gridSpacing)};
}

- (CGFloat)snapLocationToGrid:(CGFloat)location {
    if (_storage.gridEnabled) {
        return SNAP(location, _storage.gridSpacing);
    }

    return location;
}

- (NSSize)snapSizeToGrid:(NSSize)size {
    NSPoint	work;

    work.x = size.width;
    work.y = size.height;
    work = [self snapPointToGrid:work];

    return (NSSize){work.x, work.y};
}

- (NSRect)snapRectToGrid:(NSRect)rect {
    rect.origin = [self snapPointToGrid:rect.origin];
    rect.size = [self snapSizeToGrid:rect.size];

    return rect;
}

/* Methods to modify the grid of the DrawView. */

- (IBAction)takeGridStateFrom:(NSSegmentedControl *)sender {
    [self setGridVisible:[sender isSelectedForSegment:0]];
    [NSUserDefaults.standardUserDefaults setBool:self.gridVisible forKey:DrawGridVisibleKey];
    [self setGridEnabled:[sender isSelectedForSegment:1]];
    [NSUserDefaults.standardUserDefaults setBool:self.gridEnabled forKey:DrawGridEnabledKey];
}

- (IBAction)toggleGridVisible:(id)sender {
    [self setGridVisible:![self gridVisible]];
    [NSUserDefaults.standardUserDefaults setBool:self.gridVisible forKey:DrawGridVisibleKey];
}

- (void)setGridEnabled:(BOOL)flag {
    if (_storage.gridEnabled != flag) {
        [[self prepareUndoWithInvocation] setGridEnabled:!flag];
        _storage.gridEnabled = flag;
    }
}

- (BOOL)gridEnabled {
    return _storage.gridEnabled;
}

- (void)setGridVisible:(BOOL)flag {
    if (_storage.gridVisible != flag) {
        [[self prepareUndoWithInvocation] setGridEnabled:!flag];
        _storage.gridVisible = flag;
        [self updateGrid];
        [self setPagesNeedDisplay:YES];
    }
}

- (BOOL)gridVisible {
    return _storage.gridVisible;
}

- (void)setGridColor:(NSColor *)aColor {
    if (aColor != _storage.gridColor) {
        [self registerUndoWithTarget:self selector:@selector(setGridColor:) object:_storage.gridColor];

        _storage.gridColor = aColor;

        [[NSUserDefaults standardUserDefaults] setColor:_storage.gridColor forKey:@"GridColor"];
        if (_storage.gridVisible) [self setPagesNeedDisplay:YES];
    }
}

- (NSColor *)gridColor {
    return _storage.gridColor;
}

- (void)setGridSpacing:(CGFloat)aGridSpacing {
    if (aGridSpacing != _storage.gridSpacing) {
        [(DrawDocument *)[self prepareWithInvocationTarget:self] setGridSpacing:_storage.gridSpacing];

        if (aGridSpacing < 0.1) aGridSpacing = 0.1;
        if (aGridSpacing > 256.0) aGridSpacing = 256.0;

        _storage.gridSpacing = aGridSpacing;

        [self updateGrid];

        if (_storage.gridVisible) [self setPagesNeedDisplay:YES];
    }
}

- (CGFloat)gridSpacing {
    return _storage.gridSpacing;
}

- (void)drawGridInRect:(NSRect)rect inView:(NSView *)page {
    if (_storage.gridVisible && (_storage.gridSpacing * [self scale]) > 3.0) {
        CGFloat	scale = [self scale];

        [_storage.gridColor set];
        [_grid setStrokePointTransform:^(NSPoint point) {
            NSRect	rect = (NSRect){point, {1.0, 1.0}};
            CGFloat	offset = (1.0 / scale) / 2.0;
            rect = [page centerScanRect:rect];
            return (NSPoint){rect.origin.x - offset, rect.origin.y - offset};
        }];
        [_grid stroke];
        [_grid setStrokePointTransform:NULL];
    }
}

@end
