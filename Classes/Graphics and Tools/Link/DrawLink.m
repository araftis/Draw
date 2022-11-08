/*
 DrawLink.m
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

#import "DrawLink.h"

#import "DrawEvent.h"
#import "DrawLayer.h"
#import "DrawLinkCap.h"
#import "DrawLinkCapArrow.h"
#import "DrawLinkTool.h"
#import "DrawPage.h"
#import "DrawPenBezierAspect.h"
#import "DrawDocument.h"
#import "AJRXMLCoder-DrawExtensions.h"
#import <Draw/Draw-Swift.h>

#import <AJRFoundation/AJRFoundation.h>
#import <AJRInterface/AJRInterface.h>

const AJRInspectorIdentifier AJRInspectorIdentifierLink = @"link";

@interface DrawLinkInspectorChoice : NSObject <AJRInspectorChoiceTitleProvider>

@property (nonatomic,strong) Class linkCapClass;
@property (nullable,nonatomic,strong) NSString *title;
@property (nullable,nonatomic,strong) NSImage *image;
@property (nonatomic,assign) BOOL filled;

+ (DrawLinkInspectorChoice *)choiceWithLabel:(NSString *)label;
+ (DrawLinkInspectorChoice *)choiceWithClass:(Class)linkClass source:(BOOL)source filled:(BOOL)filled;

@end

@implementation DrawLinkInspectorChoice

+ (DrawLinkInspectorChoice *)choiceWithLabel:(NSString *)label {
    DrawLinkInspectorChoice *choice = [[DrawLinkInspectorChoice alloc] init];
    choice.title = label;
    return choice;
}

+ (DrawLinkInspectorChoice *)choiceWithClass:(Class)linkCapClass source:(BOOL)source filled:(BOOL)filled {
    DrawLinkInspectorChoice *choice = [[DrawLinkInspectorChoice alloc] init];
    choice.linkCapClass = linkCapClass;
    choice.filled = filled;
    choice.image = source ? [linkCapClass sourceImageFilled:filled] : [linkCapClass destinationImageFilled:filled];
    return choice;
}

- (NSString *)titleForInspector {
    return _title;
}

- (NSImage *)imageForInspector {
    return _image;
}

@end

@implementation DrawLink {
    NSPoint _sourceAttachmentPoint; // Where we want to be attached. Either one of source's handles or source's centroid.
    NSPoint _destinationAttachmentPoint;
}

- (id)init {
    if ((self = [super init])) {
        _sourceHandle = DrawHandleMake(DrawHandleTypeMissed, 0, 0);
        _destinationHandle = DrawHandleMake(DrawHandleTypeMissed, 0, 0);
    }
    return self;
}

- (id)initWithSource:(DrawGraphic *)sourceGraphic {
    NSPoint centroid = [sourceGraphic centroid];
    DrawStroke *stroke;
    DrawColorFill *fill;

    if ((self = [super initWithFrame:(NSRect){centroid, {0.0, 0.0}}])) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        Class headClass;
        Class tailClass;
        DrawLinkCap *headCap = nil;
        DrawLinkCap *tailCap = nil;

        [self setSource:sourceGraphic];
        [super setClosed:NO];

        _sourceHandle = DrawHandleMake(DrawHandleTypeMissed, 0, 0);
        _sourcePoint = centroid;
        _sourceAttachmentPoint = centroid;
        _destinationHandle = DrawHandleMake(DrawHandleTypeMissed, 0, 0);
        _destinationPoint = centroid;
        _destinationAttachmentPoint = centroid;

        stroke = [[DrawStroke alloc] initWithGraphic:self];
        [self addAspect:stroke withPriority:DrawAspectPriorityForeground];
        fill = [[DrawColorFill alloc] initWithGraphic:self];
        [fill setColor:[NSColor blackColor]];
        [self addAspect:fill withPriority:DrawAspectPriorityBackground];

        headClass = [userDefaults classForKey:DrawLinkCapHeadStyleKey defaultValue:nil];
        tailClass = [userDefaults classForKey:DrawLinkCapTailStyleKey defaultValue:[DrawLinkCapArrow class]];
        headCap = [[headClass alloc] initWithType:DrawLinkCapTypeHead];
        tailCap = [[tailClass alloc] initWithType:DrawLinkCapTypeTail];

        [self setSourceCap:headCap];
        [self setDestinationCap:tailCap];
    }

    return self;
}

- (void)setClosed:(BOOL)flag {
    // Overridden, because we don't ever want to be closed.
}

- (NSRect)boundsForAspect:(DrawAspect *)aspect withPriority:(DrawAspectPriority)priority {
    NSRect bounds = [super boundsForAspect:aspect withPriority:priority];
    if (_sourceCap) {
        bounds = NSUnionRect(bounds, [aspect boundsForPath:[_sourceCap path]]);
    }
    if (_destinationCap) {
        bounds = NSUnionRect(bounds, [aspect boundsForPath:[_destinationCap path]]);
    }
    return bounds;
}

- (BOOL)drawAspect:(DrawAspect *)aspect withPriority:(DrawAspectPriority)priority path:(AJRBezierPath *)inputPath completionBlocks:(NSMutableArray *)drawingCompletionBlocks; {
    BOOL didDraw = NO;
    DrawGraphicCompletionBlock completionBlock = NULL;
    BOOL isFilling = [aspect isKindOfClass:[DrawFill class]];

    if (![aspect isKindOfClass:[DrawPenBezierAspect class]]) {
        AJRBezierPath *path = [[AJRBezierPath alloc] init];

        if (_sourceCap && (!isFilling || [_sourceCap filled])) {
            [path appendBezierPath:[_sourceCap path]];
            didDraw = YES;
        }
        if (!isFilling) {
            [path appendBezierPath:inputPath];
            didDraw = YES;
        }
        if (_destinationCap && (!isFilling || [_destinationCap filled])) {
            [path appendBezierPath:[_destinationCap path]];
            didDraw = YES;
        }

        completionBlock = [aspect drawPath:path withPriority:DrawAspectPriorityBackground];
        if (completionBlock) {
            [drawingCompletionBlocks addObject:completionBlock];
        }
    }

    return didDraw;
}

- (void)updateSourcePoint {
    if (_source) {
        if (_sourceHandle.type != DrawHandleTypeIndexed) {
            _sourceAttachmentPoint = [_source centroid];
            if ([_path elementCount] >= 2) {
                if (_source) {
                    NSPoint endPoint;
                    NSPoint intersection;
                    BOOL found;

                    if (_destination && [self isLine]) {
                        endPoint = _destinationAttachmentPoint;
                    } else {
                        endPoint = [_path pointAtIndex:1];
                    }
                    intersection = [_source intersectionWithLineEndingAtPoint:endPoint found:&found];
                    if (found) {
                        [self setSourcePoint:intersection];
                    } else {
                        [self setSourcePoint:[_source centroid]];
                    }
                }
            } else {
                [self setSourcePoint:[_source centroid]];
            }
        } else if (_sourceHandle.type == DrawHandleTypeIndexed) {
            _sourceAttachmentPoint = [_source pointForHandle:_sourceHandle];
            [self setSourcePoint:_sourceAttachmentPoint];
        }
    } else {
        _sourceAttachmentPoint = [_path pointAtIndex:0];
        [self setSourcePoint:_sourceAttachmentPoint];
    }
}

- (void)updateDestinationPoint {
    if (_destination) {
        if (_destinationHandle.type != DrawHandleTypeIndexed) {
            NSInteger pointCount = [_path pointCount];

            _destinationAttachmentPoint = [_destination centroid];
            if (pointCount > 1) {
                if (_source) {
                    NSPoint endPoint;
                    NSPoint intersection;
                    BOOL found;

                    if (_source && [self isLine]) {
                        endPoint = _sourceAttachmentPoint;
                    } else {
                        endPoint = [_path pointAtIndex:[_path pointIndexForPathElementIndex:pointCount - 2]];
                    }
                    intersection = [_destination intersectionWithLineEndingAtPoint:endPoint found:&found];
                    if (found) {
                        [self setDestinationPoint:intersection];
                    } else {
                        [self setDestinationPoint:[_destination centroid]];
                    }
                }
            } else {
                [self setDestinationPoint:[_destination centroid]];
            }
        } else if (_destinationHandle.type == DrawHandleTypeIndexed) {
            _destinationAttachmentPoint = [_destination pointForHandle:_destinationHandle];
            [self setDestinationPoint:_destinationAttachmentPoint];
        }
    } else {
        _destinationAttachmentPoint = [_path pointAtIndex:[_path pointCount] - 1];
        [self setDestinationPoint:_destinationAttachmentPoint];
    }
}

- (void)setSource:(DrawGraphic *)source withHandle:(DrawHandle)handle {
    if (_source != source) {
        if (_source) {
            [_source removeFromRelatedGraphics:self];
        }
        _source = source;
        _sourceHandle = handle;
        if (_source) {
            [_source addToRelatedGraphics:self];
        }
        [self updateSourcePoint];
    } else if (!DrawHandleEqual(_sourceHandle, handle)) {
        _sourceHandle = handle;
        [self updateSourcePoint];
    }
}

- (void)setSource:(DrawGraphic *)source {
    [self setSource:source withHandle:_sourceHandle];
}

- (void)setSourcePoint:(NSPoint)where {
    if (_sourceCap) {
        [_path setPointAtIndex:0 toPoint:[_sourceCap initialPointFromPoint:where]];
    } else {
        [_path setPointAtIndex:0 toPoint:where];
    }
    _sourcePoint = where;

    if (_sourceCap) [_sourceCap update];
    if (_destinationCap) [_destinationCap update];

    [self updateBounds];
    [self setNeedsDisplay];
}

- (NSPoint)adjustedSourcePoint {
    return [_path pointAtIndex:0];
}

- (void)setSourceHandle:(DrawHandle)aHandle {
    [self setSource:_source withHandle:aHandle];
}

- (void)setDestination:(DrawGraphic *)aDestination {
    [self setDestination:aDestination withHandle:_destinationHandle];
}

- (void)setDestination:(DrawGraphic *)destination withHandle:(DrawHandle)aHandle; {
    if (_destination != destination) {
        if (_destination) {
            [_destination removeFromRelatedGraphics:self];
        }
        _destination = destination;
        _destinationHandle = aHandle;
        if (_destination) {
            [_destination addToRelatedGraphics:self];
        }
        [self updateDestinationPoint];
    } else if (!DrawHandleEqual(_destinationHandle, aHandle)) {
        _destinationHandle = aHandle;
        [self updateDestinationPoint];
    }
}

- (void)setDestinationPoint:(NSPoint)where {
    _destinationPoint = where;
    if (_destinationCap) {
        [_path setPointAtIndex:[_path elementCount] - 1 toPoint:[_destinationCap initialPointFromPoint:_destinationPoint]];
    } else {
        [_path setPointAtIndex:[_path elementCount] - 1 toPoint:where];
    }
    if (_sourceCap) {
        [_sourceCap update];
    }
    if (_destinationCap) {
        [_destinationCap update];
    }
    [self updateBounds];
    [self setNeedsDisplay];
}

- (NSPoint)adjustedDestinationPoint {
    return [_path pointAtIndex:[_path pointIndexForPathElementIndex:[_path elementCount] - 1]];
}

- (void)setDestinationHandle:(DrawHandle)aHandle {
    [self setDestination:_destination withHandle:aHandle];
}

- (void)setSourceCap:(DrawLinkCap *)aHeadCap {
    if (_sourceCap != aHeadCap) {
        [self.document registerUndoWithTarget:self selector:@selector(setSourceCap:) object:_sourceCap];

        if (_sourceCap) {
            DrawLinkCap *save = _sourceCap;
            [_sourceCap linkCapWillRemoveFromLink:self];
            _sourceCap = nil;
            [save linkCapDidRemoveFromLink:self];
        }

        [aHeadCap linkCapWillAddToLink:self asType:DrawLinkCapTypeHead];
        _sourceCap = aHeadCap;
        [aHeadCap linkCapDidAddToLink:self asType:DrawLinkCapTypeHead];

        [self updateSourcePoint];
    }
}

- (void)setDestinationCap:(DrawLinkCap *)aTailCap {
    if (_destinationCap != aTailCap) {
        [self.document registerUndoWithTarget:self selector:@selector(setDestinationCap:) object:_destinationCap];

        if (_destinationCap) {
            id		save = _destinationCap;
            [_destinationCap linkCapWillRemoveFromLink:self];
            _destinationCap = nil;
            [save linkCapDidRemoveFromLink:self];
        }

        [aTailCap linkCapWillAddToLink:self asType:DrawLinkCapTypeTail];
        _destinationCap = aTailCap;
        [_destinationCap linkCapDidAddToLink:self asType:DrawLinkCapTypeTail];

        [self updateDestinationPoint];
    }
}

- (DrawGraphic *)topGraphicAtPoint:(NSPoint)point exclude:(DrawGraphic *)exclusionGraphic {
    NSArray *layers = [self.document layers];
    NSInteger x, y;
    DrawLayer *aLayer;
    NSArray *graphics;
    DrawGraphic *aGraphic;

    for (x = [layers count] - 1; x >= 0; x--) {
        aLayer = [layers objectAtIndex:x];
        if (![aLayer locked] && [aLayer visible]) {
            graphics = [self.page graphicsForLayer:aLayer];
            for (y = [graphics count] - 1; y >= 0; y--) {
                aGraphic = [graphics objectAtIndex:y];
                if ((aGraphic != self) && (aGraphic != exclusionGraphic)) {
                    if (NSPointInRect(point, [aGraphic bounds])) {
                        return [[aGraphic graphicsHitByPoint:point] lastObject];
                    }
                }
            }
        }
    }
    return nil;
}

- (void)_setSourcePoint:(NSPoint)point {
    DrawGraphic *hit = [self topGraphicAtPoint:point exclude:_destination];

    if (hit) {
        if ([hit isKindOfClass:[DrawLink class]]) {
            DrawHandle aHandle = [hit pathHandleForPoint:point];

            if (aHandle.type == DrawHandleTypeMissed) {
                [self setSource:nil];
                [self setSourcePoint:[self.document snapPointToGrid:point]];
            } else {
                [self setSource:hit withHandle:aHandle];
            }
            if ([self isLine]) {
                [self updateDestinationPoint];
            }
        } else {
            [self setSource:hit withHandle:[hit pathHandleForPoint:point]];
            if ([self isLine]) {
                [self updateDestinationPoint];
            }
        }
    } else {
        [self setSource:nil];
        [self setSourcePoint:[self.document snapPointToGrid:point]];
    }
}

- (void)_setDestinationPoint:(NSPoint)point {
    DrawGraphic *hit = [self topGraphicAtPoint:point exclude:_source];

    if (hit) {
        if ([hit isKindOfClass:[DrawLink class]]) {
            DrawHandle aHandle = [hit pathHandleForPoint:point];

            if (aHandle.type == DrawHandleTypeMissed) {
                [self setDestination:nil];
                [self setDestinationPoint:[self.document snapPointToGrid:point]];
            } else {
                [self setDestination:hit withHandle:aHandle];
            }
            if ([self isLine]) {
                [self updateSourcePoint];
            }
        } else {
            [self setDestination:hit withHandle:[hit pathHandleForPoint:point]];
            if ([self isLine]) {
                [self updateSourcePoint];
            }
        }
    } else {
        [self setDestination:nil];
        _destinationAttachmentPoint = [self.document snapPointToGrid:point];
        [self setDestinationPoint:_destinationAttachmentPoint];
        [self updateSourcePoint];
    }
}

- (BOOL)trackMouse:(DrawEvent *)event fromHandle:(DrawHandle)aHandle {
    [super trackMouse:event fromHandle:aHandle];

    if (_destination) {
        self.creating = NO;
        return YES;
    }

    return NO;
}

- (DrawHandle)handleForPoint:(NSPoint)point {
    return [self initializePositionForHandle:[self pathHandleForPoint:point]];
}

- (DrawHandle)setHandle:(DrawHandle)handle toLocation:(NSPoint)point {
    if (handle.type == DrawHandleTypeIndexed) {
        if (self.creating) {
            if (handle.elementIndex == [_path elementCount]) {
                [self appendLineToPoint:point];
            }
            [self _setDestinationPoint:point];
        } else {
            NSInteger lastHandle = [_path lastDrawingElementIndex];

            if (handle.elementIndex == 0) {
                [self _setSourcePoint:point];
            } else if (handle.elementIndex == lastHandle) {
                [self _setDestinationPoint:point];
            } else {
                DrawHandle	response = [super setHandle:handle toLocation:point];
                if (handle.elementIndex == 1) {
                    [self updateSourcePoint];
                }
                if (handle.elementIndex == lastHandle - 1) {
                    [self updateDestinationPoint];
                }
                return response;
            }
        }

        [self updateBounds];
        [self setNeedsDisplay];
    }

    return handle;
}

- (void)removeAspect:(DrawAspect *)aspect {
    // Refuse to allow the removal of our "stroke".
    if ([aspect isKindOfClass:[DrawStroke class]]) {
        return;
    }
    [super removeAspect:aspect];
}

- (void)setEditing:(BOOL)flag {
    [super setEditing:YES];
}

- (CGFloat)angleInDegreesOfSourceSegment {
    NSPoint endPoint;

    if (_destination && [self isLine]) {
        endPoint = _destinationAttachmentPoint;
    } else if ([_path elementCount] == 1) {
        endPoint = [_path pointAtIndex:0];
    } else {
        endPoint = [_path pointAtIndex:1];
    }

    if (NSEqualPoints(_sourceAttachmentPoint, endPoint)) {
        return 0.0;
    }
    return AJRArctan(endPoint.y - _sourceAttachmentPoint.y, endPoint.x - _sourceAttachmentPoint.x);
}

- (CGFloat)angleInDegreesOfDestinationSegment {
    CGFloat angle = 0.0;
    NSPoint endPoint;

    if (_source && [self isLine]) {
        endPoint = _sourceAttachmentPoint;
    } else {
        endPoint = [_path pointAtIndex:[_path pointCount] - 2];
    }

    if (!NSEqualPoints(_destinationAttachmentPoint, endPoint)) {
        angle = AJRArctan(_destinationAttachmentPoint.y - endPoint.y, _destinationAttachmentPoint.x - endPoint.x);
    }

    return angle;
}

#pragma mark - DrawGraphic

- (void)graphicDidRemoveFromDocument:(DrawDocument *)document {
    [super graphicDidRemoveFromDocument:document];

    // Since we've been removed from the document, we need to disconnect from our source and destination.
    [_source removeFromRelatedGraphics:self];
    _source = nil;
    [_destination removeFromRelatedGraphics:self];
    _destination = nil;
}

- (void)graphicDidChangeShape:(DrawGraphic *)aGraphic {
    if (aGraphic == _source) {
        [self updateSourcePoint];
        if ([self isLine]) {
            [self updateDestinationPoint];
        }
    } else if (aGraphic == _destination) {
        [self updateDestinationPoint];
        if ([self isLine]) {
            [self updateSourcePoint];
        }
    }
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)aZone {
    DrawLink *new = nil;

    if ((new = [super copyWithZone:aZone])) {
        new->_source = [_source copyWithZone:aZone];
        new->_destination = [_destination copyWithZone:aZone];
        new->_sourceHandle = _sourceHandle;
        new->_destinationHandle = _destinationHandle;
        new->_sourcePoint = _sourcePoint;
        new->_sourceCap = [_sourceCap copyWithZone:aZone];
        new->_destinationPoint = _destinationPoint;
        new->_destinationCap = [_destinationCap copyWithZone:aZone];
        new->_sourceAttachmentPoint = _sourceAttachmentPoint;
        new->_destinationAttachmentPoint = _destinationAttachmentPoint;
    }
    return new;
}

#pragma mark - AJRXMLArchiving

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super decodeWithXMLCoder:coder];

    [coder decodeObjectForKey:@"source" setter:^(id  _Nonnull object) {
        self->_source = object;
    }];
    [coder decodeDrawHandleForKey:@"sourceHandle" setter:^(DrawHandle handle) {
        self->_sourceHandle = handle;
    }];
    [coder decodePointForKey:@"sourcePoint" setter:^(CGPoint point) {
        self->_sourcePoint = point;
    }];
    [coder decodePointForKey:@"sourceAttachmentPoint" setter:^(CGPoint point) {
        self->_sourceAttachmentPoint = point;
    }];
    [coder decodeObjectForKey:@"sourceCap" setter:^(id  _Nonnull object) {
        self->_sourceCap = object;
    }];
    [coder decodeObjectForKey:@"destination" setter:^(id  _Nonnull object) {
        self->_destination = object;
    }];
    [coder decodeDrawHandleForKey:@"destinationHandle" setter:^(DrawHandle handle) {
        self->_destinationHandle = handle;
    }];
    [coder decodePointForKey:@"destinationPoint" setter:^(CGPoint point) {
        self->_destinationPoint = point;
    }];
    [coder decodePointForKey:@"destinationAttachmentPoint" setter:^(CGPoint point) {
        self->_destinationAttachmentPoint = point;
    }];
    [coder decodeObjectForKey:@"destinationCap" setter:^(id  _Nonnull object) {
        self->_destinationCap = object;
    }];
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super encodeWithXMLCoder:coder];

    [coder encodeObjectReference:_source forKey:@"source"];
    [coder encodeObjectReference:_destination forKey:@"destination"];
    [coder encodeDrawHandle:_sourceHandle forKey:@"sourceHandle"];
    [coder encodeDrawHandle:_destinationHandle forKey:@"destinationHandle"];
    [coder encodePoint:_sourcePoint forKey:@"sourcePoint"];
    [coder encodePoint:_sourceAttachmentPoint forKey:@"sourceAttachmentPoint"];
    [coder encodeObject:_sourceCap forKey:@"sourceCap"];
    [coder encodePoint:_destinationPoint forKey:@"destinationPoint"];
    [coder encodePoint:_destinationAttachmentPoint forKey:@"destinationAttachmentPoint"];
    [coder encodeObject:_destinationCap forKey:@"destinationCap"];
}

- (id)finalizeXMLDecodingWithError:(NSError * _Nullable __autoreleasing *)error {
    if ([super finalizeXMLDecodingWithError:error]) {
        [_sourceCap update];
        [_destinationCap update];
    }
    return self;
}

+ (NSString *)ajr_nameForXMLArchiving {
    return @"link";
}

- (BOOL)isEqualToLink:(DrawLink *)other {
    return (self.class == other.class
            && AJREqual(_source, other->_source)
            && AJREqual(_destination, other->_destination)
            && DrawHandleEqual(_sourceHandle, other->_sourceHandle)
            && DrawHandleEqual(_destinationHandle, other->_destinationHandle)
            && NSEqualPoints(_sourcePoint, other->_sourcePoint)
            && NSEqualPoints(_sourceAttachmentPoint, other->_sourceAttachmentPoint)
            && AJREqual(_sourceCap, other->_sourceCap)
            && _sourceCap.link == self
            && NSEqualPoints(_destinationPoint, other->_destinationPoint)
            && NSEqualPoints(_destinationAttachmentPoint, other->_destinationAttachmentPoint)
            && AJREqual(_destinationCap, other->_destinationCap)
            && _destinationCap.link == self);
}

- (BOOL)isEqual:(id)other {
    return self == other || ([other isKindOfClass:DrawLink.class] && [self isEqualToLink:other]);
}

#pragma mark - Inspectors

- (NSArray<AJRInspectorIdentifier> *)inspectorIdentifiers {
    NSMutableArray<AJRInspectorIdentifier> *identifiers = [[super inspectorIdentifiers] mutableCopy];
    [identifiers addObject:AJRInspectorIdentifierLink];
    [identifiers removeObjectIdenticalTo:AJRInspectorIdentifierPen];
    return identifiers;
}

+ (NSArray<DrawLinkInspectorChoice *> *)allPossibleSourceCaps {
    static NSMutableArray<DrawLinkInspectorChoice *> *linkCaps = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        linkCaps = [NSMutableArray array];
        [linkCaps addObject:[DrawLinkInspectorChoice choiceWithLabel:@"None"]];
        for (Class linkCapClass in DrawLinkTool.linkCaps) {
            [linkCaps addObject:[DrawLinkInspectorChoice choiceWithClass:linkCapClass source:YES filled:YES]];
            [linkCaps addObject:[DrawLinkInspectorChoice choiceWithClass:linkCapClass source:YES filled:NO]];
        }
    });

    return linkCaps;
}

- (NSArray<DrawLinkInspectorChoice *> *)allPossibleSourceCaps {
    return [[self class] allPossibleSourceCaps];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingInspectedSourceCap {
    return [NSSet setWithObjects:@"sourceCap", @"sourceCap.filled", nil];
}

- (DrawLinkInspectorChoice *)inspectedSourceCap {
    NSArray<DrawLinkInspectorChoice *> *sourceCaps = [[self class] allPossibleSourceCaps];

    if (_sourceCap == nil) {
        // The "none" option.
        return sourceCaps[0];
    }

    DrawLinkInspectorChoice *found = nil;
    for (DrawLinkInspectorChoice *sourceCap in sourceCaps) {
        if (sourceCap.linkCapClass == _sourceCap.class
            && sourceCap.filled == _sourceCap.filled) {
            found = sourceCap;
            break;
        }
    }

    return found ?: sourceCaps[0];
}

- (void)setInspectedSourceCap:(DrawLinkInspectorChoice *)choice {
    if (choice.title != nil) {
        self.sourceCap = nil;
    } else {
        DrawLinkCap *linkCap = [[choice.linkCapClass alloc] initWithType:DrawLinkCapTypeHead];
        if (_sourceCap) {
            linkCap.length = _sourceCap.length;
            linkCap.thickness = _sourceCap.thickness;
            linkCap.filled = choice.filled;
        }
        self.sourceCap = linkCap;
    }
}

+ (NSArray<DrawLinkInspectorChoice *> *)allPossibleDestinationCaps {
    static NSMutableArray<DrawLinkInspectorChoice *> *linkCaps = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        linkCaps = [NSMutableArray array];
        [linkCaps addObject:[DrawLinkInspectorChoice choiceWithLabel:@"None"]];
        for (Class linkCapClass in DrawLinkTool.linkCaps) {
            [linkCaps addObject:[DrawLinkInspectorChoice choiceWithClass:linkCapClass source:NO filled:YES]];
            [linkCaps addObject:[DrawLinkInspectorChoice choiceWithClass:linkCapClass source:NO filled:NO]];
        }
    });

    return linkCaps;
}

- (NSArray<DrawLinkInspectorChoice *> *)allPossibleDestinationCaps {
    return [[self class] allPossibleDestinationCaps];
}

- (DrawLinkInspectorChoice *)inspectedDestinationCap {
    NSArray<DrawLinkInspectorChoice *> *destination = [[self class] allPossibleDestinationCaps];

    if (_destinationCap == nil) {
        // The "none" option.
        return destination[0];
    }

    DrawLinkInspectorChoice *found = nil;
    for (DrawLinkInspectorChoice *destinationCap in destination) {
        if (destinationCap.linkCapClass == _destinationCap.class
            && destinationCap.filled == _destinationCap.filled) {
            found = destinationCap;
            break;
        }
    }

    return found ?: destination[0];
}

- (void)setInspectedDestinationCap:(DrawLinkInspectorChoice *)choice {
    if (choice.title != nil) {
        self.destinationCap = nil;
    } else {
        DrawLinkCap *linkCap = [[choice.linkCapClass alloc] initWithType:DrawLinkCapTypeHead];
        if (_destinationCap) {
            linkCap.length = _destinationCap.length;
            linkCap.thickness = _destinationCap.thickness;
            linkCap.filled = choice.filled;
        }
        self.destinationCap = linkCap;
    }
}

@end
