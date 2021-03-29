
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

    BOOL _hasScheduledUpdate:1;
    BOOL _selfDidUpdate:1;
}

- (id)initWithDocument:(DrawDocument *)document;

@property (nonatomic,weak) DrawDocument *document;
@property (nonatomic,strong,null_resettable) NSColor *paperColor;

- (void)addGraphic:(DrawGraphic *)aGraphic;
- (void)addGraphic:(DrawGraphic *)graphic toLayer:(nullable DrawLayer *)layer;
- (void)addGraphic:(DrawGraphic *)graphic select:(BOOL)select byExtendingSelection:(BOOL)byExtension;
- (void)addGraphic:(DrawGraphic *)graphic toLayer:(nullable DrawLayer *)layer select:(BOOL)select byExtendingSelection:(BOOL)byExtension;
- (void)removeGraphic:(DrawGraphic *)aGraphic;
- (void)replaceGraphic:(DrawGraphic *)oldGraphic withGraphic:(DrawGraphic *)newGraphic;

- (void)observeGraphic:(DrawGraphic *)aGraphic yesNo:(BOOL)yesNo;

- (void)drawLayer:(DrawLayer *)aLayer inRect:(NSRect)rect;
- (void)drawLayer:(DrawLayer *)layer inRect:(NSRect)rect isDrawingToScreen:(BOOL)flag;
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
