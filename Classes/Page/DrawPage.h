/*
DrawPage.h
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

#import <AppKit/AppKit.h>

@class DrawGraphic, DrawLayer, DrawTool, DrawDocument;

NS_ASSUME_NONNULL_BEGIN

@class DrawPage;

typedef void *DrawDrawingToken;
typedef void (^DrawGuestDrawer)(DrawPage *page, NSRect dirtyRect);

@interface DrawPage : NSView <NSCoding> {
    __weak DrawDocument *_document;
    NSMutableDictionary<NSString *, NSMutableArray<DrawGraphic *> *> *_layers;
    NSColor *_paperColor;

    // Screen updating
    NSMutableArray<DrawGraphic *> *_changedGraphics;
    NSRect _cacheRect;
    NSRect _updateRect;

    // Drag and Drop
    DrawTool *_draggingTool;
    NSUInteger _draggingOperation;

    // Events
    BOOL _mouseInPage; // Toggles in response to monuseEntered: and mouseExited: events.

    BOOL _hasScheduledUpdate:1;
    BOOL _selfDidUpdate:1;
}

- (id)initWithDocument:(DrawDocument *)document;

#pragma mark - Properties

@property (nonatomic,weak) DrawDocument *document;
@property (nonatomic,strong,null_resettable) NSColor *paperColor;
@property (nonatomic,readonly) BOOL isPrinting;

#pragma mark - Graphics

- (void)addGraphic:(DrawGraphic *)aGraphic;
- (void)addGraphic:(DrawGraphic *)graphic toLayer:(nullable DrawLayer *)layer;
- (void)addGraphic:(DrawGraphic *)graphic select:(BOOL)select byExtendingSelection:(BOOL)byExtension;
- (void)addGraphic:(DrawGraphic *)graphic toLayer:(nullable DrawLayer *)layer select:(BOOL)select byExtendingSelection:(BOOL)byExtension;
- (void)removeGraphic:(DrawGraphic *)aGraphic;
- (void)replaceGraphic:(DrawGraphic *)oldGraphic withGraphic:(DrawGraphic *)newGraphic;

- (void)observeGraphic:(DrawGraphic *)aGraphic yesNo:(BOOL)yesNo;

#pragma mark - Layers

- (void)drawLayer:(DrawLayer *)layer inRect:(NSRect)rect;
- (void)drawPageNumber:(NSInteger)aPageNumber inRect:(NSRect)rect;
- (void)drawMarksInRect:(NSRect)rect;
- (void)drawPageMarkingsInRect:(NSRect)rect;

- (NSMutableArray *)graphicsForLayer:(DrawLayer *)aLayer;

- (NSArray<DrawGraphic *> *)graphicsHitByPoint:(NSPoint)point;
- (NSArray<DrawGraphic *> *)graphicsHitByRect:(NSRect)rect;

- (void)graphicWillChange:(DrawGraphic *)aGraphic;
- (void)displayIntermediateResults;
- (void)displayGraphicRect:(NSRect)rect;
- (void)setGraphicNeedsDisplayInRect:(NSRect)rect;

@property (nonatomic,readonly) CGFloat scale;
@property (nonatomic,readonly) CGFloat error;

#pragma mark - Guest drawers

/*!
 Adds a guest drawer to the page. This is a block added to the page called during the page's drawRect: method. Note that this method doesn't dirty the page. If you actually want the block called, you'll need to also call setNeedsDisplayInRect:. The block passed with be called with a reference to the page and the dirtyRect as passed into -drawRect:.

 Currently, all guest drawing is done after everything else.

 @param drawer The block to call when drawing is being done.

 @return A token that can be used to remove the block.
 */
- (DrawDrawingToken)addGuestDrawer:(DrawGuestDrawer)drawer;

/*!
 Removes a previous registered guest drawer via the token returned via addGuestDrawer:.
 */
- (void)removeGuestDrawer:(DrawDrawingToken)token;

@end


@interface DrawPage (DragAndDrop)

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender;
- (NSUInteger)draggingEntered:(id <NSDraggingInfo>)sender;
- (void)draggingExited:(id <NSDraggingInfo>)sender;
- (NSUInteger)draggingUpdated:(id <NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender;

@end


@interface DrawPage (Event)

- (BOOL)makeSelectionPerformSelector:(SEL)selector withObject:(id)anObject shortCircuit:(BOOL)shortCircuit;
- (void)mouseDown:(NSEvent *)anEvent;

@property (nonatomic,readonly) BOOL mouseInPage;

@end


@interface DrawPage (Rulers)

- (void)rulerViewDidSetClientView:(NSRulerView *)rulerView;
- (void)rulerView:(nullable NSRulerView *)rulerView handleMouseDown:(NSEvent *)theEvent;
- (CGFloat)rulerView:(nullable NSRulerView *)rulerView willMoveMarker:(NSRulerMarker *)marker toLocation:(CGFloat)location;
- (void)rulerView:(nullable NSRulerView *)rulerView didAddMarker:(NSRulerMarker *)marker;
- (void)rulerView:(nullable NSRulerView *)rulerView didMoveMarker:(NSRulerMarker *)marker;
- (BOOL)rulerView:(nullable NSRulerView *)rulerView shouldMoveMarker:(NSRulerMarker *)marker;
- (void)rulerView:(nullable NSRulerView *)rulerView didRemoveMarker:(NSRulerMarker *)marker;

- (NSArray *)horizontalMarginRanges;
- (NSArray *)verticalMarginRanges;

@end

NS_ASSUME_NONNULL_END
