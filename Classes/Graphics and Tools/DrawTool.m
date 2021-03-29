/*
DrawTool.m
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

#import "DrawTool.h"

#import "DrawDocument.h"
#import "DrawEvent.h"
#import "DrawGraphic.h"
#import "DrawPage.h"
#import "DrawLayer.h"
#import "DrawToolAction.h"
#import "DrawToolSet.h"

NSString *DrawToolDidBecomeActiveNotification = @"DrawToolDidBecomeActiveNotification";

static NSMutableDictionary *_tools = nil;

@interface DrawTool ()

@property (nonatomic,strong) NSArray<DrawToolAction *> *actions;

@end

@implementation DrawTool {
    NSCursor *_cursor;
    DrawGraphic *_graphic;
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _tools = [[NSMutableDictionary alloc] init];
    });
}

#pragma mark - Factory

+ (NSString *)identifier {
    return [[[AJRPlugInManager sharedPlugInManager] extensionPointForName:@"draw-tool"] valueForProperty:@"id" onExtensionForClass:[self class]];
}

+ (NSString *)name {
    return [[[AJRPlugInManager sharedPlugInManager] extensionPointForName:@"draw-tool"] valueForProperty:@"name" onExtensionForClass:[self class]];
}

- (NSArray<DrawToolAction *> *)createActions {
    NSArray *rawActions = [[[AJRPlugInManager sharedPlugInManager] extensionPointForName:@"draw-tool"] valueForProperty:@"actions" onExtensionForClass:[self class]];
    NSMutableArray<DrawToolAction *> *actions = [NSMutableArray array];

    for (NSDictionary *raw in rawActions) {
        NSString *title = raw[@"title"];
        NSImage *icon = raw[@"icon"];
        NSCursor *cursor = raw[@"cursor"];
        NSInteger tag = [raw[@"tag"] integerValue];
        Class graphicClass = raw[@"graphicClass"];

        [actions addObject:[DrawToolAction toolActionWithTool:self title:title icon:icon cursor:cursor tag:tag graphicClass:graphicClass]];
    }

    return actions;
}

#pragma mark - Creation

- (id)init {
    NSAssert(YES, @"-init should never be called. Call -initWithToolSet: instead.");
    return [self initWithToolSet:[[DrawToolSet alloc] init]];
}

- (id)initWithToolSet:(DrawToolSet *)toolSet {
    if ((self = [super init])) {
        _toolSet = toolSet;
    }
    return self;
}

#pragma mark - Properties

- (NSString *)name {
    return [[self class] name];
}

- (NSString *)identifier {
    return [[self class] identifier];
}

- (NSArray<DrawToolAction *> *)actions {
    if (_actions == nil) {
        NSArray<DrawToolAction *> *actions = [self createActions];
        NSAssert([actions count] > 0, @"The subclass, %@, of DrawTool must have at least one DrawToolAction.", NSStringFromClass([self class]));
        _actions = actions;
        _currentAction = [_actions objectAtIndex:0];
    }
    return _actions;
}

@synthesize currentAction = _currentAction;

- (void)setCurrentAction:(DrawToolAction *)currentAction {
    [self actions];
    _currentAction = currentAction;
}

- (DrawToolAction *)currentAction {
    [self actions];
    return _currentAction;
}

- (CGFloat)displayPriority {
    return [[[[AJRPlugInManager sharedPlugInManager] extensionPointForName:@"draw-tool"] valueForProperty:@"displayPriority" onExtensionForClass:self.class] floatValue];
}

#pragma mark - Activation

- (NSString *)activationKey {
    return [[[AJRPlugInManager sharedPlugInManager] extensionPointForName:@"draw-tool"] valueForProperty:@"activationKey" onExtensionForClass:self.class];
}

- (NSCursor *)cursor {
    if (!_cursor) {
        _cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursorCross"] hotSpot:(NSPoint){7.0, 7.0}];
    }

    return _cursor;
}

- (DrawGraphic *)graphicWithPoint:(NSPoint)point document:(DrawDocument *)document page:(DrawPage *)page {
    return nil;
}

#pragma mark - Event Handling

- (BOOL)waitForMouseDrag:(DrawEvent *)drawEvent {
    NSEvent *event = [NSApp nextEventMatchingMask:NSEventMaskLeftMouseDown | NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseUp
                                         untilDate:[NSDate distantFuture]
                                            inMode:NSDefaultRunLoopMode
                                           dequeue:NO];
    if ([event type] == NSEventTypeLeftMouseDragged) return YES;

    return NO;
}

- (BOOL)mouseDown:(DrawEvent *)event {
    if (![self waitForMouseDrag:event]) return NO;
    if ([event layerIsLockedOrNotVisible]) return NO;

    if (_graphic) {
        _graphic = nil;
    }

    _graphic = [self graphicWithPoint:event.locationOnPageSnappedToGrid document:event.document page:event.page];

    [[event page] addGraphic:_graphic select:YES byExtendingSelection:NO];

    [_graphic trackMouse:event];

    _graphic = nil;

    return YES;
}

- (BOOL)mouseDragged:(DrawEvent *)event {
    return NO;
}

- (BOOL)mouseUp:(DrawEvent *)event {
    return NO;
}

- (BOOL)mouseMoved:(DrawEvent *)event {
    return NO;
}

- (BOOL)mouseEntered:(DrawEvent *)event {
    return NO;
}

- (BOOL)mouseExited:(DrawEvent *)event {
    return NO;
}

- (BOOL)rightMouseDown:(DrawEvent *)event {
    return NO;
}

- (BOOL)rightMouseDragged:(DrawEvent *)event {
    return NO;
}

- (BOOL)rightMouseUp:(DrawEvent *)event {
    return NO;
}

- (BOOL)keyDown:(DrawEvent *)event {
    if (([[event characters] characterAtIndex:0] == 27) && _graphic) {
        [_graphic setEditing:NO];
        _graphic = nil;
        return YES;
    }
    return NO;
}

- (BOOL)keyUp:(DrawEvent *)event {
    return NO;
}

- (BOOL)flagsChanged:(DrawEvent *)event {
    return NO;
}

- (BOOL)helpRequested:(DrawEvent *)event {
    return NO;
}

- (NSMenu *)menuForEvent:(DrawEvent *)event {
    return nil;
}

#pragma mark - Icon

- (NSImage *)icon {
    return nil;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p: %@>", NSStringFromClass([self class]), self, [self.class identifier]];
}

#pragma mark - Activation

- (BOOL)toolShouldActivateForDocument:(DrawDocument *)document {
    return YES;
}

- (void)toolDidActivateForDocument:(DrawDocument *)document {
    [[[document pagedView] enclosingScrollView] setDocumentCursor:[self cursor]];
}

- (BOOL)toolShouldDeactivateForDocument:(DrawDocument *)document {
    return YES;
}

- (void)toolDidDeactivateForDocument:(DrawDocument *)document {
    [[[document pagedView] enclosingScrollView] setDocumentCursor:nil];
}

- (DrawDocument *)activeDocument {
    return (DrawDocument *)[[NSApp keyWindow] delegate];
}

@end
