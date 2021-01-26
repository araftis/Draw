
#import "DrawDocument.h"

#import "DrawDocumentStorage.h"
#import "DrawRulerMarker.h"
#import "DrawViewRulerAccessory.h"

#import <AJRInterface/AJRInterface.h>
#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

@implementation DrawDocument (Rulers)

- (NSUInteger)_indexForLocation:(CGFloat)location in:(NSArray<NSNumber *> *)locations {
    for (NSInteger x = 0; x < locations.count; x++) {
        if (AJRApproximateEquals(location, locations[x].doubleValue, 3)) {
            return x;
        }
    }
    return NSNotFound;
}

- (NSArray<NSNumber *> *)horizontalMarks {
    return _storage.horizontalMarks;
}

- (void)addHorizontalGuideAtLocation:(CGFloat)offset {
    NSUInteger index = [self _indexForLocation:offset in:_storage.horizontalMarks];
    if (index == NSNotFound) {
        [_storage.horizontalMarks addObject:@(offset)];
        [self setPagesNeedDisplay:YES];
    }
}

- (void)removeHorizontalGuideAtLocation:(CGFloat)offset {
    NSUInteger index = [self _indexForLocation:offset in:_storage.horizontalMarks];
    if (index != NSNotFound) {
        [_storage.horizontalMarks removeObjectAtIndex:index];
        [self setPagesNeedDisplay:YES];
    }
}

- (void)moveHorizontalGuideAtLocation:(CGFloat)oldLocation to:(CGFloat)newLocation {
    NSUInteger index = [self _indexForLocation:oldLocation in:_storage.horizontalMarks];
    if (index != NSNotFound) {
        [_storage.horizontalMarks replaceObjectAtIndex:index withObject:@(newLocation)];
        [self setPagesNeedDisplay:YES];
    }
}

- (NSArray<NSNumber *> *)verticalMarks {
    return _storage.verticalMarks;
}

- (void)addVerticalGuideAtLocation:(CGFloat)offset {
    NSUInteger index = [self _indexForLocation:offset in:_storage.verticalMarks];
    if (index == NSNotFound) {
        [_storage.verticalMarks addObject:@(offset)];
        [self setPagesNeedDisplay:YES];
    }
}

- (void)removeVerticalGuideAtLocation:(CGFloat)offset {
    NSUInteger index = [self _indexForLocation:offset in:_storage.verticalMarks];
    if (index != NSNotFound) {
        [_storage.verticalMarks removeObjectAtIndex:index];
        [self setPagesNeedDisplay:YES];
    }
}

- (void)moveVerticalGuideAtLocation:(CGFloat)oldLocation to:(CGFloat)newLocation {
    NSUInteger index = [self _indexForLocation:oldLocation in:_storage.verticalMarks];
    if (index != NSNotFound) {
        [_storage.verticalMarks replaceObjectAtIndex:index withObject:@(newLocation)];
        [self setPagesNeedDisplay:YES];
    }
}

- (void)toggleRuler:(id)sender {
    NSScrollView    *scrollView = [self.pagedView enclosingScrollView];
    
    [scrollView setRulersVisible:![scrollView rulersVisible]];

    [[NSUserDefaults standardUserDefaults] setBool:[scrollView rulersVisible] forKey:DrawRulersVisibleKey];
}

- (void)setMarkColor:(NSColor *)aColor {
    if (_storage.markColor != aColor) {
        [self registerUndoWithTarget:self selector:@selector(setMarkColor:) object:_storage.markColor];

        _storage.markColor = aColor;

        [[NSUserDefaults standardUserDefaults] setColor:_storage.markColor forKey:@"MarkColor"];
        [self setPagesNeedDisplay:YES];
    }
}

- (NSColor *)markColor {
    return _storage.markColor;
}

- (IBAction)toggleMarks:(id)sender {
    [self setMarksVisible:![self marksVisible]];
}

- (void)setMarksVisible:(BOOL)flag {
    if (flag != _storage.marksVisible) {
        _storage.marksVisible = flag;
        [self setPagesNeedDisplay:YES];
    }
}

- (BOOL)marksVisible {
    return _storage.marksVisible;
}

- (void)toggleSnapToMarks:(id)sender {
    [self setMarksEnabled:![self marksEnabled]];
}

- (void)setMarksEnabled:(BOOL)flag {
    if (_storage.marksEnabled != flag) {
        _storage.marksEnabled = flag;
    }
}

- (BOOL)marksEnabled {
    return _storage.marksEnabled;
}

- (void)objectDidResignRuler:(NSNotification *)notification {
    //   [self viewWillMoveToSuperview:[self superview]];
}

- (void)_updateMarginsForRuler:(NSRulerView *)rulerView {
    NSString *name;
    NSSize paperSize = [[self printInfo] paperSize];

    for (NSRulerMarker *marker in [rulerView markers]) {
        name = [[marker image] name];
        if ([name isEqualToString:@"MarginBottom"]) {
            [marker setMarkerLocation:paperSize.height - [[self printInfo] bottomMargin]];
        } else if ([name isEqualToString:@"MarginLeft"]) {
            [marker setMarkerLocation:[[self printInfo] leftMargin]];
        } else if ([name isEqualToString:@"MarginRight"]) {
            [marker setMarkerLocation:paperSize.width - [[self printInfo] rightMargin]];
        } else if ([name isEqualToString:@"MarginTop"]) {
            [marker setMarkerLocation:[[self printInfo] topMargin]];
        }
    }
}

- (void)updateRulers {
    [self _updateMarginsForRuler:[[self.pagedView enclosingScrollView] horizontalRulerView]];
    [self _updateMarginsForRuler:[[self.pagedView enclosingScrollView] verticalRulerView]];
}

@end
