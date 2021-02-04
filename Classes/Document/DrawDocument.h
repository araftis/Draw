/* DrawDocument.h created by alex on Tue 28-Apr-1998 */

#import <AppKit/AppKit.h>

#import <AJRFoundation/AJRFoundation.h>
#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>
#import <AJRInterface/AJRPagedView.h>
#import <Draw/DrawSelectionTool.h>

NS_ASSUME_NONNULL_BEGIN

@class AJRBezierPath, AJRRibbonView, AJRSplitView, DrawBook, DrawDocumentStorage, DrawPage, DrawGraphic, DrawInspectorGroupController, DrawGraphicsInspectorController, DrawLayer, DrawRulerMarker, DrawTool, DrawViewRulerAccessory, DrawLayerViewController, DrawInspectorGroupsController;

extern NSString * const DrawDocumentErrorDomain;
extern NSString * const DrawDocumentLogDomain;

extern NSString * const DrawViewDidChangeURLNotification;
extern NSString * const DrawViewOldURLKey;
extern NSString * const DrawViewNewURLKey;

extern NSString * const DrawLayerDidChangeNotification;
extern NSString * const DrawViewWillDeallocateNotification;

extern NSString * const DrawDocumentDidAddGraphicNotification;
extern NSString * const DrawGraphicKey;

extern NSString * const DrawViewDidChangeSelectionNotification;
extern NSString * const DrawViewSelectionKey;

extern NSString * const DrawViewDidUpdateNotification;

extern NSString * const DrawObjectDidResignRulerNotification;

// The Pasteboard
extern NSString * const DrawGraphicPboardType;

// Defaults Keys
extern NSString * const DrawMarkColorKey;
extern NSString * const DrawMarksEnabledKey;
extern NSString * const DrawMarksVisibleKey;
extern NSString * const DrawGridColorKey;
extern NSString * const DrawGridEnabledKey;
extern NSString * const DrawGridVisibleKey;
extern NSString * const DrawGridSpacingKey;
extern NSString * const DrawPaperColorKey;
extern NSString * const DrawFlippedKey;
extern NSString * const DrawRulersVisibleKey;
extern NSString * const DrawLeftViewExpandedKey;
extern NSString * const DrawRightViewExpandedKey;
extern NSString * const DrawLeftViewExpandedWidthKey;
extern NSString * const DrawRightViewExpandedWidthKey;
extern NSString * const DrawMarginColorKey;

// Panels
extern NSString * const DrawOpenPanelPathKey;
extern NSString * const DrawSavePanelPathKey;

@interface DrawDocument : NSDocument {
    // Current Tools
    DrawToolSet *_currentToolSet;   // The active tool set.
    DrawTool *_currentTool;

    // Document Storage
    DrawDocumentStorage *_storage;

    // Belonging
    DrawBook * __weak _book;

    // Grid
    AJRBezierPath *_grid;

    // Ruler Support
    DrawViewRulerAccessory *_rulerAccessory;

    // Layers
    NSPopUpButton *_layerPopUpButton;

    // Undo Management
    NSString *_lastUndoAction; // Doesn't archive
    NSDate *_lastUndoTime; // Doesn't archive
    id _lastUndoTarget; // Doesn't archive

    // Flags
    BOOL _isPrinting;
    BOOL _useShallowEncode;
    BOOL _suspendAddNotification;
}

@property (nonatomic,strong) IBOutlet AJRPagedView *pagedView;
@property (nonatomic,strong) IBOutlet NSSegmentedControl *toolSetSegments;
@property (nonatomic,strong) IBOutlet NSSegmentedControl *toolSegments;
@property (nonatomic,strong) IBOutlet NSToolbarItem *toolsToolbarItem;
@property (nonatomic,strong) IBOutlet NSSegmentedControl *globalToolSegments;
@property (nonatomic,strong) IBOutlet NSToolbarItem *globalToolToolbarItem;
@property (nonatomic,strong) IBOutlet NSToolbarItem *inspectorsToolbarItem;
@property (nonatomic,strong) IBOutlet NSToolbarItem *layersToolbarItem;
@property (nonatomic,strong) IBOutlet NSToolbarItem *gridToolbarItem;
@property (nonatomic,strong) IBOutlet NSSegmentedControl *gridSegments;
@property (nonatomic,strong) IBOutlet NSToolbarItem *toolSetsToolbarItem;
@property (nonatomic,strong) IBOutlet AJRBlockDrawingView *ribbonView;
@property (nonatomic,strong) DrawInspectorGroupController *inspectorGroupController;
@property (nonatomic,strong) DrawToolSet *currentToolSet;
@property (nonatomic,strong) DrawToolSet *displayedToolSet;
@property (nonatomic,strong) DrawTool *currentTool;
@property (nonatomic,strong) NSColor *paperColor;
@property (nonatomic,strong) DrawGraphic *templateGraphic;
@property (nonatomic,strong) DrawDocumentStorage *storage;
@property (nonatomic,strong) NSSplitViewController *splitViewController;

