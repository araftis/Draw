/*
 DrawGraphic.h
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
#import <AJRInterface/AJRInterface.h>

#import <Draw/DrawFunctions.h>

NS_ASSUME_NONNULL_BEGIN

@class DrawAspect, DrawEvent, DrawFill, DrawGraphic, DrawInspectorModule, DrawLayer, DrawPage, DrawStroke, DrawColorFill, DrawShadow, DrawText, DrawDocument, DrawReflection, AJRBezierPath;

extern NSString *DrawGraphicDidInitNotification;
extern NSString *DrawGraphicDidChangeFrameNotification;
extern NSString *DrawFlatnessKey;

extern const AJRInspectorIdentifier AJRInspectorIdentifierGraphic;

typedef NS_OPTIONS(NSUInteger, DrawAutosizeMask) {
    DrawGraphicNotSizable = 0x00,
    DrawGraphicMinXMargin = 0x01,
    DrawGraphicWidthSizable = 0x02,
    DrawGraphicMaxXMargin = 0x04,
    DrawGraphicMinYMargin = 0x08,
    DrawGraphicHeightSizable = 0x10,
    DrawGraphicMaxYMargin = 0x20,
    DrawGraphicAllSizable = 0x3F,
};

typedef NS_ENUM(NSInteger, DrawHandleType) {
    DrawHandleTypeMissed = 0,
    DrawHandleTypeIndexed = 1,
    DrawHandleTypeTopLeft = 2,
    DrawHandleTypeTopCenter = 3,
    DrawHandleTypeTopRight = 4,
    DrawHandleTypeLeft = 5,
    DrawHandleTypeCenter = 6,
    DrawHandleTypeRight = 7,
    DrawHandleTypeBottomLeft = 8,
    DrawHandleTypeBottomCenter = 9,
    DrawHandleTypeBottomRight = 10
};

typedef struct {
    DrawHandleType type;    // The type of the handle.
	NSInteger elementIndex; // If type == DrawElementTypeIndexed, then the index of the handle hit.
	NSUInteger subindex;    // The subindex of the element hit. For example, a curve has three points, so elementIndex is the index of the curve, and subindex is c0, c1, or endPoint.
} DrawHandle;

extern const DrawHandle DrawHandleMissed;

typedef NS_ENUM(NSInteger, DrawAspectPriority) {
	DrawAspectPriorityFirst            = 0,
	DrawAspectPriorityBeforeBackground = 0,
	DrawAspectPriorityBackground       = 1,
	DrawAspectPriorityAfterBackground  = 2,
	DrawAspectPriorityBeforeChildren   = 3,
	DrawAspectPriorityChildren         = 4,
	DrawAspectPriorityAfterChildren    = 5,
	DrawAspectPriorityBeforeForeground = 6,
	DrawAspectPriorityForeground       = 7,
	DrawAspectPriorityAfterForeground  = 8,
	DrawAspectPriorityLast = DrawAspectPriorityAfterForeground,
};

typedef void (^DrawGraphicCompletionBlock)(void);
typedef BOOL (^DrawGraphicAspectFilter)(DrawAspect *aspect, DrawAspectPriority priority);

@interface DrawGraphic : AJREditableObject <NSCopying, AJRXMLCoding> {
    // The Path
    AJRBezierPath *_path;

    // Aspects
    NSMutableArray<NSMutableArray<DrawAspect *> *> *_aspects;

    // Handles...
    DrawHandle _handle;

    // Events
    NSUInteger _mouseDownFlags;

    // Related Graphics
    NSMutableSet *_relatedGraphics;

    // Subgraphics
    NSMutableArray *_subgraphics;
    DrawGraphic *_supergraphic; // Not retained!

    BOOL _autosizeSubgraphics;
    BOOL _boundsAreDirty;
    DrawAutosizeMask _autosizingMask;
}

#pragma mark - Debugging

+ (BOOL)showsDirtyBounds;
+ (void)setShowsDirtyBounds:(BOOL)flag;

#pragma mark - Handles

+ (NSImage *)handleImage;

#pragma mark - Notifications

+ (void)disableNotifications;
+ (void)enableNotifications;
+ (BOOL)notificationsAreDisabled;

#pragma mark - Creation

- (id)init NS_DESIGNATED_INITIALIZER;
- (id)initWithFrame:(NSRect)frame NS_DESIGNATED_INITIALIZER;

#pragma mark - Document, Pages, and Layers

@property (nonatomic,weak) DrawDocument *document;
@property (nonatomic,weak) DrawPage *page;
@property (nonatomic,weak) DrawLayer *layer;
@property (nonatomic,strong) AJRStore *variableStore;

#pragma mark - Frame

- (void)setFrameOrigin:(NSPoint)origin;
- (void)setFrameSize:(NSSize)size;
- (void)setFrameWithoutNotification:(NSRect)frame;
@property (nonatomic,assign) NSRect frame;
@property (nonatomic,assign) NSRect bounds;
@property (nonatomic,readonly) NSRect dirtyBounds;
@property (nonatomic,readonly) NSRect dirtyBoundsWithRelatedObjects;
@property (nonatomic,readonly) NSPoint centroid;
/// This is a convenience for graphics to check if they're currently printing.
@property (nonatomic,readonly) BOOL isPrinting;

@property (nonatomic,readonly) BOOL isTemplateGraphic;

#pragma mark - Handles

- (DrawHandle)setHandle:(DrawHandle)handle toLocation:(NSPoint)point;
- (NSPoint)locationOfHandle:(DrawHandle)handle;

#pragma mark - Drawing

@property (nonatomic,strong) AJRBezierPath *path;
/*! Normally returns NO, but graphics may return YES if the path is unique. For example, a circle or rectangle doesn't need to encode it's path, because the path is easily reconstructed, but a pen does, because the path is unique to each graphic. */
@property (nonatomic,readonly) BOOL shouldEncodePath;

