/*
DrawAspect.m
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

#import "DrawAspect.h"

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
    AJRLog(DrawPlugInLogDomain, AJRLogLevelDebug, @"Aspect: %C", aspect);
    [_aspects setObject:aspect forKey:properties[@"id"]];
}

+ (NSArray *)aspects {
    return [_aspects allValues];
}

+ (NSArray *)aspectIdentifiers {
    return [_aspects allKeys];
}

+ (Class)aspectForIdentifier:(NSString *)identifier {
    return [_aspects objectForKey:identifier];
}

+ (NSString *)identifier {
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

#pragma mark - Creation

+ (DrawAspect *)defaultAspectForGraphic:(DrawGraphic *)graphic {
    return nil;
}

- (id)initWithGraphic:(DrawGraphic *)aGraphic {
    if ((self = [super init])) {
        [self setGraphic:aGraphic];
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

- (BOOL)isEqualToAspect:(DrawAspect *)aspect {
    return (self.class == aspect.class
            //&& AJREqual(_graphic, aspect->_graphic) Can't be part of the comparison, otherwise we'll go into an infinite loop.
            && _active == aspect->_active);
}

- (BOOL)isEqual:(id)object {
    return self == object || ([object isKindOfClass:DrawAspect.class] && [self isEqualToAspect:object]);
}

#pragma mark - Notification

- (void)graphicWillAddToView:(DrawDocument *)view {
}

- (void)graphicDidAddToView:(DrawDocument *)aView {
}

- (void)graphicWillAddToPage:(DrawPage *)page {
}

- (void)graphicDidAddToPage:(DrawPage *)page {
}

- (void)graphicWillRemoveFromView:(DrawDocument *)aView {
}

- (void)graphicDidRemoveFromView:(DrawDocument *)aView {
}

- (void)graphicDidChangeShape:(DrawGraphic *)aGraphic {
}

- (BOOL)beginEditingFromEvent:(DrawEvent *)anEvent {
    return NO;
}

- (void)endEditing {
}

@end
