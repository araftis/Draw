//
//  DrawInspectorController.m
//  Draw
//
//  Created by Alex Raftis on 8/12/11.
//  Copyright (c) 2011 Apple, Inc. All rights reserved.
//

#import "DrawInspectorController.h"

#import "DrawDocument.h"

#import <AJRFoundation/NSSet+Extensions.h>
#import <AJRInterface/AJRInterface.h>

@interface DrawInspectorController ()

- (void)stopInspectorsObserving:(NSSet *)inspectors;
- (void)startInspectorsObserving:(NSSet *)inspectors;

@end


@implementation DrawInspectorController

#pragma mark - Factory Client

+ (NSString *)name {
    return nil;
}

+ (NSString *)identifier {
    return nil;
}

+ (NSImage *)icon {
    NSImage *image = [AJRImages imageNamed:[NSStringFromClass(self) stringByAppendingString:@"Template"] forClass:self];
    if (image == nil) {
        image = [AJRImages imageNamed:NSStringFromClass(self) forClass:self];
    }
    return image;
}

+ (CGFloat)priority {
    return 10.0;
}

#pragma mark - Creation

- (id)initWithDocument:(DrawDocument *)document {
    if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]])) {
        _document = document;
        [_document addObserver:self forKeyPath:@"selection" options:0 context:(__bridge void *)(self)];

        _inspectors = [[NSMutableDictionary alloc] init];
        _selectionController = [[NSArrayController alloc] init];
    }
    return self;
}

#pragma mark - Destruction

- (void)dealloc {
    [_document removeObserver:self forKeyPath:@"selection"];
    [self stopInspectorsObserving:[NSSet setWithArray:_currentInspectors]];
}

#pragma mark - Properties

@synthesize document = _document;
@synthesize currentInspectors = _currentInspectors;
@synthesize selectionController = _selectionController;

#pragma mark - Installation

- (void)installInView:(NSView *)view {
    NSView *controlledView = [self view];

    AJRLogDebug(@"insert %@ into %@", controlledView, view);
    [controlledView setFrame:[view bounds]];
    [view addSubview:controlledView];
}

#pragma mark - Inspectors

- (NSSet *)inspectorClassesForObject:(id)object {
    NSAssert(YES, @"Subclasses of %@ should implement %s", NSStringFromClass([self class]), __PRETTY_FUNCTION__);
    return nil;
}

- (NSSet *)inspectorClassesForSelection {
    NSMutableSet *result = [NSMutableSet set];

    for (id object in [_selectionController selectedObjects]) {
        [result unionSet:[self inspectorClassesForObject:object]];
    }

    return result;
}

- (NSArray *)inspectorsForSelection {
    NSMutableArray *inspectors = [NSMutableArray array];

    for (Class inspectorClass in [self inspectorClassesForSelection]) {
        DrawInspector *instance;

        instance = [_inspectors objectForKey:inspectorClass];
        if (instance == nil) {
            instance = [[inspectorClass alloc] initWithInspectorController:self];
            [_inspectors setObject:instance forKey:(id)inspectorClass];
        }

        [inspectors addObject:instance];
    }

    [inspectors sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        CGFloat priority1 = [[obj1 class] priority];
        CGFloat priority2 = [[obj2 class] priority];
        if (priority1 < priority2) return NSOrderedAscending;
        if (priority1 > priority2) return NSOrderedDescending;
        return NSOrderedSame;
    }];

    return inspectors;
}

- (void)stopInspectorsObserving:(NSSet *)inspectors {
    for (DrawInspector *inspector in inspectors) {
        [inspector stopObservingSelection];
    }
}

- (void)startInspectorsObserving:(NSSet *)inspectors {
    for (DrawInspector *inspector in inspectors) {
        [inspector startObservingSelection];
    }
}

- (void)updateInspectors {
    NSSet *previousInspectors = [NSSet setWithArray:_currentInspectors];
    NSMutableSet *currentInspectors;

    _currentInspectors = [self inspectorsForSelection];
    currentInspectors = [NSMutableSet setWithArray:_currentInspectors];

    [self stopInspectorsObserving:[previousInspectors setByRemovingObjects:currentInspectors]];
    [self startInspectorsObserving:[currentInspectors setByRemovingObjects:previousInspectors]];

    [currentInspectors unionSet:previousInspectors];
    for (DrawInspector *inspector in currentInspectors) {
        [inspector view]; // Make sure the inspector has loaded its view.
        [inspector update];
    }
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selection"]) {
        [_selectionController setContent:[[(DrawDocument *)object selectionForInspection] allObjects]];
        [_selectionController setSelectedObjects:[_selectionController content]];
        [self updateInspectors];
    }
}

@end
