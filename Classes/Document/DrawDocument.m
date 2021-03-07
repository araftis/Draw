/* DrawView.m created by alex on Tue 28-Apr-1998 */

#import "DrawDocument.h"

#import "DrawAspect.h"
#import "DrawBook.h"
#import "DrawDocumentStorage.h"
#import "DrawGraphic.h"
#import "DrawGraphicsToolSet.h"
#import "DrawGraphicsInspectorController.h"
#import "DrawLayer.h"
#import "DrawPage.h"
#import "DrawPageLayout.h"
#import "DrawRibbonInspectorController.h"
#import "DrawRulerView.h"
#import "DrawTool.h"
#import "DrawToolAction.h"
#import "DrawToolSet.h"
#import "DrawViewController.h"
#import "DrawViewRulerAccessory.h"
#import <Draw/Draw-Swift.h>

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>
#import <AJRInterface/AJRInterface.h>

NSString * const DrawDocumentErrorDomain = @"DrawDocumentErrorDomain";
NSString * const DrawDocumentLogDomain = @"DrawDocument";

NSString * const DrawViewWillDeallocateNotification = @"DrawViewWillDeallocateNotification";
NSString * const DrawDocumentDidAddGraphicNotification = @"DrawDocumentDidAddGraphicNotification";
NSString * const DrawGraphicKey = @"DrawGraphicKey";
NSString * const DrawViewDidChangeSelectionNotification = @"DrawViewDidChangeSelectionNotification";
NSString * const DrawViewSelectionKey = @"DrawViewSelectionKey";
NSString * const DrawViewDidUpdateNotification = @"DrawViewDidUpdateNotification";
NSString * const DrawObjectDidResignRulerNotification = @"DrawObjectDidResignRulerNotification";

NSString * const DrawMarkColorKey = @"MarkColorKey";
NSString * const DrawMarksEnabledKey = @"MarksEnabledKey";
NSString * const DrawMarksVisibleKey = @"MarksVisibleKey";
NSString * const DrawGridColorKey = @"GridColorKey";
NSString * const DrawGridEnabledKey = @"GridEnabledKey";
NSString * const DrawGridVisibleKey = @"GridVisibleKey";
NSString * const DrawGridSpacingKey = @"GridSpacingKey";
NSString * const DrawPaperColorKey = @"PaperColorKey";
NSString * const DrawFlippedKey = @"FlippedKey";
NSString * const DrawCurrentToolSetIDKey = @"CurrentToolSetID"; // The actual, current tool.
NSString * const DrawSelectedToolSetIDKey = @"SelectedToolSetID"; // The "general" tool currently selected.
NSString * const DrawTemplateGraphicKey = @"TemplateGraphicKey";
NSString * const DrawRulersVisibleKey = @"RulersVisible";
NSString * const DrawLeftViewExpandedKey = @"LeftViewExpanded";
NSString * const DrawRightViewExpandedKey = @"RightViewExpanded";
NSString * const DrawLeftViewExpandedWidthKey = @"LeftViewExpandedWidth";
NSString * const DrawRightViewExpandedWidthKey = @"RightViewExpandedWidth";
NSString * const DrawMarginColorKey = @"MarginColor";

// Standard Document Info Keys
NSString * const DrawDocumentInfoAuthorKey = @"author";
NSString * const DrawDocumentInfoCreationDateKey = @"creationDate";
NSString * const DrawDocumentInfoCommentsKey = @"comments";
NSString * const DrawDocumentInfoCopyrightKey = @"copyright";
NSString * const DrawDocumentInfoLicenseKey = @"license";

const AJRInspectorIdentifier AJRInspectorIdentifierDrawDocument = @"document";

@interface DrawDocument (Private)

+ (void)_setupGroupMenu;
- (void)windowDidLoad;

@end


@interface DrawPage (Private)

- (void)_updateMarkersForRulerView:(NSRulerView *)aView;

@end


@implementation DrawDocument {
    DrawDocumentWindowController *_primaryWindowController;
    NSMutableDictionary<NSString *, id <AJRInvalidation>> *_iconObserverTokens;
    NSMutableArray<id <AJRInvalidation>> *_documentInfoObserverTokens;
}

