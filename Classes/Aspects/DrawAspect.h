/*
DrawAspect.h
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

#import <Draw/DrawGraphic.h>

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>
#import <Draw/DrawGraphic.h>

NS_ASSUME_NONNULL_BEGIN

@interface DrawAspect : NSObject <NSCopying, AJRXMLCoding>

#pragma mark - Factory

+ (void)registerAspect:(Class)aspect properties:(NSDictionary<NSString *, id> *)properties;
+ (NSArray<DrawAspect *> *)aspects;
+ (NSArray<NSString *> *)aspectIdentifiers;
+ (Class)aspectForIdentifier:(NSString *)identifier; 

@property (nonatomic,readonly,class) NSString *identifier;
@property (nonatomic,readonly,class) NSString *name;
@property (nonatomic,readonly,class) NSImage *image;
@property (nonatomic,readonly,class) DrawAspectPriority defaultPriority;

#pragma mark - Creation

+ (DrawAspect *)defaultAspectForGraphic:(DrawGraphic *)graphic;

- (id)initWithGraphic:(nullable DrawGraphic *)aGraphic;

#pragma mark - Properties

@property (nullable,nonatomic,weak) DrawGraphic *graphic;
@property (nonatomic,assign,getter=isActive) BOOL active;

#pragma mark - Drawing

- (_Nullable DrawGraphicCompletionBlock)drawPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority;
- (AJRBezierPath *)renderPathForPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority;

- (BOOL)isPoint:(NSPoint)point inPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority;
- (BOOL)doesRect:(NSRect)rect intersectPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority;
- (BOOL)aspectAcceptsEdit;

- (AJRRectAdjustment)boundsAdjustment;
- (NSRect)boundsForPath:(AJRBezierPath *)path;
- (BOOL)boundsExpandsGraphicBounds;
- (NSRect)boundsForGraphicBounds:(NSRect)graphicBounds;

- (void)graphicWillAddToView:(DrawDocument *)view;
- (void)graphicDidAddToView:(DrawDocument *)aView;
- (void)graphicWillAddToPage:(DrawPage *)page;
- (void)graphicDidAddToPage:(DrawPage *)page;
- (void)graphicWillRemoveFromView:(DrawDocument *)aView;
- (void)graphicDidRemoveFromView:(DrawDocument *)aView;
- (void)graphicDidChangeShape:(DrawGraphic *)aGraphic;

- (BOOL)beginEditingFromEvent:(DrawEvent *)anEvent;
- (void)endEditing;

#pragma mark - Equality

- (BOOL)isEqualToAspect:(DrawAspect *)aspect;

@end

NS_ASSUME_NONNULL_END
