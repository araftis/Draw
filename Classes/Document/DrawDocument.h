/*
DrawDocument.h
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

#import <AJRFoundation/AJRFoundation.h>
#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>
#import <AJRInterface/AJRInterface.h>
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

// Standard Document Info Keys
extern NSString * const DrawDocumentInfoAuthorKey;
extern NSString * const DrawDocumentInfoCreationDateKey;
extern NSString * const DrawDocumentInfoCommentsKey;
extern NSString * const DrawDocumentInfoCopyrightKey;
extern NSString * const DrawDocumentInfoLicenseKey;

// Panels
extern NSString * const DrawOpenPanelPathKey;
extern NSString * const DrawSavePanelPathKey;

@protocol DrawDocumentGraphicObserver;

@class AJRBlockDrawingView;

@interface DrawDocument : NSDocument {
    // Current Tools
    DrawToolSet *_currentToolSet;   // The active tool set.
    // This represents the tools being displayed in the not-global tool set. This is needed
    // mostly because tools can now belong to more than one tool set. When this is the case,
    // we need to make sure that the tools in the tools segment stay on the same tool set.
    //DrawToolSet *_toolSetInToolsSegment;
    DrawTool *_currentTool;

    // Document Storage
    DrawDocumentStorage *_storage;
    NSFileWrapper *_fileWrapper;

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
    AJREditingContext *_editingContext; // Used to track changes on our objects. Only partially implemented.
    NSMutableArray<id <DrawDocumentGraphicObserver>> *_graphicObservers;

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
@property (nonatomic,strong) AJRStore *variableStore;
/**
 Defines the actualy storage for the document. This includes all data associated with the document that "comprise" the document, but not the UI portions of the document. While the attribute is writable, it should be extremely rare that you ever need to assign to it.
 */
@property (nonatomic,strong) DrawDocumentStorage *storage;
@property (nonatomic,strong) NSSplitViewController *splitViewController;
/** The document's editing context, used to track changes to its graphics. */
@property (nonatomic,readonly) AJREditingContext *editingContext;

@property (nonatomic,readonly) DrawLayerViewController *layersViewController;
@property (nonatomic,readonly) DrawInspectorGroupsController *inspectorGroupsViewController;

// Returns the current scale (frame.size.width / bounds.size.width)
- (CGFloat)scale;

- (void)addGraphic:(DrawGraphic *)graphic;
- (void)removeGraphic:(DrawGraphic *)graphic;
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

#pragma mark - Document Info

@property (nonatomic,readonly) NSMutableDictionary<NSString *, id> *documentInfo;
- (void)setDocumentInfo:(id)value forKey:(nullable NSString *)key;
- (nullable id)documentInfoForKey:(NSString *)key;

#pragma mark - Editing Context

- (void)addObjectToEditingContext:(AJREditableObject *)object;
- (void)removeObjectFromEditingContext:(AJREditableObject *)object;

#pragma mark - Global Actions

- (void)makeVisiblePageFirstResponderAndScrollToVisible:(BOOL)scrollToVisible;
- (void)makePageFirstResponder:(DrawPage *)page andScrollToVisible:(BOOL)scrollToVisible;
- (void)makePageAtIndexFirstResponder:(NSInteger)index andScrollToVisible:(BOOL)scrollToVisible;
- (void)makeSelectionOrVisiblePageFirstResponderAndScrollToVisible:(BOOL)scrollToVisible;
- (void)makeGraphicFirstResponder:(DrawGraphic *)grpahic andScrollToVisible:(BOOL)scrollToVisible;

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


@interface DrawDocument (Event) <DrawSelectionDragger, NSDraggingSource>

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


@interface DrawDocument (Pages) <AJRPagedViewDataSource,AJRPagedViewDelegate>

// TODO: Candidate for deletion
//- (BOOL)knowsPageRange:(NSRange *)range;
//- (NSRect)rectForPage:(NSInteger)aPageNumber;
@property (nonatomic,readonly) NSArray<DrawPage *> *pages;
@property (nonatomic,strong) DrawPage *page;
- (IBAction)addPage:(id)sender;
- (IBAction)insertPage:(id)sender;
- (IBAction)appendPage:(id)sender;
- (IBAction)deletePage:(id)sender;

- (NSInteger)pageNumberForPage:(DrawPage *)page;

- (void)setPagesNeedDisplay:(BOOL)flag;

- (void)enumerateGraphicsUsing:(void (^)(DrawGraphic *graphic, BOOL *stop))block;

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


@protocol DrawDocumentGraphicObserver <NSObject>

- (void)graphic:(DrawGraphic *)graphic didEditKeys:(NSSet<NSString *> *)keys;

@end

@interface DrawDocument (Undo) <AJREditingContextDelegate>

/**
 @discussion Calls the provided block with undo registration disabled. This is the preferred way to do  something with the document without tracking undo / redo events, however, you might need to call  -[disableUndoRegistration] or -[enableUndoRegistation] if you cannot perform your actions in one block.  That being said, if you call these two methods, you must make sure you always pair the calls, or bad things  will happen to the document going forward.

 @param block A block to call, surrounded by calls to disableUndoRegistration and enableUndoRegistration.
 */
- (void)editWithoutUndoTracking:(void (^)(void))block;

- (void)disableUndoRegistration;
- (void)enableUndoRegistration;

- (void)addGraphicObserver:(id <DrawDocumentGraphicObserver>)observer NS_SWIFT_NAME(addGraphicObserver(_:));
- (void)removeGraphicObserver:(id <DrawDocumentGraphicObserver>)observer NS_SWIFT_NAME(removeGraphicObserver(_:));

- (void)registerUndoWithTarget:(id)target selector:(SEL)aSelector object:(id)anObject;
- (void)registerUndoWithTarget:(id)target handler:(void (^)(id target))undoHandler;
- (DrawDocument *)prepareUndoWithInvocation;
- (id)prepareWithInvocationTarget:(id)target;
- (void)setActionName:(NSString *)name;

- (IBAction)undo:(id)sender;
- (IBAction)redo:(id)sender;

@end

@interface DrawDocument (Variables) <AJRStoreVariableDelegate, AJRVariableListener>



@end

NS_ASSUME_NONNULL_END