+ (void)initialize {
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     [NSDictionary dictionaryWithObjectsAndKeys:
      // The Compose Defaults
      @"NSCalibratedWhiteColorSpace 1 1", DrawPaperColorKey,
      @"NSCalibratedRGBColorSpace 1 0.498039 0.498039 1", DrawMarkColorKey,
      @"YES", DrawMarksVisibleKey,
      @"YES", DrawMarksEnabledKey,
      @"NSCalibratedWhiteColorSpace 0.8367 1", DrawGridColorKey,
      @"NO", DrawGridVisibleKey,
      @"NO", DrawGridEnabledKey,
      @"9", DrawGridSpacingKey,
      NSHomeDirectory(), DrawOpenPanelPathKey,
      NSHomeDirectory(), DrawSavePanelPathKey,
      @"YES", DrawFlippedKey,
      @"global", DrawCurrentToolSetIDKey, // NOTE: Should be DrawToolSetIdGlobal, but these don't export back from Swift.
      DrawToolSetIdGraphics, DrawSelectedToolSetIDKey,
      @"YES", DrawRulersVisibleKey,
      @"NO", DrawLeftViewExpandedKey,
      @"NO", DrawRightViewExpandedKey,
      @"200.0", DrawLeftViewExpandedWidthKey,
      @"200.0", DrawRightViewExpandedWidthKey,
      nil
      ]
     ];

    [self _setupGroupMenu];

    [AJRScrollView setRulerViewClass:[DrawRulerView class]];

    //[DrawSelectionTool registerObject:self forDragWithModifierMask:NSEventModifierFlagShift];
}

#pragma mark - Creation

- (void)_initializeTemplateGraphic {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:DrawTemplateGraphicKey];
    if (data) {
        _storage.templateGraphic = [NSKeyedUnarchiver ajr_unarchivedObjectWithData:data error:NULL];
    }
    if (_storage.templateGraphic == nil) {
        _storage.templateGraphic = [[DrawGraphic alloc] initWithFrame:NSZeroRect];
        for (Class aspectClass in [DrawAspect aspects]) {
            DrawAspect *aspect = [aspectClass defaultAspectForGraphic:_storage.templateGraphic];
            if (aspect != nil) {
                [_storage.templateGraphic addAspect:aspect withPriority:[aspectClass defaultPriority]];
            }
        }
    }
}

- (id)init {
    if ((self = [super init])) {
        _iconObserverTokens = [NSMutableDictionary dictionary];

        // Editing
        _editingContext = [[AJREditingContext alloc] init];
        _editingContext.delegate = self;
        // TODO: Add this in
        //_editingContext.undoManager = self.undoManager;
        _graphicObservers = [NSMutableArray array];

    }
    return self;
}

- (id)initWithType:(NSString *)typeName error:(NSError **)outError {
    if ((self = [super initWithType:typeName error:outError])) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        DrawPage *page;

        _storage = [[self.class.storageClass alloc] init];
        _storage.printInfo = self.printInfo;

        _storage.paperColor = [defaults colorForKey:DrawPaperColorKey];

        // Snap Marks
        _storage.markColor = [defaults colorForKey:DrawMarkColorKey];
        _storage.horizontalMarks = [[NSMutableArray alloc] init];
        _storage.verticalMarks = [[NSMutableArray alloc] init];
        _storage.marksEnabled = [defaults boolForKey:DrawMarksEnabledKey];
        _storage.marksVisible = [defaults boolForKey:DrawMarksVisibleKey];

        // Ruler Support
        _rulerAccessory = [[DrawViewRulerAccessory alloc] initWithDocument:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectDidResignRuler:) name:DrawObjectDidResignRulerNotification object:self];

        // Grid
        _storage.gridColor = [defaults colorForKey:DrawGridColorKey];
        _storage.gridSpacing = [[defaults objectForKey:DrawGridSpacingKey] floatValue];
        if (_storage.gridSpacing <= 0.0) _storage.gridSpacing = 9.0;
        _storage.gridEnabled = [defaults boolForKey:DrawGridEnabledKey];
        _storage.gridVisible = [defaults boolForKey:DrawGridVisibleKey];
        [self updateGrid];

        // Pages
        _storage.startingPageNumber = 1;
        page = [[DrawPage alloc] initWithDocument:self];
        _storage.pages = [[NSMutableArray alloc] initWithObjects:page, nil];
        [self setPage:page];
        _storage.masterPageOdd = [[DrawPage alloc] initWithDocument:self];
        _storage.masterPageEven = [[DrawPage alloc] initWithDocument:self];

        // Layers
        _storage.layers = [[NSMutableArray alloc] init];
        [self addLayerWithName:@"Default"];

        // Tools...
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toolDidBecomeActive:) name:DrawToolDidBecomeActiveNotification object:nil];

        // Selection
        _storage.selection = [[NSMutableSet alloc] init];

        // State
        [self _initializeTemplateGraphic];

        // My menu...
        //[self setMenu:[[DrawController sharedInstance] actionMenuCopy]];

        // Belonging
        [self setChapterName:@"Untitled"];

        // Initial Document Info
        [self setDocumentInfo:NSFullUserName() forKey:@"author"];
        [self setDocumentInfo:[NSDate date] forKey:@"creationDate"];
    }
    return self;
}

