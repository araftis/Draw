/*
 DrawTool.h
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

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DrawPage, DrawDocument, DrawEvent, DrawGraphic, DrawToolAction, DrawToolSet;

extern NSString *DrawToolDidBecomeActiveNotification;

@interface DrawTool : NSObject 

#pragma mark - Factory

@property (nonatomic,class,readonly) NSString *identifier;
@property (nonatomic,class,readonly) NSString *name;
@property (nonatomic,class,readonly) BOOL addsViaDrag;
@property (nonatomic,class,readonly) NSSize newGraphicSize;
@property (nonatomic,readonly) NSArray<DrawToolAction *> *createActions;

#pragma mark - Creation

- (id)initWithToolSet:(DrawToolSet *)toolSet NS_DESIGNATED_INITIALIZER;

#pragma mark - Properties

@property (nonatomic,readonly,readonly) NSArray<DrawToolSet *> *toolSets;
@property (nonatomic,readonly) NSString *identifier;
@property (nonatomic,readonly) NSString *name;
@property (nonatomic,readonly,strong) NSArray<DrawToolAction *> *actions;
@property (nonatomic,strong) DrawToolAction *currentAction;
@property (nonatomic,readonly) CGFloat displayPriority;
@property (nullable,nonatomic,strong) DrawGraphic *graphic;

@property (nonatomic,readonly) NSString *activationKey;

@property (nonatomic,readonly) NSCursor *cursor;

#pragma mark - Aliasing

/*!
 @discussion Normally a tool only belongs to one tool set, but tool sets can alias to a tool in another tool set. When that happens, the tool will belong to more than one tool set. You add that additional tool set by calling this method. Normally, this is called by using the "alias" property in the ajrplugindata for the aliasing tool.
 
 @param additionalToolSet The additional tool set that will display the tool.
 */
- (void)addAliasedToolSet:(DrawToolSet *)additionalToolSet;

/*!
 @discussion Checks to see if the receiver is used by toolSet.
 
 @param toolSet The tool set to check membership in.
 
 @return YES if the tool is used by toolSet, otherwise, NO.
 */
- (BOOL)isUsedByToolSet:(DrawToolSet *)toolSet;

/*!
 The primary tool set. Generally, this is the first toolset to instantiate the tool.
 */
@property (nonatomic,readonly) DrawToolSet *primaryToolSet;

#pragma mark - Creation

- (DrawGraphic *)graphicWithPoint:(NSPoint)point document:(DrawDocument *)document page:(DrawPage *)page;

#pragma mark - Event Handling

- (BOOL)waitForMouseDrag:(DrawEvent *)event;

- (BOOL)mouseDown:(DrawEvent *)event;
- (BOOL)mouseDragged:(DrawEvent *)event;
- (BOOL)mouseUp:(DrawEvent *)event;
- (BOOL)mouseMoved:(DrawEvent *)event;
- (BOOL)mouseEntered:(DrawEvent *)event;
- (BOOL)mouseExited:(DrawEvent *)event;
- (BOOL)rightMouseDown:(DrawEvent *)event;
- (BOOL)rightMouseDragged:(DrawEvent *)event;
- (BOOL)rightMouseUp:(DrawEvent *)event;
- (BOOL)keyDown:(DrawEvent *)event;
- (BOOL)keyUp:(DrawEvent *)event;
- (BOOL)flagsChanged:(DrawEvent *)event;
- (BOOL)helpRequested:(DrawEvent *)event;
- (nullable NSMenu *)menuForEvent:(DrawEvent *)event;

#pragma mark - Activation

- (BOOL)toolShouldActivateForDocument:(DrawDocument *)document;
- (void)toolDidActivateForDocument:(DrawDocument *)document;
- (BOOL)toolShouldDeactivateForDocument:(DrawDocument *)document;
- (void)toolDidDeactivateForDocument:(DrawDocument *)document;

- (DrawDocument *)activeDocument;

#pragma mark - Icon

/*!
 @discussion Represents the icon to display in the tool bar. This only displays the "current" icon, and is generally used when the tool's action doesn't have an icon. This may return nil to indicate that only the action's icon be used. The default is to return nil. The returned icon should be 25x25 points and have 1x and 2x representations.

 @return An image to display for the tools.
 */
@property (nonatomic,readonly,nullable) NSImage *icon;

@end

@interface DrawTool (DragAndDrop)

// Drag and Drop
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender inView:(DrawPage *)drawView;
- (NSUInteger)draggingEntered:(id <NSDraggingInfo>)sender inView:(DrawPage *)drawView;
- (void)draggingExited:(id <NSDraggingInfo>)sender inView:(DrawPage *)drawView;
- (NSUInteger)draggingUpdated:(id <NSDraggingInfo>)sender inView:(DrawPage *)drawView;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender inView:(DrawPage *)drawView;
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender inView:(DrawPage *)drawView;

@end

NS_ASSUME_NONNULL_END
