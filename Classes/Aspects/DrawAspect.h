/*
 DrawAspect.h
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

#import <Draw/DrawGraphic.h>

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>
#import <Draw/DrawGraphic.h>

NS_ASSUME_NONNULL_BEGIN

@interface DrawAspect : AJREditableObject <NSCopying, AJRXMLCoding>

#pragma mark - Factory

+ (void)registerAspect:(Class)aspect properties:(NSDictionary<NSString *, id> *)properties;
+ (NSArray<DrawAspect *> *)aspects;
+ (NSArray<NSString *> *)aspectIdentifiers;
+ (Class)aspectForIdentifier:(NSString *)identifier; 

@property (nonatomic,readonly,class) NSString *identifier;
@property (nonatomic,readonly,class) NSString *name;
@property (nonatomic,readonly,class,nullable) NSImage *image;
@property (nonatomic,readonly,class) DrawAspectPriority defaultPriority;
/// If `NO`, then the aspect will not archive. This is `YES` by default, but your custom aspect might not wish to archive. For example, a transient aspect, like warning badges.
@property (nonatomic,readonly,class) BOOL shouldArchive;

#pragma mark - Creation

+ (nullable DrawAspect *)defaultAspectForGraphic:(DrawGraphic *)graphic;

- (id)init NS_DESIGNATED_INITIALIZER;
- (id)initWithGraphic:(nullable DrawGraphic *)graphic NS_DESIGNATED_INITIALIZER;

#pragma mark - Properties

@property (nullable,nonatomic,weak) DrawGraphic *graphic;
@property (nonatomic,assign,getter=isActive) BOOL active;

#pragma mark - Drawing

/**
 This flag indicates that the aspect will actually cause pixels to be rendered on the canvas. Most aspects will return YES, in fact that's the default value, however some aspects will return NO if they on do something like affect the settings in the current context rather than creating pixels of their own. For example, the opacity aspect.
 
 This flag can be dynamic if, for example, the current combination of properties on an aspect would result in nothing being drawn, then this method should return NO. For example, a fill aspect that was entirely transparent could return NO.
 
 It's somewhat important that aspects correctly return YES or NO for this value, because it's used by the canvas to know when to draw a "ghost" image on the canvas. As such, if an aspect returned YES, when it didn't actually draw anything to the screen, then the user might not be able to find the image on the canvas, because nothing would be visible.
 */
@property (nonatomic,readonly) BOOL rendersToCanvas;

- (_Nullable DrawGraphicCompletionBlock)drawPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority;
- (AJRBezierPath *)renderPathForPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority;

- (BOOL)isPoint:(NSPoint)point inPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority;
- (BOOL)doesRect:(NSRect)rect intersectPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority;
@property (nonatomic,readonly) BOOL aspectAcceptsEdit;

@property (nonatomic,assign,readonly) AJRRectAdjustment boundsAdjustment;
- (NSRect)boundsForPath:(AJRBezierPath *)path;
/*!
 If `true`, this property denotes that the aspect causes the graphics bounds to be "expanded" beyond what you be expected. By default, this returns `false`, since the computation of the expanded bounds can be expensive.
 */
@property (nonatomic,assign,readonly) BOOL boundsExpandsGraphicBounds;
- (NSRect)boundsForGraphicBounds:(NSRect)graphicBounds;

#pragma mark - Life Cycle

- (void)willAddToDocument:(DrawDocument *)document;
- (void)didAddToDocument:(DrawDocument *)document;
- (void)willRemoveFromDocument:(DrawDocument *)document;
- (void)didRemoveFromDocument:(DrawDocument *)document;
- (void)willAddToPage:(DrawPage *)page;
- (void)didAddToPage:(DrawPage *)page;
- (void)willRemoveFromPage:(DrawPage *)page;
- (void)didRemoveFromPage:(DrawPage *)page;
- (void)willAddToGraphic:(DrawGraphic *)graphic;
- (void)didAddToGraphic:(DrawGraphic *)graphic;
- (void)willRemoveFromGraphic:(DrawGraphic *)graphic;
- (void)didRemoveFromGraphic:(DrawGraphic *)graphic;
- (void)graphicDidChangeShape:(DrawGraphic *)graphic;

#pragma mark - Editing

- (BOOL)beginEditingFromEvent:(DrawEvent *)event;
- (void)endEditing;

#pragma mark - Equality

- (BOOL)isEqualToAspect:(nullable DrawAspect *)aspect NS_SWIFT_NAME(isEqual(toAspect:));

@end

NS_ASSUME_NONNULL_END
