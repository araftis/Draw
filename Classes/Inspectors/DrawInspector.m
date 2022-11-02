/*
 DrawInspector.m
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

#import "DrawInspector.h"

#import "DrawDocument.h"
#import "DrawInspectorController.h"

@implementation DrawInspector

static NSMutableDictionary *_inspectors = nil;
static NSMutableDictionary *_ribbonInspectors = nil;

#pragma mark - Initialize

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _inspectors = [[NSMutableDictionary alloc] init];
        _ribbonInspectors = [[NSMutableDictionary alloc] init];
    });
}

#pragma mark - Factory

+ (void)registerInspector:(Class)inspector {
    @autoreleasepool {
        for (Class inspectedClass in [inspector inspectedClasses]) {
            NSMutableSet	*bucket = [_inspectors objectForKey:inspectedClass];
            if (bucket == nil) {
                bucket = [[NSMutableSet alloc] init];
                [_inspectors setObject:bucket forKey:(id)inspectedClass];
            }
            [bucket addObject:inspector];
        }
    }
}

+ (void)registerRibbonInspector:(Class)inspector {
    @autoreleasepool {
        for (Class inspectedClass in [inspector inspectedClasses]) {
            NSMutableSet	*bucket = [_ribbonInspectors objectForKey:inspectedClass];
            if (bucket == nil) {
                bucket = [[NSMutableSet alloc] init];
                [_ribbonInspectors setObject:bucket forKey:(id)inspectedClass];
            }
            [bucket addObject:inspector];
        }
    }
}

//static NSComparator DrawInspectorComparator = ^NSComparisonResult(id obj1, id obj2) {
//    if ([obj1 priority] < [obj2 priority]) return NSOrderedAscending;
//    if ([obj1 priority] > [obj2 priority]) return NSOrderedDescending;
//    return NSOrderedSame;
//};

+ (NSSet *)inspectorClassesForClass:(Class)inspectedClass {
    return [_inspectors objectForKey:inspectedClass];
}

+ (NSSet *)ribbonInspectorClassesForClass:(Class)inspectedClass {
    NSMutableSet	*set = [NSMutableSet set];

    for (Class class in _ribbonInspectors) {
        if ([inspectedClass isSubclassOfClass:class]) {
            [set unionSet:[_ribbonInspectors objectForKey:class]];
        }
    }

    return set;
}

#pragma mark - Factory Clients

+ (NSSet *)inspectedClasses {
    return [NSSet set];
}

+ (CGFloat)priority {
    return MAXFLOAT;
}

+ (NSString *)identifier {
    NSAssert(YES, @"Subclasses of DrawInspector should implement %s", __PRETTY_FUNCTION__);
    return nil;
}

+ (NSString *)name {
    NSAssert(YES, @"Subclasses of DrawInspector should implement %s", __PRETTY_FUNCTION__);
    return nil;
}

#pragma mark - Creation

- (id)initWithInspectorController:(DrawInspectorController *)inspectorController {
    if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]])) {
        _inspectorController = inspectorController;
        _selectionController = [inspectorController selectionController];
    }
    return self;
}

#pragma mark - Properties

@synthesize inspectorController = _inspectorController;
@synthesize selectionController = _selectionController;

- (DrawDocument *)document {
    return [[self inspectorController] document];
}

- (NSPrintInfo *)printInfo {
    return [[self document] printInfo];
}

#pragma mark - Inspection

- (Class)inspectedType; {
    return Nil;
}

- (void)update {
    // Just make sure our inspector's view is loaded.
    [self view];
}

- (void)startObservingSelection {
}

- (void)stopObservingSelection {
}

#pragma mark - Selection

- (NSArray *)selection {
    return [_selectionController selectedObjects];
}

- (NSArray *)inspectedObjectsWithCreationCallback:(DrawAspectCreationCallback)creationCallback {
    NSMutableArray	*objects = [NSMutableArray array];

    for (id object in [self selection]) {
        id inspectedObject = [self inspectedObjectForSelectedObject:object withCreationCallback:creationCallback];
        if (inspectedObject) {
            [objects addObject:inspectedObject];
        }
    }

    return objects;
}

- (id)inspectedObjectForSelectedObject:(id)object withCreationCallback:(DrawAspectCreationCallback)creationCallback {
    Class	inspectedType = [self inspectedType];
    id		inspectedObject = object;

    if (inspectedType && ![object isKindOfClass:inspectedType]) {
        inspectedObject = nil;
    }

    return inspectedObject;
}

#pragma mark - Utilities

- (NSSet *)inspectedValuesForKeyPath:(NSString *)keyPath {
    NSMutableSet	*values = [NSMutableSet set];

    for (id object in [self inspectedObjectsWithCreationCallback:NULL]) {
        id value = [object valueForKeyPath:keyPath];
        if (value) {
            [values addObject:value];
        } else {
            [values addObject:[NSNull null]];
        }
    }

    return values;
}

- (void)setInspectedValue:(id)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback {
    for (id object in [self inspectedObjectsWithCreationCallback:creationCallback]) {
        [object setValue:value forKeyPath:keyPath];
    }
}

- (void)setInspectedFloat:(CGFloat)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback {
    [self setInspectedValue:[NSNumber numberWithFloat:value] forKeyPath:keyPath creationCallback:creationCallback];
}

- (void)setInspectedDouble:(double)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback {
    [self setInspectedValue:[NSNumber numberWithDouble:value] forKeyPath:keyPath creationCallback:creationCallback];
}

- (void)setInspectedInteger:(NSInteger)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback {
    [self setInspectedValue:[NSNumber numberWithInteger:value] forKeyPath:keyPath creationCallback:creationCallback];
}

- (void)setInspectedBool:(BOOL)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback {
    [self setInspectedValue:[NSNumber numberWithBool:value] forKeyPath:keyPath creationCallback:creationCallback];
}

@end