#pragma mark - Destruction

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:DrawViewWillDeallocateNotification object:self];

    for (id <AJRInvalidation> object in _iconObserverTokens.objectEnumerator) {
        [object invalidate];
    }

    _storage.group = nil;
}

#pragma mark - Utilities

- (void)_setupToolSets {
    NSMenu *toolSetMenu = [[NSMenu alloc] initWithTitle:@"Tool Sets"];
    for (NSString *identifier in [DrawToolSet toolSetIdentifiers]) {
        if (![identifier isEqualToString:@"global"]) {
            DrawToolSet *toolSet = [DrawToolSet toolSetForIdentifier:identifier];
            NSMenuItem *item;

            item = [toolSetMenu addItemWithTitle:toolSet.name action:@selector(selectToolSet:) keyEquivalent:@""];
            item.target = self;
            item.image = toolSet.icon;
            item.representedObject = toolSet;
        }
    }
    [_toolSetSegments setMenu:toolSetMenu forSegment:0];

    [self _setupToolSegmentsIn:_globalToolSegments for:DrawToolSet.globalToolSet];
}

- (void)_setImageIn:(NSSegmentedControl *)segments forSegment:(NSUInteger)index tool:(DrawTool *)tool action:(DrawToolAction *)action {
    if (tool.icon != nil) {
        [segments setImage:tool.icon forSegment:index];
        if (_iconObserverTokens[tool.identifier] == nil) {
            __weak DrawDocument *weakSelf = self;
            _iconObserverTokens[tool.identifier] = [tool addObserver:self forKeyPath:@"icon" options:0 block:^(DrawTool *tool, NSString *keyPath, NSDictionary<NSKeyValueChangeKey,id> *change) {
                AJRPrintf(@"update!\n");
                DrawDocument *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    if (strongSelf.displayedToolSet == tool.toolSet) {
                        if (!tool.toolSet.isGlobal) {
                            [strongSelf _setImageIn:strongSelf->_toolSegments forSegment:index tool:tool action:nil];
                        }
                    }
                }
            }];
        }
    } else {
        [segments setImage:[action icon] forSegment:index];
    }
}

- (void)_setupToolSegmentsIn:(NSSegmentedControl *)segments for:(DrawToolSet *)toolSet {
    NSArray<DrawTool *> *tools = [toolSet tools];
    NSInteger segmentIndex;

    [segments setSegmentCount:tools.count];
    segmentIndex = 0;
    for (DrawTool *tool in tools) {
        NSArray *actions = [tool actions];
        DrawToolAction *action = [tool currentAction];

        [self _setImageIn:segments forSegment:segmentIndex tool:tool action:action];
        [segments setSelected:tool == _currentTool forSegment:segmentIndex];

        if ([actions count] > 1) {
            NSMenu *menu = [[NSMenu alloc] initWithTitle:[tool name]];
            for (DrawToolAction *action in [tool actions]) {
                NSMenuItem *item = [menu addItemWithTitle:[action title] action:@selector(selectTool:) keyEquivalent:@""];
                [item setTarget:self];
                [item setImage:[action icon]];
                [item setRepresentedObject:action];
            }
            [segments setMenu:menu forSegment:segmentIndex];
        } else {
            [segments setMenu:nil forSegment:segmentIndex];
        }
        [segments setWidth:32.0 forSegment:segmentIndex];
        segmentIndex++;
    }

    [segments sizeToFit];
}

#pragma mark - Properties

+ (Class)storageClass {
    return DrawDocumentStorage.class;
}

