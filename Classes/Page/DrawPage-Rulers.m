/*
 DrawPage-Rulers.m
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

#import "DrawPage.h"

#import "DrawRulerMarker.h"
#import "DrawDocument.h"
#import "DrawDocumentStorage.h"
#import "DrawViewRulerAccessory.h"

#import <AJRInterface/AJRInterface.h>

@interface DrawPage (PrivateUndoRedo)

- (void)rulerView:(NSRulerView *)rulerView addMarker:(NSRulerMarker *)marker;
- (void)rulerView:(NSRulerView *)rulerView removeMarker:(NSRulerMarker *)marker;

@end

@interface DrawPage (Retype)
- (DrawDocument *)superview;
@end

@interface DrawPage()

@property (nonatomic,assign) CGFloat oldMarkerLocation;

@end


@implementation DrawPage (Rulers)

- (void)_updateMarkersForRulerView:(NSRulerView *)rulerView {
    NSArray<NSNumber *> *marks;
    DrawRulerMarker *marker;
    NSSize paperSize = [_document.paper sizeForOrientation:_document.orientation];

    if ([rulerView orientation] == NSHorizontalRuler) {
        marks = _document.storage.horizontalMarks;

        [rulerView setMarkers:nil];

        marker = [[DrawRulerMarker alloc] initWithRulerView:rulerView markerLocation:_document.margins.left image:[AJRImages imageNamed:@"marginLeftMarker" forObject:self] imageOrigin:(NSPoint){4.0, 0.0}];
        [marker setMovable:YES];
        [marker setRemovable:NO];
        [rulerView addMarker:marker];

        marker = [[DrawRulerMarker alloc] initWithRulerView:rulerView markerLocation:paperSize.width - _document.margins.right image:[AJRImages imageNamed:@"marginRightMarker" forObject:self] imageOrigin:(NSPoint){0.0, 0.0}];
        [marker setMovable:YES];
        [marker setRemovable:NO];
        [rulerView addMarker:marker];
    } else {
        marks = _document.storage.verticalMarks;

        [rulerView setMarkers:nil];

        marker = [[DrawRulerMarker alloc] initWithRulerView:rulerView markerLocation:[self isFlipped] ? paperSize.height - _document.margins.bottom : _document.margins.bottom image:[AJRImages imageNamed:@"marginBottomMarker" forObject:self] imageOrigin:(NSPoint){15.0, [self isFlipped] ? 5.0 : 4.0}];
        [marker setMovable:YES];
        [marker setRemovable:NO];
        [rulerView addMarker:marker];

        marker = [[DrawRulerMarker alloc] initWithRulerView:rulerView markerLocation:[self isFlipped] ? _document.margins.top : paperSize.height - _document.margins.top image:[AJRImages imageNamed:@"marginTopMarker" forObject:self] imageOrigin:(NSPoint){15.0, [self isFlipped] ? 1.0 : 0.0}];
        [marker setMovable:YES];
        [marker setRemovable:NO];
        [rulerView addMarker:marker];
    }

    for (NSNumber *location in marks) {
        [rulerView addMarker:[self guideMarkerAtLocation:location.doubleValue in:rulerView]];
    }
}

- (DrawRulerMarker *)guideMarkerAtLocation:(CGFloat)location in:(NSRulerView *)rulerView {
    NSImage *image;
    NSPoint hotSpot;
    DrawRulerMarker *marker;

    if (rulerView.orientation == NSHorizontalRuler) {
        image = [AJRImages imageNamed:@"guideMarkerH" forObject:self];
        hotSpot = (NSPoint){6.0, -1.0};
    } else {
        image = [AJRImages imageNamed:@"guideMarkerV" forObject:self];
        hotSpot = (NSPoint){8.0, 7.0};
    }

    marker = [[DrawRulerMarker alloc] initWithRulerView:rulerView markerLocation:location image:image imageOrigin:hotSpot];
    marker.movable = YES;
    marker.removable = YES;

    return marker;
}

- (void)rulerViewDidSetClientView:(NSRulerView *)rulerView; {
    if (rulerView) {
        [self _updateMarkersForRulerView:rulerView];
    }
}

- (void)rulerView:(NSRulerView *)rulerView handleMouseDown:(NSEvent *)event {
    NSRulerMarker *newMarker;
    CGFloat position;
    NSImage *image;
    NSPoint hotSpot;

    hotSpot = [self convertPoint:[event locationInWindow] fromView:nil];

    if ([rulerView orientation] == NSHorizontalRuler) {
        image = [AJRImages imageNamed:@"guideMarkerH" forObject:self];
        position = hotSpot.x;
        hotSpot = (NSPoint){6.0, 0.0};
    } else {
        image = [AJRImages imageNamed:@"guideMarkerV" forObject:self];
        position = hotSpot.y;
        hotSpot = (NSPoint){8.0, 6.0};
    }

    newMarker = [[DrawRulerMarker alloc] initWithRulerView:rulerView markerLocation:position image:image imageOrigin:hotSpot];
    [newMarker setMovable:YES];
    [newMarker setRemovable:YES];
    [rulerView addMarker:newMarker];

    [newMarker trackMouse:event adding:YES];
}

- (CGFloat)rulerView:(NSRulerView *)rulerView willMoveMarker:(NSRulerMarker *)marker toLocation:(CGFloat)location {
    NSString *name = [[marker image] name];

    AJRLogDebug(@"name: %@\n", name);

    if ([name hasPrefix:@"margin"]) {
        NSSize paperSize = [_document.paper sizeForOrientation:_document.orientation];
        CGFloat min, max;
        if ([name isEqualToString:@"marginLeftMarker"]) {
            min = 0.0;
            max = paperSize.width - _document.margins.right - 18.0;
        } else if ([name isEqualToString:@"marginRightMarker"]) {
            min = _document.margins.left + 18.0;
            max = paperSize.width;
        } else if ([name isEqualToString:@"marginTopMarker"]) {
            if ([self isFlipped]) {
                min = 0.0;
                max = paperSize.height - _document.margins.bottom - 18.0;
            } else {
                min = _document.margins.bottom + 18.0;
                max = paperSize.height;
            }
        } else if ([name isEqualToString:@"marginBottomMarker"]) {
            if ([self isFlipped]) {
                min = _document.margins.top + 18.0;
                max = paperSize.height;
            } else {
                min = 0.0;
                max = paperSize.height - _document.margins.top - 18.0;
            }
        } else {
            min = 0.0;
            max = MIN(paperSize.width, paperSize.height);
        }

        if (location < min) {
            return min;
        }
        if (location > max) {
            return max;
        }

        return location;
    }

    return [_document snapLocationToGrid:location];
}

- (void)rulerView:(NSRulerView *)rulerView addMarker:(NSRulerMarker *)marker {
    [rulerView addMarker:marker];
    [self rulerView:rulerView didAddMarker:marker];
    [[self enclosingScrollView] setNeedsDisplay:YES];
}

- (void)rulerView:(NSRulerView *)rulerView didAddMarker:(NSRulerMarker *)marker {
    [[_document prepareWithInvocationTarget:self] rulerView:rulerView removeMarker:marker];

    if ([rulerView orientation] == NSHorizontalRuler) {
        [_document addHorizontalGuideAtLocation:marker.markerLocation];
    } else {
        [_document addVerticalGuideAtLocation:marker.markerLocation];
    }

    [[self enclosingScrollView] setNeedsDisplay:YES];
}

// This isn't thread safe, but then this app isn't threaded in anyway.
- (void)setOldMarkerLocation:(CGFloat)oldMarkerLocation {
    [self setInstanceObject:@(oldMarkerLocation) forKey:@"oldMarkerLocation"];
}

- (CGFloat)oldMarkerLocation {
    return [[self instanceObjectForKey:@"oldMarkerLocation"] doubleValue];
}

- (void)setMarker:(NSRulerMarker *)marker inRulerView:(NSRulerView *)rulerView toLocation:(CGFloat)location {
    [[_document prepareWithInvocationTarget:self] setMarker:marker inRulerView:rulerView toLocation:[marker markerLocation]];
    [marker setMarkerLocation:location];
    [self rulerView:nil didMoveMarker:marker];
    [rulerView setNeedsDisplay:YES];
}

- (void)rulerView:(NSRulerView *)rulerView didMoveMarker:(NSRulerMarker *)marker {
    NSString *name = [[marker image] name];
    NSSize paperSize = [_document.paper sizeForOrientation:_document.orientation];

    if ([name hasPrefix:@"margin"]) {
        if ([name isEqualToString:@"marginLeftMarker"]) {
            self.document.leftMargin = marker.markerLocation;
            [self.enclosingScrollView.horizontalRulerView setNeedsDisplay:YES];
        } else if ([name isEqualToString:@"marginRightMarker"]) {
            self.document.rightMargin = paperSize.width - marker.markerLocation;
            [self.enclosingScrollView.horizontalRulerView setNeedsDisplay:YES];
        } else if ([name isEqualToString:@"marginTopMarker"]) {
            if ([self isFlipped]) {
                self.document.topMargin = marker.markerLocation;
            } else {
                self.document.topMargin = paperSize.height - marker.markerLocation;
            }
            [self.enclosingScrollView.verticalRulerView setNeedsDisplay:YES];
        } else if ([name isEqualToString:@"marginBottomMarker"]) {
            if ([self isFlipped]) {
                self.document.bottomMargin = paperSize.height - marker.markerLocation;
            } else {
                self.document.bottomMargin = marker.markerLocation;
            }
            [self.enclosingScrollView.verticalRulerView setNeedsDisplay:YES];
        }
        [self.document setPagesNeedDisplay:YES];
    } else if ([name hasPrefix:@"guide"]) {
        if (rulerView.orientation == NSHorizontalRuler) {
            [_document moveHorizontalGuideAtLocation:self.oldMarkerLocation to:marker.markerLocation];
        } else {
            [_document moveVerticalGuideAtLocation:self.oldMarkerLocation to:marker.markerLocation];
        }
    }

    [[self enclosingScrollView] setNeedsDisplay:YES];
}

- (BOOL)rulerView:(NSRulerView *)rulerView shouldMoveMarker:(NSRulerMarker *)marker {
    [[_document prepareWithInvocationTarget:self] setMarker:marker inRulerView:rulerView toLocation:[marker markerLocation]];

    self.oldMarkerLocation = marker.markerLocation;

    return YES;
}

- (void)rulerView:(NSRulerView *)rulerView removeMarker:(NSRulerMarker *)marker {
    [rulerView removeMarker:marker];
    [self rulerView:rulerView didRemoveMarker:marker];
    [rulerView setNeedsDisplay:YES];
}

- (void)rulerView:(NSRulerView *)rulerView didRemoveMarker:(NSRulerMarker *)marker {
    [[_document prepareWithInvocationTarget:self] rulerView:rulerView addMarker:marker];

    if ([rulerView orientation] == NSHorizontalRuler) {
        [_document removeHorizontalGuideAtLocation:self.oldMarkerLocation];
    } else {
        [_document removeVerticalGuideAtLocation:self.oldMarkerLocation];
    }

    [[self enclosingScrollView] setNeedsDisplay:YES];
}

- (NSArray *)horizontalMarginRanges {
    NSSize paperSize = [_document.paper sizeForOrientation:_document.orientation];

    return [NSArray arrayWithObjects:
            [NSValue valueWithRange:(NSRange){0, _document.margins.left}],
            [NSValue valueWithRange:(NSRange){paperSize.width - _document.margins.right, _document.margins.right}],
            nil];
}

- (NSArray *)verticalMarginRanges {
    NSSize paperSize = [_document.paper sizeForOrientation:_document.orientation];

    if (self.isFlipped) {
        return [NSArray arrayWithObjects:
                [NSValue valueWithRange:(NSRange){paperSize.height - _document.margins.bottom, _document.margins.bottom}],
                [NSValue valueWithRange:(NSRange){0, _document.margins.top}],
                nil];
    } else {
        return [NSArray arrayWithObjects:
                [NSValue valueWithRange:(NSRange){paperSize.height - _document.margins.top, _document.margins.top}],
                [NSValue valueWithRange:(NSRange){0, _document.margins.bottom}],
                nil];
    }
}

//- (CGFloat)rulerView:(NSRulerView *)ruler locationForPoint:(NSPoint)clientPoint
//{
//	CGFloat	location;
//	
//	if ([ruler orientation] == NSHorizontalRuler) {
//		location = [ruler convertPoint:clientPoint fromView:self].x;
//	} else {
//		location = [ruler convertPoint:clientPoint fromView:self].y;
//	}
//	
//	NSLog(@"locationForPoint:%P, %.1f\n", clientPoint, location);
//	
//	return location;
//}

//- (NSPoint)rulerView:(NSRulerView *)ruler pointForLocation:(CGFloat)location
//{
//	NSPoint		point = (NSPoint){location, location};
//	NSPoint		result;
//	
//	if ([ruler orientation] == NSHorizontalRuler) {
//		result = [ruler convertPoint:point toView:self];
//	} else {
//		result = [ruler convertPoint:point toView:self];
//	}
//	
//	NSLog(@"pointForLocation: %P, %.1f\n", point, location);
//	
//	return point;
//}

@end
