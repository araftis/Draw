/*
 DrawTool.m
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

#import "DrawTool.h"

#import "DrawDocument.h"
#import "DrawEvent.h"
#import "DrawGraphic.h"
#import "DrawPage.h"
#import "DrawToolAction.h"
#import "DrawToolSet.h"
#import <Draw/Draw-Swift.h>

NSString *DrawToolDidBecomeActiveNotification = @"DrawToolDidBecomeActiveNotification";

static NSMutableDictionary *_tools = nil;

@interface DrawTool ()

@property (nonatomic,strong) NSArray<DrawToolAction *> *actions;
@property (nonatomic,strong) NSMutableArray<DrawToolSet *> *toolSets;

@end

@implementation DrawTool {
    NSCursor *_cursor;
    DrawGraphic *_graphic;

    NSImage *_newGraphicImage; // Used when the tool adds via a new graphic template, rather than drag.
    DrawDrawingToken _newGraphicToken;
    NSRect _newGraphicRect;
    NSPoint _newGraphicOffset;
    DrawPage *_newGraphicPage; // Needed so that we can manipulate the image outside the event cycle. For example, if our tool deactivates.
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _tools = [[NSMutableDictionary alloc] init];
    });
}

#pragma mark - Factory

+ (NSString *)identifier {
    return [[[AJRPlugInManager sharedPlugInManager] extensionPointForName:@"draw-tool"] valueForProperty:@"id" onExtensionForClass:self];
}

+ (NSString *)name {
    return [[[AJRPlugInManager sharedPlugInManager] extensionPointForName:@"draw-tool"] valueForProperty:@"name" onExtensionForClass:self];
}

+ (BOOL)addsViaDrag {
    return [[[AJRPlugInManager.sharedPlugInManager extensionPointForName:@"draw-tool"] valueForProperty:@"addsViaDrag" onExtensionForClass:self] boolValue];
}

+ (CGSize)newGraphicSize {
    return [[[AJRPlugInManager.sharedPlugInManager extensionPointForName:@"draw-tool"] valueForProperty:@"newGraphicSize" onExtensionForClass:self.class] sizeValue];
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

#pragma mark - Aliasing

- (void)addAliasedToolSet:(DrawToolSet *)additionalToolSet {
    [_toolSets addObject:additionalToolSet];
}

- (BOOL)isUsedByToolSet:(DrawToolSet *)toolSet {
    return [_toolSets containsObjectIdenticalTo:toolSet];
}

- (DrawToolSet *)primaryToolSet {
    return [_toolSets firstObject];
}

#pragma mark - Creation

- (id)init {
    NSAssert(YES, @"-init should never be called. Call -initWithToolSet: instead.");
    return [self initWithToolSet:[[DrawToolSet alloc] init]];
}

- (id)initWithToolSet:(DrawToolSet *)toolSet {
    if ((self = [super init])) {
        // NOTE: Techinically, we should be using an NSPointerArray with weak object pointers, because we're creating a retain cycle here. However, in this case, we don't really care, because these objects never get freed, as in they're alive for the entire life span of the owning process.
        _toolSets = [NSMutableArray array];
        [_toolSets addObject:toolSet];
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
    if (_newGraphicImage != nil) {
        [self _createOrUpdateNewGraphicImageIn:_newGraphicPage display:YES];
    }
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
    if ([event type] == NSEventTypeLeftMouseDragged) {
        return YES;
    }

    return NO;
}

- (BOOL)mouseDown:(DrawEvent *)event {
    // Let's do this first, since we can have multiple possibilities of what
    // happens on mouse down.
    if ([event layerIsLockedOrNotVisible]) {
        return NO;
    }

    if (_newGraphicImage) {
        // This means that we're creating a new graphic as a "stamp" action, so
        // we want to just add the graphic, at it's default size and be done
        // with it.
        NSSize size = self.class.newGraphicSize;
        DrawGraphic *graphic = [self graphicWithPoint:event.locationOnPageSnappedToGrid document:event.document page:event.page];
        [graphic setFrameSize:size];
        [event.page addGraphic:graphic toLayer:nil select:YES byExtendingSelection:NO];

        return YES;
    } else {
        // We don't actually want to create the graphic until the user drags
        // the mouse, so we'll wait for that. If anything else happens, we'll
        // abort and not create the new graphic.
        if (![self waitForMouseDrag:event]) {
            return NO;
        }

        // Just in case we had an old graphic.
        if (_graphic) {
            _graphic = nil;
        }

        _graphic = [self graphicWithPoint:event.locationOnPageSnappedToGrid document:event.document page:event.page];

        [[event page] addGraphic:_graphic select:YES byExtendingSelection:NO];

        [_graphic trackMouse:event];

        _graphic = nil;

        return YES;
    }
}

- (BOOL)mouseDragged:(DrawEvent *)event {
    return NO;
}

- (BOOL)mouseUp:(DrawEvent *)event {
    return NO;
}

- (BOOL)mouseMoved:(DrawEvent *)event {
    if (_newGraphicImage) {
        NSRect oldRect = _newGraphicRect;
        _newGraphicRect = (NSRect){event.locationOnPageSnappedToGrid, _newGraphicImage.size};
        _newGraphicRect.origin.x += _newGraphicOffset.x;
        _newGraphicRect.origin.y += _newGraphicOffset.y;
        if (!NSEqualRects(oldRect, _newGraphicRect)) {
            [event.page setNeedsDisplayInRect:oldRect];
            [event.page setNeedsDisplayInRect:_newGraphicRect];
        }
    }
    return NO;
}

- (void)_createOrUpdateNewGraphicImageIn:(DrawPage *)page display:(BOOL)needsDisplay {
    [page.document editWithoutUndoTracking:^{
        NSSize size = self.class.newGraphicSize;
        DrawGraphic *tempGraphic = [self graphicWithPoint:NSZeroPoint document:page.document page:page];
        [tempGraphic setFrameSize:size];
        [page addGraphic:tempGraphic];
        self->_newGraphicImage = [page.document imageForGraphicsArray:@[tempGraphic]];
        self->_newGraphicOffset = tempGraphic.dirtyBounds.origin;
        [page removeGraphic:tempGraphic];
    }];
    if (needsDisplay) {
        [_newGraphicPage setNeedsDisplayInRect:_newGraphicRect];
    }
}

- (void)_setupNewGraphicIn:(DrawPage *)page location:(NSPoint)where {
    [self _createOrUpdateNewGraphicImageIn:page display:NO];

    _newGraphicPage = page;
    _newGraphicRect = (NSRect){where, _newGraphicImage.size};
    _newGraphicRect.origin.x += _newGraphicOffset.x;
    _newGraphicRect.origin.y += _newGraphicOffset.y;
    __weak DrawTool *weakSelf = self;
    _newGraphicToken = [_newGraphicPage addGuestDrawer:^(DrawPage * _Nonnull page, NSRect dirtyRect) {
        DrawTool *strongSelf = weakSelf;
        if (strongSelf != nil) {
            [strongSelf->_newGraphicImage drawInRect:strongSelf->_newGraphicRect fromRect:(NSRect){NSZeroPoint, strongSelf->_newGraphicImage.size} operation:NSCompositingOperationSourceOver fraction:0.5 respectFlipped:YES hints:nil];
        }
    }];
    [_newGraphicPage setNeedsDisplayInRect:_newGraphicRect];
}

- (BOOL)mouseEntered:(DrawEvent *)event {
    //AJRPrintf(@"graphic: %@\n", self.class.addsViaDrag ? @"don't add" : @"add");

    if (!self.class.addsViaDrag && _newGraphicImage == nil) {
        [self _setupNewGraphicIn:event.page location:event.locationOnPageSnappedToGrid];
        return YES;
    }
    return NO;
}

- (BOOL)_removeTemporaryGraphic {
    if (_newGraphicImage != nil) {
        [_newGraphicPage removeGuestDrawer:_newGraphicToken];
        _newGraphicToken = nil;
        _newGraphicImage = nil;
        [_newGraphicPage setNeedsDisplayInRect:_newGraphicRect];
        _newGraphicRect = NSZeroRect;
        return YES;
    }
    return NO;
}

- (BOOL)mouseExited:(DrawEvent *)event {
    return [self _removeTemporaryGraphic];
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
    if (!self.class.addsViaDrag && _newGraphicImage == nil && document.page.mouseInPage) {
        NSPoint where = [NSEvent mouseLocation];
        DrawPage *page = document.page;
        NSWindow *window = page.window;

        where = [window convertPointFromScreen:where];
        where = [page convertPoint:where fromView:nil];
        where = [document snapPointToGrid:where];
        AJRPrintf(@"location: %P\n", where);
        [self _setupNewGraphicIn:document.page location:where];
    }
}

- (BOOL)toolShouldDeactivateForDocument:(DrawDocument *)document {
    return YES;
}

- (void)toolDidDeactivateForDocument:(DrawDocument *)document {
    [self _removeTemporaryGraphic];
    [[[document pagedView] enclosingScrollView] setDocumentCursor:nil];
}

- (DrawDocument *)activeDocument {
    return (DrawDocument *)[[NSApp keyWindow] delegate];
}

@end