- (void)_setDocumentStorage:(DrawDocumentStorage *)storage {
    if (_storage != nil) {
        // We're reverting to our saved state.
        for (DrawLayer *layer in _storage.layers) {
            layer.document = nil;
        }
        for (DrawPage *page in _storage.pages) {
            // We need to remove all the objects from our editing context
            [self enumerateGraphicsUsing:^(DrawGraphic * _Nonnull graphic, BOOL * _Nonnull stop) {
                if (graphic.editingContext == self->_editingContext) {
                    [self->_editingContext forgetObject:graphic];
                }
            }];
            page.document = nil;
        }
        _storage.masterPageOdd.document = nil;
        _storage.masterPageEven.document = nil;
    }

    // Does this need to do some sort notifications? I'm assuming no to start with, because this should only be called during document unarchiving.
    _storage = storage;

    self.printInfo = _storage.printInfo;

    // We have to "claim" ownership of some of our storage's objects.
    for (DrawLayer *layer in _storage.layers) {
        layer.document = self;
    }

    for (DrawPage *page in _storage.pages) {
        page.document = self;
    }

    // And now we need to add all our graphics back in.
    [self enumerateGraphicsUsing:^(DrawGraphic * _Nonnull graphic, BOOL * _Nonnull stop) {
        // We do this check, because a graphic might get passed to us twice.
        if (graphic.editingContext != self->_editingContext) {
            if (graphic.editingContext != nil) {
                // Steal ownership
                [[graphic editingContext] forgetObject:graphic];
            }
            [self->_editingContext addObject:graphic];
            [graphic startTrackingEdits];
        }
    }];

    _storage.masterPageOdd.document = self;
    _storage.masterPageEven.document = self;

    [_pagedView reloadPages];
    [self updateGrid];
    [self updateRulers];

    if (_pagedView) {
        _pagedView.enclosingScrollView.horizontalRulerView.clientView = self.page;
        _pagedView.enclosingScrollView.verticalRulerView.clientView = self.page;
    }
}

- (void)setPrintInfo:(NSPrintInfo *)printInfo {
    // Make sure the storage reflects our print info.
    [super setPrintInfo:printInfo];
    _storage.printInfo = self.printInfo;
}

- (void)setPaperColor:(NSColor *)color {
    if (_storage.paperColor != color) {
        [self registerUndoWithTarget:self selector:@selector(setPaperColor:) object:_storage.paperColor];
        [[self undoManager] setActionName:@"Paper Color"];
        _storage.paperColor = color;
        [self setPagesNeedDisplay:YES];
    }
}

- (NSColor *)paperColor {
    return _storage.paperColor ?: NSColor.whiteColor;
}

- (void)setTemplateGraphic:(DrawGraphic *)templateGraphic {
    _storage.templateGraphic = templateGraphic;
}

- (DrawGraphic *)templateGraphic {
    return _storage.templateGraphic;
}

- (void)setDisplayedToolSet:(DrawToolSet *)toolSet {
    // The displayed tool set can never be to global tool set.
    AJRAssert(![toolSet.identifier isEqualToString:@"global"], @"The global tool set cannot be the displayed tool set.");
    [NSUserDefaults.standardUserDefaults setObject:toolSet.identifier forKey:DrawSelectedToolSetIDKey];
}

- (DrawToolSet *)displayedToolSet {
    NSString *identifier = [NSUserDefaults.standardUserDefaults stringForKey:DrawSelectedToolSetIDKey];
    DrawToolSet *toolSet = [DrawToolSet toolSetForIdentifier:identifier];
    return toolSet ?: [DrawToolSet toolSetForIdentifier:DrawToolSetIdGraphics];
}

- (void)setCurrentToolSet:(DrawToolSet *)toolSet {
    if (_currentToolSet != toolSet) {
        if (_currentToolSet == nil || (_currentToolSet != nil && [_currentToolSet toolSetShouldDeactivateForDocument:self])) {
            if ([toolSet toolSetShouldActivateForDocument:self]) {
                BOOL newIsGlobal = toolSet.isGlobal;

                _currentToolSet = toolSet;
                if (!newIsGlobal) {
                    self.displayedToolSet = _currentToolSet;
                }

                self.currentTool = [_currentToolSet currentTool];

                [_toolSetSegments setImage:self.displayedToolSet.icon forSegment:0];

                if (!newIsGlobal) {
                    [self _setupToolSegmentsIn:_toolSegments for:_currentToolSet];
                }
            }
        }
    }
}

- (void)setCurrentTool:(DrawTool *)currentTool {
    if (currentTool) {
        if ((!_currentTool || (_currentTool && [_currentTool toolShouldDeactivateForDocument:self]))
            && (!currentTool || (currentTool && [currentTool toolShouldActivateForDocument:self]))) {
            if (_currentToolSet != [currentTool toolSet]) {
                self.currentToolSet = [currentTool toolSet];
            }
            
            // This makes sure the segments are nominally setup.
            NSArray *tools = [_currentToolSet tools];
            NSUInteger foundIndex = [tools indexOfObjectIdenticalTo:currentTool];
            DrawTool *tempTool;
            
            tempTool = _currentTool;
            _currentTool = nil;
            [tempTool toolDidDeactivateForDocument:self];
            
            if (foundIndex != NSNotFound) {
                _currentTool = currentTool;

                NSInteger globalIndex = NSNotFound;
                NSInteger index = NSNotFound;

                if (currentTool.toolSet.isGlobal) {
                    globalIndex = foundIndex;
                } else {
                    index = foundIndex;
                }

                for (NSInteger x = 0; x < [_globalToolSegments segmentCount]; x++) {
                    [_globalToolSegments setSelected:x == globalIndex forSegment:x];
                }
                for (NSInteger x = 0; x < [_toolSegments segmentCount]; x++) {
                    [_toolSegments setSelected:x == index forSegment:x];
                }

                if (_currentTool) {
                    if (_currentTool.toolSet.isGlobal) {
                        [_globalToolSegments setImage:_currentTool.currentAction.icon forSegment:globalIndex];
                    } else {
                        [self _setImageIn:_toolSegments forSegment:index tool:_currentTool action:_currentTool.currentAction];
                    }
                    [_currentTool toolDidActivateForDocument:self];
                }
            }
            _currentToolSet.currentTool = _currentTool;
        }
    }
}