- (void)drawHandleAtPoint:(NSPoint)point;
- (void)drawHandles;
- (BOOL)drawAspect:(DrawAspect *)aspect withPriority:(DrawAspectPriority)priority path:(AJRBezierPath *)path completionBlocks:(NSMutableArray *)drawingCompletionBlocks;
- (BOOL)drawAspectsWithPriority:(DrawAspectPriority)priority path:(AJRBezierPath *)path aspectFilter:(DrawGraphicAspectFilter)filter completionBlocks:(NSMutableArray *)drawingCompletionBlocks;
- (void)draw;
- (void)drawWithAspectFilter:(nullable DrawGraphicAspectFilter)filter;

- (void)setNeedsDisplay;

#pragma mark - Event Handling

- (BOOL)trackMouse:(DrawEvent *)event;
- (BOOL)trackMouse:(DrawEvent *)event fromHandle:(DrawHandle)handle;
- (BOOL)startTrackingAt:(NSPoint)startPoint;
- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint;
- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint;
- (NSInteger)mouseDownFlags;

// These two are special. They don't cause the document view to update. Generally, only call these on a temporary basis. Generally, this will be when you want to draw the view, minus a certain graphic, in preparation for redrawing that graphic in a new shape or location.
@property (nonatomic,assign) BOOL ignore;
@property (nonatomic,assign) BOOL editing;
- (BOOL)beginAspectEditingFromEvent:(DrawEvent *)event;
- (void)informAspectsOfShapeChange;
- (NSRect)boundsForAspect:(DrawAspect *)aspect withPriority:(DrawAspectPriority)priority;
/*! Not generally called by anything other than a draw graphic, but is provided as an override point for subclasses that need more complex bounds computations than the default. */
- (void)updateBounds;
/*! This method is generally called by subclasses or a graphic's aspects to denote that the graphic's bounds have likely changed. This updates both the bounds and dirtyBounds. */
- (void)noteBoundsAreDirty;

#pragma mark - Aspects

- (void)enumerateAspectsWithBlock:(void (^)(DrawAspect *aspect))block;

- (void)addAspect:(DrawAspect *)aspect;
- (void)addAspect:(DrawAspect *)aspect withPriority:(DrawAspectPriority)priority;
- (NSArray *)aspects;
- (NSArray *)aspectsForPriority:(DrawAspectPriority)priority;
- (nullable DrawAspect *)firstAspectOfType:(Class)aspectType withPriority:(DrawAspectPriority)priority;
- (nullable DrawAspect *)firstAspectOfType:(Class)aspectType withPriority:(DrawAspectPriority)priority create:(BOOL)flag;
- (NSArray *)prioritiesForAspect:(DrawAspect *)aspect;
- (void)removeAllAspects;
- (void)removeAspect:(DrawAspect *)aspect;
- (void)takeAspectsFromGraphic:(DrawGraphic *)otherGraphic;
- (BOOL)hasAspectOfType:(Class)aspectType;
- (BOOL)hasAspectOfType:(Class)aspectType withPriority:(DrawAspectPriority)priority;

- (NSGraphicsContext *)hitContext;

- (BOOL)isPoint:(NSPoint)point inHandleAt:(NSPoint)otherPoint;
- (DrawHandle)pathHandleForPoint:(NSPoint)point;
- (DrawHandle)pathHandleFromEvent:(DrawEvent *)event;
- (NSPoint)pointForHandle:(DrawHandle)handle;
- (DrawHandle)handleForPoint:(NSPoint)point;
- (BOOL)isHitByPoint:(NSPoint)point forAspectsWithPriority:(DrawAspectPriority)priority;
- (BOOL)isHitByRect:(NSRect)rect forAspectsWithPriority:(DrawAspectPriority)priority;
- (NSArray<DrawGraphic *> *)graphicsHitByPoint:(NSPoint)point;
- (NSArray<DrawGraphic *> *)graphicsHitByRect:(NSRect)rect;

- (DrawAspect *)primaryAspectOfType:(Class)aspectClass create:(BOOL)createFlag;

