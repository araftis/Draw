/*
 DrawPage.m
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

#import "DrawFunctions.h"
#import "DrawGraphic.h"
#import "DrawLayer.h"
#import "DrawDocument.h"
#import "AJRXMLCoder-DrawExtensions.h"

#import <AJRInterface/AJRInterface.h>
#import <Draw/Draw-Swift.h>

const AJRInspectorIdentifier AJRInspectorIdentifierDrawPage = @"page";

@implementation DrawPage {
    NSMutableDictionary<NSString *, DrawGuestDrawer> *_guestDrawers;
}

static NSDictionary *_pageNumberAttributes = nil;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSTextAlignmentRight];
        _pageNumberAttributes = @{NSForegroundColorAttributeName:NSColor.disabledControlTextColor,
                                  NSParagraphStyleAttributeName:style};
    });
}

- (id)initWithDocument:(DrawDocument *)document {
    NSRect frame = {NSZeroPoint, [document.paper sizeForOrientation:document.orientation]};

    if ((self = [super initWithFrame:frame])) {
        [self setDocument:document];
        _layers = [[NSMutableDictionary alloc] init];
        _variableStore = [[AJRStore alloc] init];

        // Updating
        _changedGraphics = [[NSMutableArray alloc] init];

        // Observing myself... I do this so that I can post a single notification that I updated at the end of an event loop.
//        [AJRObserverCenter addObserver:self forObject:self];
//        [AJRObserverCenter notifyObserversObjectWillChange:nil];

        // Drag and Drop
        [self registerForDraggedTypes:[[DrawDocument draggedTypes] allKeys]];
        [self registerForDraggedTypes:[NSArray arrayWithObject:DrawGraphicPboardType]];

        // Variabes
        _variableStore = [[AJRStore alloc] init];
    }
    return self;
}

#pragma mark - Properties

- (NSColor *)paperColor {
    return _paperColor ?: _document.paperColor;
}

- (void)setPaperColor:(NSColor *)newColor {
    if (_paperColor != newColor) {
        NSColor *copy = _paperColor;
        [[self document] registerUndoWithTarget:self handler:^(id  _Nonnull target) {
            [target setPaperColor:copy];
        }];
        _paperColor = newColor;
        [self setNeedsDisplay:YES];
    }
}

- (void)setDocument:(DrawDocument *)document {
    _document = document;
    // Make sure all of our graphics will not point to the document.
    [_layers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSMutableArray<DrawGraphic *> *graphics, BOOL *stop) {
        for (DrawGraphic *graphic in graphics) {
            graphic.document = self->_document;
            graphic.page = self;
            graphic.layer = [self->_document layerWithName:key];
        }
    }];
    [_variableStore enumerate:^(NSString *name, id <AJREvaluation> value, BOOL *stop) {
        DrawVariable *variable = AJRObjectIfKindOfClass(value, DrawVariable);
        if (variable != nil) {
            variable.document = document;
            variable.page = self;
        }
    }];
}

@synthesize paper = _paper;

- (void)setPaper:(AJRPaper *)paper {
    if (_paper != paper) {
        _paper = paper;
        [self.document updateLayoutAndNotify:YES];
    }
}

- (AJRPaper *)paper {
    return _paper ?: self.document.paper;
}

#pragma mark - Graphics

- (void)addGraphic:(DrawGraphic *)graphic {
    [self addGraphic:graphic toLayer:nil];
}

- (void)addGraphic:(DrawGraphic *)graphic toLayer:(DrawLayer *)layer {
    [self addGraphic:graphic toLayer:layer select:NO byExtendingSelection:NO];
}

- (void)addGraphic:(DrawGraphic *)graphic select:(BOOL)select byExtendingSelection:(BOOL)byExtension; {
    [self addGraphic:graphic toLayer:nil select:select byExtendingSelection:byExtension];
}

- (void)addGraphic:(DrawGraphic *)graphic toLayer:(DrawLayer *)layer select:(BOOL)select byExtendingSelection:(BOOL)byExtension {
    NSMutableArray *graphics;
    DrawGraphic *focused;
    
    if (layer == nil) {
        layer = [_document layer];
    }

    graphics = [_layers objectForKey:[layer name]];
    focused = [_document focusedGroup];

    if (focused && ([focused layer] == layer)) {
        [focused addSubgraphic:graphic];
        if (![DrawGraphic notificationsAreDisabled]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:DrawDocumentDidAddGraphicNotification object:_document userInfo:[NSDictionary dictionaryWithObjectsAndKeys:graphic, DrawGraphicKey, nil]];
        }
        return;
    }
    
    [_document addGraphic:graphic];
    
    if (!graphics) {
        graphics = [[NSMutableArray alloc] init];
        [_layers setObject:graphics forKey:[layer name]];
    }
    
    [graphic graphicWillAddToPage:self];
    [graphics addObject:graphic];
    [graphic graphicDidAddToPage:self];
    
    [graphic setLayer:layer];
    [graphic setPage:self];

    if (select) {
        if (!byExtension) {
            [_document clearSelection];
        }
        [_document addGraphicToSelection:graphic];
    }
}

- (void)removeGraphic:(DrawGraphic *)graphic {
    if (graphic.layer == nil) {
        // This happens when an abandoned graphic, usually due to an error in related graphics, gets left around.
        for (NSString *layerName in _layers.keyEnumerator) {
            [_layers[layerName] removeObjectIdenticalTo:graphic];
        }
    } else {
        DrawLayer *layer = [graphic layer];
        NSMutableArray *graphics = [_layers objectForKey:[layer name]];

        if (!graphics) {
            [NSException raise:NSInvalidArgumentException format:@"Cannot remove graphic %@ because it's layer doesn't exist.", graphic];
        }

        [self setGraphicNeedsDisplayInRect:[graphic bounds]];

        [graphics removeObjectIdenticalTo:graphic];
    }
}

- (void)replaceGraphic:(DrawGraphic *)oldGraphic withGraphic:(DrawGraphic *)newGraphic; {
    DrawLayer *layer = [oldGraphic layer];
    NSMutableArray *graphics = [_layers objectForKey:[layer name]];
    NSUInteger index;
    
    if (!graphics) {
        [NSException raise:NSInvalidArgumentException format:@"Cannot remove graphic %@ because it's layer doesn't exist.", oldGraphic];
    }
    
    index = [graphics indexOfObjectIdenticalTo:oldGraphic];
    if (index != NSNotFound) {
        [graphics replaceObjectAtIndex:index withObject:newGraphic];
        [newGraphic setLayer:layer];
        [newGraphic setPage:self];
        [self setGraphicNeedsDisplayInRect:[oldGraphic bounds]];
    }
}

- (void)observeGraphic:(DrawGraphic *)graphic yesNo:(BOOL)yesNo {
    if (yesNo) {
    } else {
    }
}

#pragma mark - Drawing

- (void)drawPageNumber:(NSInteger)pageNumber inRect:(NSRect)rect {
    CGFloat pointSize = [NSFont systemFontSize] / _document.scale;
    NSMutableDictionary *attributes = [_pageNumberAttributes mutableCopy];

    attributes[NSFontAttributeName] = [NSFont boldSystemFontOfSize:pointSize];

    [@(pageNumber).description drawInRect:NSInsetRect(rect, 8.0, 8.0) withAttributes:attributes];
}

- (void)drawMarksInRect:(NSRect)rect {
    CGFloat position;
    NSRect markerRect;
    CGFloat scale = [self frame].size.width / [self bounds].size.width;

    if ([_document marksVisible]) {
        [[_document markColor] set];

        markerRect.origin.y = rect.origin.y;
        markerRect.size.width = 1.0 / scale;
        markerRect.size.height = rect.size.height;
        for (NSNumber *marker in [_document horizontalMarks]) {
            position = [marker doubleValue];
            if ((position >= rect.origin.x) && (position <= rect.origin.x + rect.size.width)) {
                markerRect.origin.x = position;
                markerRect = [self centerScanRect:markerRect];
                NSRectFill(markerRect);
            }
        }

        markerRect.origin.x = rect.origin.x;
        markerRect.size.width = rect.size.width;
        markerRect.size.height = 1.0 / scale;
        for (NSNumber *marker in [_document verticalMarks]) {
            position = [marker doubleValue];
            if ((position >= rect.origin.y) && (position <= rect.origin.y + rect.size.height)) {
                markerRect.origin.y = position;
                markerRect = [self centerScanRect:markerRect];
                NSRectFill(markerRect);
            }
        }
    }
}

- (void)drawPageMarkingsInRect:(NSRect)rect {
    // Draw the margins.
    NSColor *tempColor = [[NSUserDefaults standardUserDefaults] colorForKey:DrawMarginColorKey];
    if (!tempColor) {
        tempColor = NSColor.gridColor;
    }
    [tempColor set];
    NSSize paperSize = [_document.paper sizeForOrientation:_document.orientation];
    AJRInset margins = _document.margins;
    NSRect marginRect;
    marginRect.origin.x = margins.left;
    if (self.isFlipped) {
        marginRect.origin.y = margins.top;
    } else {
        marginRect.origin.y = margins.bottom;
    }
    marginRect.size.width = paperSize.width - (margins.left + margins.right);
    marginRect.size.height = paperSize.height - (margins.bottom + margins.top);
    marginRect = [self backingAlignedRect:marginRect options:NSAlignAllEdgesNearest];
    NSFrameRect(marginRect);

    // Draw the marks
    [self drawMarksInRect:rect];
}

- (BOOL)isFlipped {
    return YES;
}

- (BOOL)isPrinting {
    return [NSPrintInfo.sharedPrintInfo.dictionary[@"AJRIsPrinting"] boolValue];
}

- (void)drawRect:(NSRect)rect {
    NSRect bounds = [self bounds];
    BOOL isPrinting = [self.enclosingPagedView prepareViewForPrinting:self];
    
    if (!isPrinting) {
        // Draw the background.
        [self.paperColor set];
        NSRectFill([self centerScanRect:rect]);
        
        // Draw the Grid
        [_document drawGridInRect:bounds inView:self];
        
        // Draw Page Markings
        [self drawPageMarkingsInRect:bounds];

        // Draw the page number
        [self drawPageNumber:[_document pageNumberForPage:self] inRect:bounds];
    }
    
    // Finally, draw our actual graphics.
    for (DrawLayer *layer in [_document layers]) {
        if ([layer visible] && (!isPrinting || (isPrinting && [layer printable]))) {
            [self drawLayer:layer inRect:rect];
        }
    }

    if (isPrinting) {
        [NSColor.blackColor set];
        [[AJRBezierPath bezierPathWithRect:self.bounds] stroke];
    }
    
    // Finally, draw our guest drawers, if we have any.
    if (!isPrinting) {
        for (DrawGuestDrawer block in [_guestDrawers objectEnumerator]) {
            block(self, rect);
        }
    }
    
    [self.enclosingPagedView concludePrintingInView:self];
}

- (void)drawLayer:(DrawLayer *)layer inRect:(NSRect)rect {
    for (DrawGraphic *graphic in _layers[layer.name]) {
        if ([self needsToDrawRect:graphic.bounds]) {
            [graphic draw];
        }
    }
    
    if (!self.isPrinting) {
        // We don't draw handles when printing.
        for (DrawGraphic *graphic in [_document sortedSelection]) {
            if ([self needsToDrawRect:graphic.bounds]) {
                [graphic drawHandles];
            }
        }
    }
}

- (NSMutableArray<DrawGraphic *> *)graphicsForLayer:(DrawLayer *)layer {
    return _layers[layer.name];
}

- (NSArray<DrawGraphic *> *)graphicsHitByTest:(NSArray<DrawGraphic *> * (^)(DrawGraphic *graphic))graphicTest
                                   boundsTest:(BOOL (^)(DrawGraphic *graphic))boundsTest {
    NSArray<DrawGraphic *> *graphics;
    DrawGraphic *group = [_document focusedGroup];
    NSMutableArray<DrawGraphic *> *hitGraphics;

    // This prehaps isn't the most efficient method, but we're going to create an array of all the graphic underneath the mouse down. This will allow us to process the current selection in a fairly complex way. See below for details.
    hitGraphics = [[NSMutableArray alloc] init];

    // If we're drilled into a group, then we want to examine that group only.
    if (group) {
        graphics = graphicTest(group);
        if ([graphics count]) {
            [hitGraphics addObjectsFromArray:graphics];
        }
    } else {
        for (DrawLayer *layer in [[_document layers] reverseObjectEnumerator]) {
            if (![layer locked] && [layer visible]) {
                graphics = [self graphicsForLayer:layer];
                for (DrawGraphic *graphic in [[self graphicsForLayer:layer] reverseObjectEnumerator]) {
                    if (boundsTest(graphic)) {
                        [hitGraphics addObjectsFromArray:graphicTest(graphic)];
                    }
                }
            }
        }
    }

    return hitGraphics;
}

- (NSArray<DrawGraphic *> *)graphicsHitByPoint:(NSPoint)point {
    CGFloat adjustment = [self error];
    return [self graphicsHitByTest:^NSArray<DrawGraphic *> *(DrawGraphic *graphic) {
        return [graphic graphicsHitByPoint:point];
    } boundsTest:^BOOL(DrawGraphic *graphic) {
        return NSPointInRect(point, NSInsetRect([graphic bounds], -adjustment, -adjustment));
    }];
}

- (NSArray<DrawGraphic *> *)graphicsHitByRect:(NSRect)rect {
    CGFloat adjustment = [self error];
    return [self graphicsHitByTest:^NSArray<DrawGraphic *> *(DrawGraphic *graphic) {
        return [graphic graphicsHitByRect:rect];
    } boundsTest:^BOOL(DrawGraphic *graphic) {
        return NSIntersectsRect(rect, NSInsetRect([graphic bounds], -adjustment, -adjustment));
    }];
}

- (void)scheduleUpdate {
    if (!_hasScheduledUpdate) {
        [self performSelector:@selector(_scheduleUpdate) withObject:nil afterDelay:0.00001];
        _hasScheduledUpdate = YES;
    }
}

- (void)_scheduleUpdate {
    _hasScheduledUpdate = NO;
    [[self superview] setNeedsDisplay:YES];
}


- (void)objectWillChange:(id)anObject {
    if ([anObject isKindOfClass:[DrawLayer class]]) {
        [self scheduleUpdate];
    } else if (anObject == self) {
        if (!_selfDidUpdate) {
            _selfDidUpdate = YES;
            [self performSelector:@selector(postUpdateNotification) withObject:nil afterDelay:0.00001];
        }
    } else {
        [self graphicWillChange:anObject];
    }
}

- (void)graphicWillChange:(DrawGraphic *)graphic {
    //AJRPrintf(@"%@\n", NSStringFromRect([graphic bounds]));
    if (![_changedGraphics count]) {
        _updateRect = NSIntegralRect([graphic bounds]);
        [self performSelector:@selector(updateGraphics) withObject:nil afterDelay:0.00001];
    } else {
        _updateRect = NSIntegralRect(NSUnionRect(_updateRect, [graphic bounds]));
    }
    if ([_changedGraphics indexOfObjectIdenticalTo:graphic] == NSNotFound) {
        [_changedGraphics addObject:graphic];
    }
}

- (void)displayIntermediateResults {
    if ([_changedGraphics count]) {
        NSRect newUpdateRect = NSZeroRect;
        CGFloat adjustment = -3.0 / (self.frame.size.width / self.bounds.size.width);
        
        for (NSInteger x = 0; x < (const NSInteger)[_changedGraphics count]; x++) {
            DrawGraphic *graphic = [_changedGraphics objectAtIndex:x];
            if (x == 0) {
                newUpdateRect = [graphic bounds];
            } else {
                newUpdateRect = NSUnionRect(newUpdateRect, [graphic bounds]);
            }
        }
        
        [self displayRect:NSInsetRect(NSUnionRect(_updateRect, newUpdateRect), adjustment, adjustment)];
    }
}

- (void)updateGraphics {
    NSRect newUpdateRect = NSZeroRect;

    for (NSInteger x = 0; x < (const NSInteger)[_changedGraphics count]; x++) {
        if (x == 0) {
            newUpdateRect = [[_changedGraphics objectAtIndex:x] bounds];
        } else {
            newUpdateRect = NSUnionRect(newUpdateRect, [[_changedGraphics objectAtIndex:x] bounds]);
        }
    }
    
    [self setNeedsDisplayInRect:[self centerScanRect:NSUnionRect(_updateRect, newUpdateRect)]];
    
    [_changedGraphics removeAllObjects];
}

- (void)displayGraphicRect:(NSRect)rect {
    [self displayRect:[self centerScanRect:rect]];
}

- (void)setGraphicNeedsDisplayInRect:(NSRect)rect; {
    [self setNeedsDisplayInRect:[self centerScanRect:rect]];
}

- (void)postUpdateNotification {
    if (_selfDidUpdate) {
        _selfDidUpdate = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:DrawViewDidUpdateNotification object:self];
    }
}

- (CGFloat)scale {
    return self.frame.size.width / self.bounds.size.width;
}

- (CGFloat)error {
    return 0.5 / (self.frame.size.width / self.bounds.size.width);
}

- (void)setNeedsDisplayInRect:(NSRect)invalidRect {
    if ([DrawGraphic showsDirtyBounds]) {
        [super setNeedsDisplayInRect:[self bounds]];
    } else {
        [super setNeedsDisplayInRect:invalidRect];
    }
}

#pragma mark - Guest drawers

- (DrawDrawingToken)addGuestDrawer:(DrawGuestDrawer)drawer {
    if (_guestDrawers == nil) {
        _guestDrawers = [NSMutableDictionary dictionary];
    }

    NSString *token = NSProcessInfo.processInfo.globallyUniqueString;
    _guestDrawers[token] = drawer;

    return (__bridge void *)token;
}

- (void)removeGuestDrawer:(DrawDrawingToken)token {
    _guestDrawers[(__bridge NSString *)token] = nil;
}

#pragma mark - AJRnspection

- (NSArray<AJRInspectorIdentifier> *)inspectorIdentifiers {
    NSMutableArray *array = [[super inspectorIdentifiers] mutableCopy];
    [array addObject:AJRInspectorIdentifierDrawPage];
    return array;
}

#pragma mark - AJRXMLCoding

- (id)init {
    return [super init];
}

+ (NSString *)ajr_nameForXMLArchiving {
    return @"page";
}

- (id)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [coder decodeRectForKey:@"frame" setter:^(CGRect rect) {
        [self setFrame:rect];
    }];
    [coder decodeObjectForKey:@"layers" setter:^(id  _Nonnull object) {
        self->_layers = [object mutableCopy];
    }];
    [coder decodeObjectForKey:@"paperColor" setter:^(id  _Nonnull object) {
        self->_paperColor = object;
    }];
    [coder decodeObjectForKey:@"variableStore" setter:^(id  _Nullable object) {
        if (object == nil) {
            self->_variableStore = [[AJRStore alloc] init];
        } else {
            self->_variableStore = object;
        }
    }];

    return self;
}

- (id)finalizeXMLDecodingWithError:(NSError **)error {
    _hasScheduledUpdate = NO;
    _selfDidUpdate = NO;

    // Updating
    _changedGraphics = [[NSMutableArray alloc] init];

    // Observing myself... I do this so that I can post a single notification that I updated at the end of an event loop.
    //   [AJRObserverCenter addObserver:self forObject:self];
    //   [AJRObserverCenter notifyObserversObjectWillChange:nil];

    // Drag and Drop
    [self registerForDraggedTypes:[[DrawDocument draggedTypes] allKeys]];
    [self registerForDraggedTypes:@[DrawGraphicPboardType]];

    NSEnumerator *enumerator = [_layers objectEnumerator];
    NSArray *graphics;
    while ((graphics = [enumerator nextObject])) {
        for (NSInteger x = 0; x < (const NSInteger)[graphics count]; x++) {
            DrawGraphic *graphic = [graphics objectAtIndex:x];
            [self observeGraphic:graphic yesNo:YES];
        }
    }

    // Variables
    if (_variableStore == nil) {
        _variableStore = [[AJRStore alloc] init];
    }

    return self;
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)coder {
    [coder encodeRect:[self frame] forKey:@"frame"];
    [coder encodeObject:_layers forKey:@"layers"];
    [coder encodeObjectIfNotNil:_paperColor forKey:@"paperColor"];
    if (_variableStore.count > 0) {
        // Let's only encode this if it matters, since it usually won't.
        [coder encodeObject:_variableStore forKey:@"variableStore"];
    }
}

@end