- (DrawLayerViewController *)layersViewController {
    return AJRObjectIfKindOfClass([_primaryWindowController.contentViewController ajr_descendantViewControllerOfClass:DrawLayerViewController.class], DrawLayerViewController);
}

- (DrawInspectorGroupsController *)inspectorGroupsViewController {
    return AJRObjectIfKindOfClass([_primaryWindowController.contentViewController ajr_descendantViewControllerOfClass:DrawInspectorGroupsController.class], DrawInspectorGroupsController);
}

- (AJREditingContext *)editingContext {
    return _editingContext;
}

#pragma mark - NSDocument

+ (BOOL)autosavesInPlace {
    return YES;
}

- (void)makeWindowControllers {
    NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"DrawDocument" bundle:[NSBundle bundleForClass:DrawDocument.class]];
    _primaryWindowController = [storyboard instantiateInitialController];
    if (_primaryWindowController) {
        _splitViewController = AJRObjectIfKindOfClassOrAssert([_primaryWindowController contentViewController], NSSplitViewController);

        DrawDocumentViewController *documentViewController = (DrawDocumentViewController *)[_splitViewController ajr_descendantViewControllerOfClass:DrawDocumentViewController.class];
        documentViewController.document = self;

        NSArray<NSViewController *> *childControllers = _splitViewController.childViewControllers;
        NSSize paperSize = self.printInfo.paperSize;
        paperSize.width *= 1.25;
        paperSize.width += 40.0;
        paperSize.height *= 1.25;
        paperSize.height += 40.0;
        if (![_splitViewController splitViewItems][0].isCollapsed) {
            paperSize.width += childControllers[0].view.frame.size.width;
        }
        if (![_splitViewController splitViewItems][2].isCollapsed) {
            paperSize.width += childControllers[2].view.frame.size.width;
        }
        [_primaryWindowController.window setContentSize:paperSize];

        // Set up our "outlets". We can't do this directly in IB, because the outlets would have to cross scene boundaries.
        _pagedView = AJRObjectIfKindOfClassOrAssert([_primaryWindowController.window.contentView findViewWithIdentifier:@"pagedView"], AJRPagedView);
        _pagedView.pageDataSource = self;
        _toolSetSegments = AJRObjectIfKindOfClassOrAssert([_primaryWindowController.window.toolbar toolbarItemForItemIdentifier:@"toolSets"].view, NSSegmentedControl);
        _toolSetSegments.target = self;
        _toolSetSegments.action = @selector(selectToolSet:);
        _toolsToolbarItem = [_primaryWindowController.window.toolbar toolbarItemForItemIdentifier:@"tools"];
        _toolSegments = AJRObjectIfKindOfClassOrAssert(_toolsToolbarItem.view, NSSegmentedControl);
        _toolSegments.target = self;
        _toolSegments.action = @selector(selectTool:);
        _globalToolToolbarItem = [_primaryWindowController.window.toolbar toolbarItemForItemIdentifier:@"globalTools"];
        _globalToolSegments = AJRObjectIfKindOfClassOrAssert(_globalToolToolbarItem.view, NSSegmentedControl);
        _globalToolSegments.target = self;
        _globalToolSegments.action = @selector(selectTool:);
        _layersToolbarItem = [_primaryWindowController.window.toolbar toolbarItemForItemIdentifier:@"layers"];
        _gridToolbarItem = [_primaryWindowController.window.toolbar toolbarItemForItemIdentifier:@"grid"];
        _gridSegments = AJRObjectIfKindOfClassOrAssert(_gridToolbarItem.view, NSSegmentedControl);
        _gridSegments.target = self;
        _gridSegments.action = @selector(takeGridStateFrom:);
        _toolSetsToolbarItem = [_primaryWindowController.window.toolbar toolbarItemForItemIdentifier:@"toolSets"];
        _inspectorsToolbarItem = [_primaryWindowController.window.toolbar toolbarItemForItemIdentifier:@"inspectors"];

        NSToolbarItem *item = [_primaryWindowController.window.toolbar toolbarItemForItemIdentifier:@"inspectors"];
        NSSegmentedControl *control = AJRObjectIfKindOfClassOrAssert(item.view, NSSegmentedControl);
        control.target = self;
        control.action = @selector(toggleInspectors:);
        item = [_primaryWindowController.window.toolbar toolbarItemForItemIdentifier:@"layers"];
        control = AJRObjectIfKindOfClassOrAssert(item.view, NSSegmentedControl);
        control.target = self;
        control.action = @selector(toggleLayers:);

        // We're going to shove this into our top ruler.
        _ribbonView = [[AJRBlockDrawingView alloc] initWithFrame:(NSRect){NSZeroPoint, {100.0, 26.0}}];
        _ribbonView.contentRenderer = ^(CGContextRef context, CGRect rect) {
            [NSColor.windowBackgroundColor set];
            NSRectFill(rect);
            NSRect upper, lower;
            NSDivideRect(rect, &upper, &lower, rect.size.height - 1.0, NSRectEdgeMaxY);
            [NSColor.separatorColor set];
            NSRectFill(lower);
        };

        NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"document"];
        toolbar.delegate = self;
        toolbar.allowsUserCustomization = YES;
        toolbar.displayMode = NSToolbarDisplayModeIconOnly;
        
        [_primaryWindowController.window setToolbar:toolbar];

        [self addWindowController:_primaryWindowController];

        [self setupAfterUILoad];
    }
}