/*! Returns the object's primary stroke, creating it if it doesn't already exist. While graphics may have more than one stroke, all graphics have at least one stroke. It can be set to be inactive if you do not want it visible.*/
@property (nonatomic,readonly) DrawStroke *primaryStroke;
/*! Returns the object's primary fill, creating it if it doesn't already exist. While graphics may have more than one fill, all graphics have at least one fill. It can be set to be inactive if you do not want it visible.*/
@property (nonatomic,readonly) DrawFill *primaryFill;
/*! Returns the object's primary shadow, creating it if it doesn't already exist. While graphics may have more than one shadow, all graphics have at least one shadow. It can be set to be inactive if you do not want it visible.*/
@property (nonatomic,readonly) DrawShadow *primaryShadow;
/*! Returns the object's primary shadow, creating it if it doesn't already exist. While graphics may have more than one shadow, all graphics have at least one shadow. It can be set to be inactive if you do not want it visible.*/
@property (nonatomic,readonly) DrawReflection *primaryReflection;
/*! Returns the object's primary text aspect, creating it if it doesn't already exist. */
@property (nonatomic,readonly) DrawText *primaryText;

#pragma mark - Event Handling

- (void)moveHandle:(DrawHandle)handle byDelta:(NSPoint)delta;
- (void)moveFrameOriginByDelta:(NSPoint)delta;
- (BOOL)keyDown:(DrawEvent *)event;

#pragma mark - Notifications

- (void)graphicWillAddToDocument:(DrawDocument *)view;
- (void)graphicDidAddToDocument:(DrawDocument *)aView;
- (void)graphicWillAddToPage:(DrawPage *)view;
- (void)graphicDidAddToPage:(DrawPage *)aView;
- (void)graphicWillRemoveFromDocument:(DrawDocument *)aView;
- (void)graphicDidRemoveFromDocument:(DrawDocument *)aView;

#pragma mark - Links

@property (nonatomic,strong,readonly) NSSet<DrawGraphic *> *relatedGraphics;
- (void)addToRelatedGraphics:(DrawGraphic *)graphic;
- (void)removeFromRelatedGraphics:(DrawGraphic *)graphic;

- (NSPoint)intersectionWithLineEndingAtPoint:(NSPoint)point found:(BOOL *)found;

#pragma mark - Sheer randomness

@property (nonatomic,assign) NSUInteger seed;
- (void)resetRandomNumberSequence;
- (NSInteger)randomNumberInRange:(NSRange)range;

#pragma mark - Error

// This might seem a bit more like it belongs in stroke or fill, but it pretty much effects anything that works with the graphic's path. In reality, it's the amount of error allowed when mapping a bezier curve into line segments. For that reason, it's here.
@property (nonatomic,assign) CGFloat flatness;
@property (nonatomic,readonly) CGFloat error; // Used for determining hits...

#pragma mark - Equality

- (BOOL)isEqualToGraphic:(DrawGraphic *)other;

@end


@interface DrawGraphic (Subgraphics)

- (void)addSubgraphic:(DrawGraphic *)subgraphic;
- (void)addSubgraphic:(DrawGraphic *)subgraphic positioned:(NSWindowOrderingMode)place relativeTo:(DrawGraphic *)otherGraphic;
- (void)replaceSubgraphic:(DrawGraphic *)oldGraphic with:(DrawGraphic *)newGraphic;

- (NSArray *)subgraphics;

- (DrawGraphic *)ancestorSharedWithView:(DrawGraphic *)subgraphic;
- (BOOL)isDescendantOf:(nullable DrawGraphic *)subgraphic;

- (nullable DrawGraphic *)supergraphic;
- (void)removeFromSupergraphic;

- (void)sortSubgraphicsUsingFunction:(NSInteger (*)(id, id, void *))compare context:(void *)context;

- (void)sizeToFit;

- (void)graphicWillMoveToSupergraphic:(DrawGraphic *)newSupergraphic;

- (void)setAutosizeSubgraphics:(BOOL)flag;
- (BOOL)autosizeSubgraphics;
- (void)setAutoresizingMask:(DrawAutosizeMask)mask;
- (DrawAutosizeMask)autoresizingMask;

- (void)addClip;

@end

extern DrawHandle DrawHandleMake(DrawHandleType type, NSInteger elementIndex, NSInteger index);
extern BOOL DrawHandleEqual(DrawHandle handle1, DrawHandle handle2);
extern NSString *DrawStringFromHandle(DrawHandle handle);
extern DrawHandle DrawHandleFromString(NSString *string);
extern NSString *DrawStringFromDrawHandleType(DrawHandleType type);
extern DrawHandleType DrawHandleTypeFromString(NSString *string);
extern BOOL DrawHandleIsBase(DrawHandle handle);
extern NSString *DrawStringFromDrawAspectPriority(DrawAspectPriority priority);
extern DrawAspectPriority DrawAspectPriorityFromString(NSString *string);

#define DrawHandleSetIndex(handle, index, si) \
    handle.type == DrawHandleTypeIndexed; \
    handle.elementIndex = (index); \
    handle.subindex = (si);

NS_ASSUME_NONNULL_END