@property (nonatomic,readonly) DrawLayerViewController *layersViewController;
@property (nonatomic,readonly) DrawInspectorGroupsController *inspectorGroupsViewController;

// Returns the current scale (frame.size.width / bounds.size.width)
- (CGFloat)scale;

- (void)addGraphic:(DrawGraphic *)aGraphic;
- (void)removeGraphic:(DrawGraphic *)aGraphic;
- (void)replaceGraphic:(DrawGraphic *)oldGraphic withGraphic:(DrawGraphic *)newGraphic;

@property (nonatomic,readonly) BOOL useShallowEncode;

- (void)displayIntermediateResults;

- (void)updateMarkings;

- (void)ping;

/**
 The type of object to use as the document's storage. By default, this is DrawDocumentStorage, but subclasses may override, and in fact will need to override if the introduce additonal properties.
 */
@property (nonatomic,class,readonly) Class storageClass;
@property (nonatomic,class,readonly) DrawDocument * focusedDocument;

//- (IBAction)toggleSideViews:(NSSegmentedControl *)sender;

@end


@interface DrawDocument (Chapters)

@property (nonatomic,weak) DrawBook *book;
@property (nonatomic,strong) NSString *chapterName;

@end


@interface DrawDocument (DragAndDrop)

+ (NSDictionary *)draggedTypes;
+ (void)registerTool:(DrawTool *)aTool forDraggedTypes:(NSArray *)dragTypes;
+ (void)unregisterTool:(DrawTool *)aTool forDraggedTypes:(NSArray *)dragTypes;

@end


@interface DrawDocument (EPS)

- (NSImage *)imageForSelection;
- (NSImage *)imageForGraphicsArray:(NSArray<DrawGraphic *> *)graphics;
- (NSData *)PDFForGraphics:(NSArray<DrawGraphic *> *)graphics;

@end


@interface DrawDocument (Event) <DrawSelectionDragger>

- (BOOL)dragSelection:(NSArray<DrawGraphic *> *)aSelection withLastHitGraphic:(DrawGraphic *)graphic fromEvent:(DrawEvent *)event;

@end


@interface DrawDocument (Grid)

- (void)updateGrid;

- (CGFloat)snapLocationToGrid:(CGFloat)location;
- (NSPoint)snapPointToGrid:(NSPoint)point;
- (NSSize)snapSizeToGrid:(NSSize)size;
- (NSRect)snapRectToGrid:(NSRect)rect;

- (IBAction)takeGridStateFrom:(NSSegmentedControl *)sender;
- (IBAction)toggleGridVisible:(id)sender;

@property (nonatomic,assign) BOOL gridEnabled;
@property (nonatomic,assign) BOOL gridVisible;
@property (nonatomic,strong) NSColor *gridColor;
@property (nonatomic,assign) CGFloat gridSpacing;

- (void)drawGridInRect:(NSRect)rect inView:(NSView *)page;

@end


@interface DrawDocument (Group)

- (IBAction)group:(id)sender;
- (IBAction)ungroup:(id)sender;

- (IBAction)enterGroup:(id)sender;
- (IBAction)exitGroup:(id)sender;

- (void)focusGroup:(DrawGraphic *)aGroup;
- (void)unfocusGroup;
- (void)unfocusAllGroups;
@property (nonatomic,readonly) DrawGraphic *focusedGroup;

@end


@interface DrawDocument (IO) <AJRXMLCoding>

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError *__autoreleasing _Nullable *)outError;
- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError *__autoreleasing _Nullable *)outError;

@end


@interface DrawDocument (Layers)

@property (nonatomic,readonly) DrawLayerViewController *layerViewController;

@property (nonatomic,readonly) NSArray<DrawLayer *> *layers;
@property (nonatomic,strong) DrawLayer *layer;
- (void)setLayerWithName:(NSString *)lame;

- (void)addLayer:(DrawLayer *)aLayer;
- (void)addLayerWithName:(NSString *)name;
- (void)removeLayer:(DrawLayer *)layer;
- (void)removeLayerWithName:(NSString *)aName;
- (void)removeLayerAtIndex:(NSUInteger)index;

- (void)moveLayerAtIndex:(NSUInteger)index toIndex:(NSUInteger)otherIndex;