- (void)setupAfterUILoad {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSWindow *window;
    NSRect frame;
    NSScreen *screen = [NSScreen mainScreen];
    NSRect screenFrame;
    NSScrollView *scrollView = [_pagedView enclosingScrollView];

    [self windowDidLoad];

    window = [_pagedView window];
    screenFrame = [screen visibleFrame];
    frame = [window frame];

    frame.size = [self pagedView:_pagedView sizeForPage:0];
    frame.size.width *= [_pagedView scale];
    frame.size.height *= [_pagedView scale];
    frame.size.width += 500.0;
    frame.size.height += 80.0;
    if ([scrollView hasVerticalScroller]) {
        frame.size.width += [[scrollView verticalScroller] frame].size.width;
    }
    if ([scrollView hasHorizontalScroller]) {
        frame.size.height += [[scrollView horizontalScroller] frame].size.height;
    }
    scrollView.verticalRulerView.clientView = self.page;
    scrollView.horizontalRulerView.clientView = self.page;
    if ([scrollView rulersVisible]) {
        if ([scrollView hasVerticalRuler]) {
            frame.size.width += [[scrollView verticalRulerView] frame].size.width;
        }
        if ([scrollView hasHorizontalRuler]) {
            frame.size.height += [[scrollView horizontalRulerView] frame].size.height;
            [[scrollView horizontalRulerView] setAccessoryView:_ribbonView];
            NSRect rulerFrame = scrollView.horizontalRulerView.frame;
            NSRect ribbonFrame;
            ribbonFrame.origin.x = 0;
            ribbonFrame.origin.y = NSMaxY(rulerFrame) - 26.0;
            ribbonFrame.size.width = rulerFrame.size.width;
            ribbonFrame.size.height = 26.0;
            [_ribbonView setFrame:ribbonFrame];
            [_ribbonView setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
        }
    }
    frame.size.height += [_ribbonView frame].size.height;
    frame = [window frameRectForContentRect:frame];

    frame.origin.x = screenFrame.origin.x + 20.0;
    frame.origin.y = screenFrame.origin.y + screenFrame.size.height - (frame.size.height + 20.0);

    if ([defaults boolForKey:DrawLeftViewExpandedKey]) {
        frame.size.width += [defaults floatForKey:DrawLeftViewExpandedWidthKey];
    }
    if ([defaults boolForKey:DrawRightViewExpandedKey]) {
        frame.size.width += [defaults floatForKey:DrawRightViewExpandedWidthKey];
    }

    [window setFrame:frame display:NO animate:NO];

    [[self layerViewController] reload];

    [self updateGrid];
    [self updateRulers];

    [self.inspectorGroupsViewController push:@[self] for:AJRInspectorContentIdentifierAny];

    [self _notifyControllersOfDocumentLoad:_primaryWindowController.contentViewController];

    _documentInfoObserverTokens = [NSMutableArray array];
    for (NSString *key in @[DrawDocumentInfoAuthorKey, DrawDocumentInfoCreationDateKey, DrawDocumentInfoCommentsKey, DrawDocumentInfoCopyrightKey, DrawDocumentInfoLicenseKey]) {
        __weak DrawDocument *weakSelf = self;
        [_documentInfoObserverTokens addObject:[[self documentInfo] addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld block:^(id object, NSString *keyPath, NSDictionary<NSKeyValueChangeKey,id> *change) {
            DrawDocument *strongSelf = weakSelf;
            if (strongSelf != nil) {
                id previousValue = change[NSKeyValueChangeOldKey];
                [[strongSelf prepareUndoWithInvocation] setDocumentInfo:previousValue forKey:keyPath];
            }
        }]];
    }
}

- (void)_notifyControllersOfDocumentLoad:(NSViewController *)viewController {
    DrawViewController *drawViewController = AJRObjectIfKindOfClass(viewController, DrawViewController);
    if (drawViewController != nil) {
        [drawViewController documentDidLoad:self];
    }
    for (NSViewController *childViewController in viewController.childViewControllers) {
        [self _notifyControllersOfDocumentLoad:childViewController];
    }
}

- (NSArray<AJRInspectorIdentifier> *)inspectorIdentifiers {
    NSMutableArray *array = [[super inspectorIdentifiers] mutableCopy];
    [array addObject:AJRInspectorIdentifierDrawDocument];
    return array;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)controller {
    [super windowControllerDidLoadNib:controller];
    [self setupAfterUILoad];
}

#pragma mark - NSNibAwakening

- (void)windowDidLoad {
    NSScrollView *scrollView = [_pagedView enclosingScrollView];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    DrawRulerView *rulerView;

    // Set up the inspectors
    //[(DrawRibbonInspectorController *)[_inspectorGroupsController inspectorControllerForName:DrawInspectorGroupRibbon] installInView:_ribbonView];

    // Set up the paged view
    [_pagedView setScale:1.25];

    // Setup Rulers

    rulerView = [[DrawRulerView alloc] initWithScrollView:scrollView orientation:NSHorizontalRuler];
    [rulerView setReservedThicknessForMarkers:0.0];
    [rulerView setReservedThicknessForAccessoryView:0.0];
    [rulerView setRuleThickness:16.0];
    [rulerView setClientView:[self page]];
    [scrollView setHorizontalRulerView:rulerView];

    rulerView = [[DrawRulerView alloc] initWithScrollView:scrollView orientation:NSVerticalRuler];
    [scrollView setVerticalRulerView:rulerView];
    [rulerView setClientView:[self page]];

    if ([defaults boolForKey:DrawRulersVisibleKey]) {
        [scrollView setRulersVisible:YES];
    }

    // Set up the scroll view

    [scrollView setBackgroundColor:NSColor.underPageBackgroundColor];

    // Set up the tool sets, the current tool set, and associated tools.

    [self _setupToolSets];
    [self setCurrentToolSet:[DrawToolSet toolSetForIdentifier:[[NSUserDefaults standardUserDefaults] objectForKey:DrawCurrentToolSetIDKey]]];
    [self _setupToolSegmentsIn:_toolSegments for:self.displayedToolSet];
    //[self setCurrentTool:_currentToolSet.currentTool];
    [self.currentToolSet toolSetShouldActivateForDocument:self];
    // Call this to force a selection change, even though it's not really changing anything.
    [self clearSelection];
}

- (void)printInfoDidUpdate:(NSNotification *)aNotification {
    NSScrollView *enclosingScrollView = [_pagedView enclosingScrollView];

    [self updateRulers];
    [self updateGrid];
    [_pagedView setNeedsDisplay:YES];

    [[enclosingScrollView horizontalRulerView] setMeasurementUnits:[[[self printInfo] dictionary] objectForKey:NSUnitsOfMeasure]];
    [[enclosingScrollView verticalRulerView] setMeasurementUnits:[[[self printInfo] dictionary] objectForKey:NSUnitsOfMeasure]];
}

- (CGFloat)scale {
    DrawPage *page = [self page];
    return ([page frame].size.width / [page bounds].size.width);
}

- (void)addGraphic:(DrawGraphic *)graphic {
    [[self undoManager] registerUndoWithTarget:self selector:@selector(removeGraphic:) object:graphic];

    [graphic graphicWillAddToView:self];
    [graphic setDocument:self];
    [graphic graphicDidAddToView:self];
    if ([graphic supergraphic]) {
        [graphic removeFromSupergraphic];
    }

    // Add the graphic to our editing context, so we can watch it.
    [_editingContext addObject:graphic];
    [graphic startTrackingEdits];

    if (![DrawGraphic notificationsAreDisabled]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DrawDocumentDidAddGraphicNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:graphic, DrawGraphicKey, nil]];
    }
}

