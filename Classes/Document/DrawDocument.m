/*
 DrawDocument.m
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

#import "DrawDocument.h"

#import "DrawAspect.h"
#import "DrawBook.h"
#import "DrawDocumentStorage.h"
#import "DrawGraphic.h"
#import "DrawGraphicsToolSet.h"
#import "DrawGraphicsInspectorController.h"
#import "DrawLayer.h"
#import "DrawPage.h"
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

const NSNotificationName DrawViewWillDeallocateNotification = @"DrawViewWillDeallocateNotification";
const NSNotificationName DrawDocumentDidAddGraphicNotification = @"DrawDocumentDidAddGraphicNotification";
NSString * const DrawGraphicKey = @"DrawGraphicKey";
const NSNotificationName DrawViewDidChangeSelectionNotification = @"DrawViewDidChangeSelectionNotification";
NSString * const DrawViewSelectionKey = @"DrawViewSelectionKey";
const NSNotificationName DrawViewDidUpdateNotification = @"DrawViewDidUpdateNotification";
const NSNotificationName DrawDocumentDidUpdateLayoutNotification = @"DrawDocumentDidUpdateLayoutNotification";
const NSNotificationName DrawObjectDidResignRulerNotification = @"DrawObjectDidResignRulerNotification";

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
    NSMutableArray<id <AJRInvalidation>> *_toolSetObserverTokens;
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

- (void)_initializeTemplateGraphic:(DrawGraphic *)templateGraphic {
    for (Class aspectClass in [DrawAspect aspects]) {
        // We only want to include aspects that actually override defaultAspectForGraphic: If we take others, then we can pick up subclasses that aren't meant to be added as defaults.
        if ([templateGraphic primaryAspectOfType:aspectClass create:NO] == nil
            && [aspectClass overridesSelector:@selector(defaultAspectForGraphic:)]) {
            DrawAspect *aspect = [aspectClass defaultAspectForGraphic:_storage.templateGraphic];
            if (aspect != nil) {
                [templateGraphic addAspect:aspect withPriority:[aspectClass defaultPriority]];
            }
        }
    }
}

- (void)_initializeTemplateGraphic {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:DrawTemplateGraphicKey];
    if (data) {
        _storage.templateGraphic = [NSKeyedUnarchiver ajr_unarchivedObjectWithData:data error:NULL];
    }
    if (_storage.templateGraphic == nil) {
        _storage.templateGraphic = [[DrawGraphic alloc] initWithFrame:NSZeroRect];
        [self _initializeTemplateGraphic:_storage.templateGraphic];
    }
}

- (id)init {
    if ((self = [super init])) {
        _iconObserverTokens = [NSMutableDictionary dictionary];
        _toolSetObserverTokens = [NSMutableArray array];

        // Editing
        _editingContext = [[AJREditingContext alloc] init];
        _editingContext.delegate = self;
        // We don't want the editing context to have an undo manager, because we want to manage the undo events via the delegate callback.
        _editingContext.undoManager = nil;
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

    [_iconObserverTokens invalidateObjects];
    [_toolSetObserverTokens invalidateObjects];

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
                DrawDocument *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    if ([tool isUsedByToolSet:strongSelf.displayedToolSet]) {
                        if (!tool.primaryToolSet.isGlobal) {
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

    if (segments == _toolSegments) {
        self.displayedToolSet = toolSet;
    }

    // This is rediculous, but the toolbar item is refusing to resize correctly on startup, even when I tell the view hierarchy that it's out of sync.
    CGFloat height = segments.fittingSize.height;
    CGFloat width = segments.fittingSize.width;
    [segments sizeToFit];
    if (segments.segmentCount > 0) {
        NSRect last = [(AJRSegmentedCell *)[segments cell] rectForSegment:segments.segmentCount - 1 inFrame:segments.bounds];
        
        width = NSMaxX(last);
        height = 28.0;
        
        [segments removeConstraints:segments.constraints];
        [segments addConstraints:@[
            [segments.widthAnchor constraintEqualToConstant:width],
            [segments.heightAnchor constraintEqualToConstant:height],
        ]];
    }
}

#pragma mark - Properties

+ (Class)storageClass {
    return DrawDocumentStorage.class;
}

- (void)setStorage:(DrawDocumentStorage *)storage {
    if (_storage != nil) {
        // We're reverting to our saved state.
        for (DrawLayer *layer in _storage.layers) {
            layer.document = nil;
        }
        for (DrawPage *page in _storage.pages) {
            // We need to remove all the objects from our editing context
            [self enumerateGraphicsUsing:^(DrawGraphic * _Nonnull graphic, BOOL * _Nonnull stop) {
                [graphic enumerateAspectsWithBlock:^(DrawAspect * _Nonnull aspect) {
                    [self removeObjectFromEditingContext:aspect];
                }];
                [self removeObjectFromEditingContext:graphic];
            }];
            page.document = nil;
        }
        _storage.masterPageOdd.document = nil;
        _storage.masterPageEven.document = nil;
        _storage.templateGraphic.document = nil;
        _storage.variableStore.variableDelegate = nil;
    }

    // Make sure our variables point to us.
    [_storage.variableStore enumerate:^(NSString *key, id <AJREvaluation> object, BOOL *stop) {
        AJRObjectIfKindOfClass(object, DrawVariable).document = self;
    }];

    // Does this need to do some sort notifications? I'm assuming no to start with, because this should only be called during document unarchiving.
    _storage = storage;

    // Make sure, in case we added a new default aspect, that it gets initialized. This is just future proofing
    [self _initializeTemplateGraphic:_storage.templateGraphic];

    self.printInfo = _storage.printInfo;

    // We have to "claim" ownership of some of our storage's objects.
    for (DrawLayer *layer in _storage.layers) {
        layer.document = self;
    }

    for (DrawPage *page in _storage.pages) {
        page.document = self;
    }

    // And now we need to add all our graphics back in.
    [self enumerateGraphicsUsing:^(DrawGraphic *graphic, BOOL *stop) {
        // We do this check, because a graphic might get passed to us twice.
        [self addObjectToEditingContext:graphic];
        [graphic enumerateAspectsWithBlock:^(DrawAspect *aspect) {
            [self addObjectToEditingContext:aspect];
        }];
    }];
    _storage.templateGraphic.document = self;

    _storage.masterPageOdd.document = self;
    _storage.masterPageEven.document = self;

    [_pagedView reloadPages];
    [self updateGrid];
    [self updateRulers];

    if (_pagedView) {
        _pagedView.enclosingScrollView.horizontalRulerView.clientView = self.page;
        _pagedView.enclosingScrollView.verticalRulerView.clientView = self.page;
    }

    _storage.variableStore.variableDelegate = self;
    [_storage.variableStore.symbols enumerateKeysAndObjectsUsingBlock:^(NSString *key, id <AJREvaluation> object, BOOL *stop) {
        AJRVariable *variable = AJRObjectIfKindOfClass(object, AJRVariable);
        if (variable != nil) {
            [variable addListener:self];
        }
    }];
}

// MARK: - Layout Properties

- (void)setPrintInfo:(NSPrintInfo *)printInfo {
    // Make sure the storage reflects our print info.
    [super setPrintInfo:printInfo];
    _storage.printInfo = self.printInfo;
    [self updateLayoutAndNotify:YES];
}

- (void)setPrinter:(NSPrinter *)printer {
    NSPrinter *current = printer;
    [self registerUndoWithTarget:self handler:^(DrawDocument *target) {
        [target setPrinter:current];
    }];
    _storage.printer = printer;
    _storage.printInfo.printer = printer;
}

- (NSPrinter *)printer {
    return _storage.printer;
}

- (void)setPaper:(AJRPaper *)paper {
    AJRPaper *current = paper;
    [self registerUndoWithTarget:self handler:^(DrawDocument *target) {
        [target setPaper:current];
    }];
    _storage.paper = paper;
    _storage.printInfo.paper = paper;
    [self updateLayoutAndNotify:YES];
}

- (AJRPaper *)paper {
    return _storage.paper;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingOrientation {
    return [NSSet setWithObjects:@"printInfo.orientation", nil];
}

- (void)setOrientation:(NSPaperOrientation)orientation {
    NSPaperOrientation current = orientation;
    [self registerUndoWithTarget:self handler:^(DrawDocument *target) {
        [target setOrientation:current];
    }];
    self.printInfo.orientation = orientation;
    [self updateLayoutAndNotify:YES];
}

- (NSPaperOrientation)orientation {
    return self.printInfo.orientation;
}

- (NSArray<DrawMeasurementUnit *> *)allUnitsOfMeasure {
    return DrawMeasurementUnit.availableMeasurementUnits;
}

- (void)setUnitOfMeasure:(DrawMeasurementUnit *)unitOfMeasure {
    DrawMeasurementUnit *current = _storage.unitOfMeasure;
    [self registerUndoWithTarget:self handler:^(DrawDocument *target) {
        [self setUnitOfMeasure:current];
    }];
    _storage.unitOfMeasure = unitOfMeasure;
    [self updateLayoutAndNotify:YES];
}

- (DrawMeasurementUnit *)unitOfMeasure {
    return _storage.unitOfMeasure;
}

- (void)setMargins:(AJRInset)margins {
    AJRInset current = _storage.margins;
    [self registerUndoWithTarget:self handler:^(DrawDocument *target) {
        [self setMargins:current];
    }];
    _storage.margins = margins;
    [self updateLayoutAndNotify:YES];
}

- (AJRInset)margins {
    return _storage.margins;
}

- (void)setPaperColor:(NSColor *)color {
    if (_storage.paperColor != color) {
        [self registerUndoWithTarget:self selector:@selector(setPaperColor:) object:_storage.paperColor];
        [[self undoManager] setActionName:@"Paper Color"];
        _storage.paperColor = color;
        [self setPagesNeedDisplay:YES];
    }
}

/// Used by the inspectors to get the valid list of printers available on the system.
- (NSArray<NSPrinter *> *)allPrinters {
    NSMutableArray<NSPrinter *> *printers = [NSMutableArray array];

    [printers addObject:NSPrinter.genericPrinter];
    for (NSString *name in NSPrinter.printerNames) {
        [printers addObject:[NSPrinter printerWithName:name]];
    }

    return printers;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingAllPapers {
    return [NSSet setWithObjects:@"printer", nil];
}

- (NSArray<AJRPaper *> *)allPapers {
    if (self.printInfo.printer == nil) {
        return [AJRPaper allGenericPapers];
    }
    return self.printer.allPapers;
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

- (void)setVariableStore:(AJRStore *)variableStore {
    _storage.variableStore = variableStore;
}

- (AJRStore *)variableStore {
    return _storage.variableStore;
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

                if (_currentToolSet != nil) {
                    [_toolSetObserverTokens invalidateObjects];
                }

                _currentToolSet = toolSet;
                if (!newIsGlobal) {
                    self.displayedToolSet = _currentToolSet;
                }

                self.currentTool = [_currentToolSet currentTool];

                [_toolSetSegments setImage:self.displayedToolSet.icon forSegment:0];

                if (!newIsGlobal) {
                    [self _setupToolSegmentsIn:_toolSegments for:_currentToolSet];
                }

                if (_currentToolSet != nil) {
                    for (DrawTool *tool in _currentToolSet.tools) {
                        // Avoid possible retain cycles.
                        __weak DrawDocument *weakSelf = self;
                        [_toolSetObserverTokens addObject:[tool addObserver:self forKeyPath:@"currentAction" options:0 block:^(id object, NSString *keyPath, NSDictionary<NSKeyValueChangeKey,id> *change) {
                            DrawDocument *strongSelf = weakSelf;
                            if (strongSelf != nil) {
                                NSInteger index = [strongSelf->_currentToolSet.tools indexOfObjectIdenticalTo:strongSelf->_currentToolSet.currentTool];
                                if (index != NSNotFound) {
                                    [strongSelf _setImageIn:strongSelf->_toolSegments forSegment:index tool:strongSelf->_currentTool action:strongSelf->_currentTool.currentAction];
                                }
                            }
                        }]];
                    }
                }
            }
        }
    }
}

- (void)setCurrentTool:(DrawTool *)newTool {
    if (newTool != nil) {
        if ((!_currentTool || (_currentTool && [_currentTool toolShouldDeactivateForDocument:self]))
            && (!newTool || (newTool && [newTool toolShouldActivateForDocument:self]))) {
            // The new tool set, which may be the old tool set.
            DrawToolSet *newToolSet = self.currentToolSet;
            if (![newTool isUsedByToolSet:_currentToolSet]) {
                if (self.displayedToolSet != nil && [newTool isUsedByToolSet:self.displayedToolSet]) {
                    newToolSet = self.displayedToolSet;
                } else {
                    newToolSet = [newTool primaryToolSet];
                }
            }
            
            // This makes sure the segments are nominally setup.
            NSInteger globalIndex = NSNotFound;
            NSInteger index = NSNotFound;

            if (newToolSet.isGlobal) {
                globalIndex = [newToolSet.tools indexOfObjectIdenticalTo:newTool];
            } else {
                index = [newToolSet.tools indexOfObjectIdenticalTo:newTool];
            }

            DrawTool *tempTool = _currentTool;
            _currentTool = nil;
            [tempTool toolDidDeactivateForDocument:self];
            
            _currentTool = newTool;
            // This is a little jinky, but setting the currentToolSet will cause it to select it's remembered currentTool, which is likely to be different from what we're selecting. As such, make sure it's current tool is the tool we want.
            newToolSet.currentTool = newTool;
            self.currentToolSet = newToolSet;
            _currentToolSet.currentTool = _currentTool;

            for (NSInteger x = 0; x < [_globalToolSegments segmentCount]; x++) {
                [_globalToolSegments setSelected:x == globalIndex forSegment:x];
            }
            for (NSInteger x = 0; x < [_toolSegments segmentCount]; x++) {
                [_toolSegments setSelected:x == index forSegment:x];
            }

            if (_currentToolSet.isGlobal) {
                [_globalToolSegments setImage:_currentTool.currentAction.icon forSegment:globalIndex];
            } else {
                [self _setImageIn:_toolSegments forSegment:index tool:_currentTool action:_currentTool.currentAction];
            }
            [_currentTool toolDidActivateForDocument:self];
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

+ (BOOL)preservesVersions {
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
        _pagedView.delegate = self;
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
    [self.inspectorGroupsViewController push:@[self.page] for:AJRInspectorContentIdentifierAny];
    [self.inspectorGroupsViewController push:@[_storage.templateGraphic] for:AJRInspectorContentIdentifierAny];

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

- (void)updateLayoutAndNotify:(BOOL)flag {
    NSScrollView *enclosingScrollView = [_pagedView enclosingScrollView];

    [_pagedView reloadPages];

    [self updateRulers];
    [self updateGrid];
    
    [[enclosingScrollView horizontalRulerView] setMeasurementUnits:self.unitOfMeasure.identifier.capitalizedString];
    [[enclosingScrollView verticalRulerView] setMeasurementUnits:self.unitOfMeasure.identifier.capitalizedString];
    
    if (flag) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DrawDocumentDidUpdateLayoutNotification object:self];
    }
}

- (CGFloat)scale {
    DrawPage *page = [self page];
    return ([page frame].size.width / [page bounds].size.width);
}

- (void)addGraphic:(DrawGraphic *)graphic {
    [[self undoManager] registerUndoWithTarget:self selector:@selector(removeGraphic:) object:graphic];

    [graphic graphicWillAddToDocument:self];
    [graphic setDocument:self];
    [graphic graphicDidAddToDocument:self];
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
    if (graphic.document == nil) {
        // This happens when an object is somehow archived, but shouldn't have been. Normally it's a bug with related graphics. We're just going to try and remove it from everything.
        for (DrawPage *page in self.pages) {
            [page removeGraphic:graphic];
        }
    } else {
        if ([graphic document] != self) {
            [NSException raise:NSInvalidArgumentException format:@"Cannot remove graphic %@, because I don't contain it.", graphic];
        }

        [[self undoManager] registerUndoWithTarget:self selector:@selector(addGraphic:) object:graphic];
        [graphic graphicWillRemoveFromDocument:self];
        [[graphic page] removeGraphic:graphic];
        [graphic graphicDidRemoveFromDocument:self];

        // And since we no longer own the object, forget about it.
        [_editingContext forgetObject:graphic];
    }
}

- (void)replaceGraphic:(DrawGraphic *)oldGraphic withGraphic:(DrawGraphic *)newGraphic {
    if ([oldGraphic document] != self) {
        [NSException raise:NSInvalidArgumentException format:@"Cannot remove graphic %@, because I don't contain it.", oldGraphic];
    }
    [newGraphic setDocument:self];
    [newGraphic setLayer:[oldGraphic layer]];

    [oldGraphic graphicWillRemoveFromDocument:self];
    [newGraphic graphicWillAddToDocument:self];
    [[oldGraphic page] replaceGraphic:oldGraphic withGraphic:newGraphic];
    [newGraphic graphicDidAddToDocument:self];
    [oldGraphic graphicDidRemoveFromDocument:self];

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

#pragma mark - Editing Context

- (void)addObjectToEditingContext:(AJREditableObject *)object {
    // Only do this if the object isn't already in our editing context.
    if (object.editingContext != self->_editingContext) {
        if (object.editingContext != nil) {
            // Steal ownership
            [object.editingContext forgetObject:object];
        }
        [_editingContext addObject:object];
        [object startTrackingEdits];
    }
}

- (void)removeObjectFromEditingContext:(AJREditableObject *)object {
    // Only actually remove the object if we already own the object.
    if (object.editingContext == self.editingContext) {
        [object.editingContext forgetObject:object];
    }
}

#pragma mark - Global Actions

- (void)makeVisiblePageFirstResponderAndScrollToVisible:(BOOL)scrollToVisible {
    NSIndexSet *visiblePages = [_pagedView visiblePageIndexes];
    NSInteger index = visiblePages.firstIndex;
    if (index != NSNotFound) {
        [self makePageFirstResponder:_storage.pages[index] andScrollToVisible:scrollToVisible];
    }
}

- (void)makePageFirstResponder:(DrawPage *)page andScrollToVisible:(BOOL)scrollToVisible {
    [page.window makeFirstResponder:page];
    if (scrollToVisible) {
        NSInteger index = [_storage.pages indexOfObjectIdenticalTo:page];
        if (index != NSNotFound) {
            [_pagedView scrollPageToVisible:index];
        }
    }
}

- (void)makePageAtIndexFirstResponder:(NSInteger)index andScrollToVisible:(BOOL)scrollToVisible {
    [self makePageFirstResponder:_storage.pages[index] andScrollToVisible:scrollToVisible];
}

- (void)makeSelectionOrVisiblePageFirstResponderAndScrollToVisible:(BOOL)scrollToVisible {
    DrawGraphic *graphic = _storage.selection.anyObject;
    if (graphic != nil) {
        [self makeGraphicFirstResponder:graphic andScrollToVisible:scrollToVisible];
    } else {
        [self makeVisiblePageFirstResponderAndScrollToVisible:scrollToVisible];
    }
}

- (void)makeGraphicFirstResponder:(DrawGraphic *)graphic andScrollToVisible:(BOOL)scrollToVisible {
    [self makePageFirstResponder:graphic.page andScrollToVisible:scrollToVisible];
}

@end

// This is just a tiny re-mapping of the printer's name to make it play nice in the UI.

@interface NSPrinter (DrawInspection)

@property (nonatomic,readonly) NSString *displayName;

@end

@implementation NSPrinter (DrawInspection)

- (NSString *)displayName {
    NSString *name = self.name;

    if ([name isEqualToString:AJRGenericPrinterName]) {
        return [[AJRTranslator translatorForClass:[DrawDocument class]] valueForKey:@"Any Printer"];
    }

    return name;
}

@end