- (NSUInteger)indexOfLayerWithName:(NSString *)aName;
- (DrawLayer *)layerWithName:(NSString *)aName;
- (DrawLayer *)layerAtIndex:(NSUInteger)index;
@property (nonatomic,readonly) NSUInteger layerIndex;

@property (nonatomic,readonly) NSUInteger layerCount;

@end


@interface DrawDocument (Menus)

@property (nonatomic,class,readonly) NSMenu *formatMenu;
@property (nonatomic,class,readonly) NSMenu *arrangeMenu;
@property (nonatomic,class,readonly) NSMenu *viewMenu;

+ (void)addItems:(NSArray<NSMenuItem *> *)items toMenu:(NSMenu *)menu;

@end


@interface DrawDocument (Pages) <AJRPagedViewDataSource>

- (BOOL)knowsPageRange:(NSRange *)range;
- (NSRect)rectForPage:(NSInteger)aPageNumber;
@property (nonatomic,readonly) NSArray<DrawPage *> *pages;
@property (nonatomic,strong) DrawPage *page;
- (IBAction)addPage:(id)sender;
- (IBAction)insertPage:(id)sender;
- (IBAction)appendPage:(id)sender;
- (IBAction)deletePage:(id)sender;

- (NSInteger)pageNumberForPage:(DrawPage *)page;

- (void)setPagesNeedDisplay:(BOOL)flag;

@end


@interface DrawDocument (Pasteboard)

- (IBAction)copy:(id)sender;
- (IBAction)paste:(id)sender;

@end


@interface DrawDocument (Rulers)

- (NSArray<NSNumber *> *)horizontalMarks;
- (void)addHorizontalGuideAtLocation:(CGFloat)offset;
- (void)removeHorizontalGuideAtLocation:(CGFloat)offset;
- (void)moveHorizontalGuideAtLocation:(CGFloat)oldLocation to:(CGFloat)newLocation;
- (NSArray<NSNumber *> *)verticalMarks;
- (void)addVerticalGuideAtLocation:(CGFloat)offset;
- (void)removeVerticalGuideAtLocation:(CGFloat)offset;
- (void)moveVerticalGuideAtLocation:(CGFloat)oldLocation to:(CGFloat)newLocation;

- (IBAction)toggleMarks:(id)sender;
@property (nonatomic,strong) NSColor *markColor;
@property (nonatomic,assign) BOOL marksVisible;
- (IBAction)toggleSnapToMarks:(id)sender;
@property (nonatomic,assign) BOOL marksEnabled;

- (void)updateRulers;

- (void)objectDidResignRuler:(NSNotification *)notification;

@end


@interface DrawDocument (Selection)

- (BOOL)isGraphicSelected:(DrawGraphic *)graphic;
- (void)addGraphicToSelection:(DrawGraphic *)graphic;
- (void)removeGraphicFromSelection:(DrawGraphic *)graphic;
- (void)addGraphicsToSelection:(id <NSFastEnumeration,NSCopying>)graphic;
- (void)removeGraphicsFromSelection:(id <NSFastEnumeration,NSCopying>)graphic;

@property (nonatomic,readonly) NSSet<DrawGraphic *> *selection;
@property (nonatomic,readonly) NSSet<DrawGraphic *> *selectionForInspection;
@property (nonatomic,readonly) NSArray<DrawGraphic *> *sortedSelection;
- (void)clearSelection;

- (IBAction)deleteSelection:(id)sender;
- (void)deleteSelection;
- (IBAction)moveSelectionUp:(id)sender;
- (void)moveSelectionUp;
- (IBAction)moveSelectionToTop:(id)sender;
- (void)moveSelectionToTop;
- (IBAction)moveSelectionDown:(id)sender;
- (void)moveSelectionDown;
- (IBAction)moveSelectionToBottom:(id)sender;
- (void)moveSelectionToBottom;

@property (nonatomic,readonly) BOOL selectionContainsGroups;
@property (nullable,readonly) DrawGraphic *groupFromSelection;

@end


@interface DrawDocument (ToolBar) <NSToolbarDelegate>

- (void)toolDidBecomeActive:(NSNotification *)notification;
- (IBAction)selectToolSet:(id)sender;
- (IBAction)selectTool:(id)sender;

@end


@interface DrawDocument (Undo)

- (void)registerUndoWithTarget:(id)target selector:(SEL)aSelector object:(id)anObject;
- (void)registerUndoWithTarget:(id)target handler:(void (^)(id target))undoHandler;
- (DrawDocument *)prepareUndoWithInvocation;
- (id)prepareWithInvocationTarget:(id)target;
- (void)setActionName:(NSString *)name;

- (IBAction)undo:(id)sender;
- (IBAction)redo:(id)sender;

@end

NS_ASSUME_NONNULL_END