- (void)removeGraphic:(DrawGraphic *)graphic {
    if ([graphic document] != self) {
        [NSException raise:NSInvalidArgumentException format:@"Cannot remove graphic %@, because I don't contain it.", graphic];
    }

    [[self undoManager] registerUndoWithTarget:self selector:@selector(addGraphic:) object:graphic];
    [graphic graphicWillRemoveFromView:self];
    [[graphic page] removeGraphic:graphic];
    [graphic graphicDidRemoveFromView:self];

    // And since we no longer own the object, forget about it.
    [_editingContext forgetObject:graphic];
}

- (void)replaceGraphic:(DrawGraphic *)oldGraphic withGraphic:(DrawGraphic *)newGraphic {
    if ([oldGraphic document] != self) {
        [NSException raise:NSInvalidArgumentException format:@"Cannot remove graphic %@, because I don't contain it.", oldGraphic];
    }
    [newGraphic setDocument:self];
    [newGraphic setLayer:[oldGraphic layer]];

    [oldGraphic graphicWillRemoveFromView:self];
    [newGraphic graphicWillAddToView:self];
    [[oldGraphic page] replaceGraphic:oldGraphic withGraphic:newGraphic];
    [newGraphic graphicDidAddToView:self];
    [oldGraphic graphicDidRemoveFromView:self];

    if ([_storage.selection containsObject:oldGraphic]) {
        [self removeGraphicFromSelection:oldGraphic];
        [self addGraphicToSelection:newGraphic];
    }
}

