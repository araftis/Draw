/*
 DrawAspect.m
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

#import "DrawAspect.h"

#import "DrawDocument.h"
#import "DrawGraphic.h"
#import "DrawLogging.h"

#import <AJRInterface/AJRInterface.h>

@implementation DrawAspect

static NSMutableDictionary  *_aspects = nil;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _aspects = [[NSMutableDictionary alloc] init];
    });
}

#pragma mark - Factory

+ (void)registerAspect:(Class)aspect properties:(NSDictionary<NSString *, id> *)properties {
    AJRLog(AJRLoggingDomainDrawPlugIn, AJRLogLevelDebug, @"Aspect: %C", aspect);
    [_aspects setObject:aspect forKey:properties[@"id"]];
}

+ (NSArray<DrawAspect *> *)aspects {
    return [_aspects allValues];
}

+ (NSArray<DrawAspectId> *)aspectIdentifiers {
    return [_aspects allKeys];
}

+ (Class)aspectForIdentifier:(DrawAspectId)identifier {
    return [_aspects objectForKey:identifier];
}

+ (DrawAspectId)identifier {
    return [[[AJRPlugInManager sharedPlugInManager] extensionPointForName:@"draw-aspect"] valueForProperty:@"id" onExtensionForClass:self.class];
}

+ (NSString *)name {
    return [[[AJRPlugInManager sharedPlugInManager] extensionPointForName:@"draw-aspect"] valueForProperty:@"name" onExtensionForClass:self.class];
}

+ (NSImage *)image {
    NSString *imageName = [[[AJRPlugInManager sharedPlugInManager] extensionPointForName:@"draw-aspect"] valueForProperty:@"image" onExtensionForClass:self.class];
    if (imageName == nil) {
        imageName = NSStringFromClass(self.class);
    }
    return [AJRImages imageNamed:imageName forClass:self.class];
}

+ (DrawAspectPriority)defaultPriority {
    return DrawAspectPriorityFromString([[[AJRPlugInManager sharedPlugInManager] extensionPointForName:@"draw-aspect"] valueForProperty:@"priority" onExtensionForClass:self.class]);
}

+ (BOOL)shouldArchive {
    return YES;
}

#pragma mark - Creation

+ (DrawAspect *)defaultAspectForGraphic:(DrawGraphic *)graphic {
    return nil;
}

- (id)init {
    return [super init];
}

- (id)initWithGraphic:(DrawGraphic *)graphic {
    if ((self = [super init])) {
        [self setGraphic:graphic];
        _active = YES;
    }
    return self;
}

#pragma mark - Properties

- (void)setActive:(BOOL)active {
    if ((active && !_active) || (!active && _active)) {
        _active = active;
        [_graphic updateBounds];
        [_graphic setNeedsDisplay];
    }
}

- (BOOL)rendersToCanvas {
    return YES;
}

#pragma mark - AJREditableObject

//+ (NSSet<NSString *> *)propertiesToIgnore {
//    NSMutableSet<NSString *> *ignore = [[super propertiesToIgnore] mutableCopy];
//    // We ignore this, because we basically want to only follow the parent -> child relationship, not the child -> parent relationship.
//    [ignore addObject:@"graphic"];
//    return ignore;
//}

#pragma mark - Drawing

- (DrawGraphicCompletionBlock)drawPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    return NULL;
}

- (AJRBezierPath *)renderPathForPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    return path;
}

#pragma mark - Hit Detection

- (BOOL)isPoint:(NSPoint)aPoint inPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    return NO;
}

- (BOOL)doesRect:(NSRect)rect intersectPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    return [[self renderPathForPath:path withPriority:priority] isHitByRect:rect];
}

- (BOOL)aspectAcceptsEdit {
    return NO;
}

- (AJRRectAdjustment)boundsAdjustment {
    return (AJRRectAdjustment){0.0, 0.0, 0.0, 0.0};
}

- (NSRect)boundsForPath:(AJRBezierPath *)path {
    return NSZeroRect;
}

- (BOOL)boundsExpandsGraphicBounds {
    return NO;
}

- (NSRect)boundsForGraphicBounds:(NSRect)graphicBounds {
    return graphicBounds;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    DrawAspect	*aspect = [self.class allocWithZone:nil];
    
    aspect->_graphic = _graphic;
    aspect->_active = _active;
    
    return aspect;
}

#pragma mark - AJRXMLCoding

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [coder decodeBoolForKey:@"active" setter:^(BOOL value) {
        self->_active = value;
    }];
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)encoder {
    [encoder encodeBool:_active forKey:@"active"];
}

- (BOOL)isEqual:(id)object {
    DrawAspect *other = AJRObjectIfKindOfClass(object, DrawAspect);
    if (other != nil) {
        return (self.class == other.class
                && _active == other->_active);
    }
    return NO;
}

#pragma mark - Life Cycle

+ (NSSet<NSString *> *)propertiesToObserve {
    return [super propertiesToObserve];
}

- (void)willAddToDocument:(DrawDocument *)document {
}

- (void)didAddToDocument:(DrawDocument *)document {
    [document addObjectToEditingContext:self];
}

- (void)willAddToPage:(DrawPage *)page {
}

- (void)didAddToPage:(DrawPage *)page {
}

- (void)willRemoveFromPage:(DrawPage *)page {
}

- (void)didRemoveFromPage:(DrawPage *)page {
}

- (void)willRemoveFromDocument:(DrawDocument *)document {
}

- (void)didRemoveFromDocument:(DrawDocument *)document {
    [document removeObjectFromEditingContext:self];
}

- (void)willAddToGraphic:(DrawGraphic *)graphic {
}

- (void)didAddToGraphic:(DrawGraphic *)graphic {
}

- (void)willRemoveFromGraphic:(DrawGraphic *)graphic {
}

- (void)didRemoveFromGraphic:(DrawGraphic *)graphic {
}

- (void)graphicDidChangeShape:(DrawGraphic *)graphic {
}

#pragma mark - Editing

- (BOOL)beginEditingFromEvent:(DrawEvent *)anEvent {
    return NO;
}

- (void)endEditing {
}

@end