- (BOOL)useShallowEncode {
    return _useShallowEncode;
}

- (void)displayIntermediateResults {
    NSIndexSet *pageIndexes = [_pagedView visiblePageIndexes];
    NSUInteger index;
    
    index = [pageIndexes firstIndex];
    while (index != NSNotFound) {
        [[_storage.pages objectAtIndex:index] displayIntermediateResults];
        index = [pageIndexes indexGreaterThanIndex:index];
    }
}

- (void)updateMarkings {
    NSScrollView *enclosingScrollView = [[self page] enclosingScrollView];

    [[self page] _updateMarkersForRulerView:[enclosingScrollView horizontalRulerView]];
    [[self page] _updateMarkersForRulerView:[enclosingScrollView verticalRulerView]];

    [[self page] setNeedsDisplay:YES];
}

- (void)ping {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
}

+ (DrawDocument *)_searchResponderChainInWindowForDocument:(NSWindow *)window {
    NSResponder *responder = [window firstResponder];

    while (responder != nil) {
        if ([responder isKindOfClass:[DrawPage class]]) {
            return [(DrawPage *)responder document];
        }
        responder = [responder nextResponder];
    }

    return nil;
}

+ (DrawDocument *)focusedDocument {
    DrawDocument *document = nil;

    for (NSWindow *window in [NSApp orderedWindows]) {
        document = [self _searchResponderChainInWindowForDocument:window];
    }

    if (document == nil) {
        for (NSWindow *window in [NSApp orderedWindows]) {
            if ([[window delegate] isKindOfClass:[DrawDocument class]]) {
                document = (DrawDocument *)[window delegate];
                break;
            }
        }
    }

    return document;
}

#pragma mark - Actions

- (IBAction)toggleInspectors:(NSSegmentedControl *)sender {
    NSSplitViewItem *item = _splitViewController.splitViewItems[2];
    item.animator.collapsed = !item.isCollapsed;
    [sender setSelected:!item.isCollapsed forSegment:0];
}

- (IBAction)toggleLayers:(NSSegmentedControl *)sender {
    NSSplitViewItem *item = _splitViewController.splitViewItems[0];
    item.animator.collapsed = !item.isCollapsed;
    [sender setSelected:!item.isCollapsed forSegment:0];
}

#pragma mark - Document Info

- (NSMutableDictionary<NSString *, id> *)documentInfo {
    return _storage.documentInfo;
}

- (void)setDocumentInfo:(id)value forKey:(nullable NSString *)key {
    [[self prepareWithInvocationTarget:self] setDocumentInfo:[self documentInfoForKey:key] forKey:key];
    [_storage setDocumentInfo:value forKey:key];
}

- (nullable id)documentInfoForKey:(NSString *)key {
    return [_storage documentInfoForKey:key];
}

@end
