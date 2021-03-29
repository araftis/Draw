/*
DrawGraphic-Subgraphics.m
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

#import "DrawGraphic.h"

#import "DrawPage.h"
#import "DrawDocument.h"

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

@implementation DrawGraphic (Subgraphics)

- (void)_adjustFrameAndBoundsForSubgraphic:(DrawGraphic *)subgraphic {
    CGFloat inset;

    if (self.document) {
        inset = -[self.document gridSpacing];
    } else {
        inset = 0.0;
    }

    if ([_subgraphics count] == 1) {
        if ([[subgraphic subgraphics] count]) {
            [self setFrame:[subgraphic frame]];
            self.bounds = [subgraphic bounds];
        } else {
            [self setFrame:NSInsetRect([subgraphic frame], inset, inset)];
            [self setBounds:NSInsetRect([subgraphic bounds], inset, inset)];
        }
    } else {
        if ([[subgraphic subgraphics] count]) {
            [self setBounds:NSUnionRect(self.bounds, [subgraphic bounds])];
            [self setFrame:NSUnionRect(self.frame, [subgraphic frame])];
        } else {
            [self setBounds:NSUnionRect(self.bounds, NSInsetRect([subgraphic bounds], inset, inset))];
            [self setFrame:NSUnionRect(self.frame, NSInsetRect([subgraphic frame], inset, inset))];
        }
    }

    [_path removeAllPoints];
    [_path appendBezierPathWithRect:self.frame];
}

- (void)addSubgraphic:(DrawGraphic *)subgraphic {
    [self addSubgraphic:subgraphic positioned:NSWindowAbove relativeTo:[_subgraphics lastObject]];
}

- (void)addSubgraphic:(DrawGraphic *)subgraphic positioned:(NSWindowOrderingMode)place relativeTo:(DrawGraphic *)otherGraphic {
    NSUInteger		index;

    if (subgraphic->_supergraphic) {
        [subgraphic removeFromSupergraphic];
    }

    index = [_subgraphics indexOfObjectIdenticalTo:otherGraphic];
    if (index == NSNotFound) {
        [subgraphic graphicWillMoveToSupergraphic:self];
        [_subgraphics addObject:subgraphic];
        subgraphic->_supergraphic = self;
        if (!self.editing) {
            [self _adjustFrameAndBoundsForSubgraphic:subgraphic];
        }
    } else {
        if (place == NSWindowAbove) {
            [subgraphic graphicWillMoveToSupergraphic:self];
            if (index == [_subgraphics count] - 1) {
                [_subgraphics addObject:subgraphic];
            } else {
                [_subgraphics insertObject:subgraphic atIndex:index + 1];
            }
        } else if (place == NSWindowBelow) {
            [subgraphic graphicWillMoveToSupergraphic:self];
            [_subgraphics insertObject:subgraphic atIndex:index];
        } else {
            [NSException raise:NSInvalidArgumentException format:@"Cannot place a subgraphic with place %d\n", (int)place];
        }
        subgraphic->_supergraphic = self;
        if (!self.editing) {
            [self _adjustFrameAndBoundsForSubgraphic:subgraphic];
        }
    }

    [subgraphic setPage:self.page];
    [subgraphic setDocument:self.document];
    [subgraphic setLayer:self.layer];
    [self.page observeGraphic:subgraphic yesNo:YES];
}

- (void)replaceSubgraphic:(DrawGraphic *)oldGraphic with:(DrawGraphic *)newGraphic {
    NSInteger			index;

    index = [_subgraphics indexOfObjectIdenticalTo:oldGraphic];
    if (index == NSNotFound) {
        [NSException raise:NSInvalidArgumentException format:@"%@ does not contain subgraphic %@", self, oldGraphic];
    }

    if (newGraphic->_supergraphic) [newGraphic removeFromSupergraphic];

    [newGraphic graphicWillMoveToSupergraphic:self];
    [_subgraphics replaceObjectAtIndex:index withObject:newGraphic];
    oldGraphic->_supergraphic = nil;
    newGraphic->_supergraphic = self;
    if (!self.editing) {
        [_supergraphic sizeToFit];
    }

    [[self page] observeGraphic:oldGraphic yesNo:NO];
    [[self page] observeGraphic:newGraphic yesNo:YES];
}

- (NSArray *)subgraphics {
    return _subgraphics;
}

- (DrawGraphic *)supergraphic {
    return _supergraphic;
}

- (DrawGraphic *)ancestorSharedWithView:(DrawGraphic *)aSupergraphic {
    DrawGraphic		*parent = self;

    while (parent) {
        if ([aSupergraphic isDescendantOf:parent]) return parent;
        parent = [parent supergraphic];
    }

    return nil;
}

- (BOOL)isDescendantOf:(DrawGraphic *)aSupergraphic {
    DrawGraphic 	*parent;

    if (aSupergraphic == nil) return YES;

    parent = [self supergraphic];

    while (parent) {
        if (parent == aSupergraphic) return YES;
        parent = [parent supergraphic];
    }

    return NO;
}

- (void)removeFromSupergraphic {
    NSMutableArray		*superSubgraphics = (NSMutableArray *)[_supergraphic subgraphics];
    NSUInteger			index;

    index = [superSubgraphics indexOfObjectIdenticalTo:self];
    if (index != NSNotFound) {
        [superSubgraphics removeObjectAtIndex:index];
        if (![_supergraphic editing]) {
            [_supergraphic sizeToFit];
        }
        _supergraphic = nil;
    }

    [self.page observeGraphic:self yesNo:NO];
    self.page = nil;
    self.layer = nil;
    self.document = nil;
}

- (void)sortSubgraphicsUsingFunction:(NSInteger (*)(id, id, void *))compare context:(void *)context {
    [_subgraphics sortUsingFunction:compare context:context];
}

- (void)sizeToFit {
    NSInteger x;
    DrawGraphic *subgraphic;
    CGFloat inset = -[self.document gridSpacing];

    NSRect frame, bounds;
    for (x = 0; x < (const NSInteger)[_subgraphics count]; x++) {
        subgraphic = [_subgraphics objectAtIndex:x];

        if (x == 0) {
            if ([[subgraphic subgraphics] count]) {
                frame = subgraphic.frame;
                bounds = subgraphic.bounds;
            } else {
                frame = NSInsetRect(subgraphic.frame, inset, inset);
                bounds = NSInsetRect(subgraphic.bounds, inset, inset);
            }
        } else {
            if (subgraphic.subgraphics.count != 0) {
                bounds = NSUnionRect(bounds, subgraphic.bounds);
                frame = NSUnionRect(frame, subgraphic.frame);
            } else {
                bounds = NSUnionRect(bounds, NSInsetRect(subgraphic.bounds, inset, inset));
                frame = NSUnionRect(frame, NSInsetRect(subgraphic.frame, inset, inset));
            }
        }
    }

    [self setFrame:frame];
    [self setBounds:bounds];

    [_path removeAllPoints];
    [_path appendBezierPathWithRect:self.frame];
}

- (void)graphicWillMoveToSupergraphic:(DrawGraphic *)newSupergraphic {
    // Default implementation does nothing.
}

- (void)setAutosizeSubgraphics:(BOOL)flag {
    if (_autosizeSubgraphics != flag) {
        _autosizeSubgraphics = flag;
    }
}

- (BOOL)autosizeSubgraphics {
    return _autosizeSubgraphics;
}

- (void)_resizeSubgraphicsFromRect:(NSRect)oldFrame toRect:(NSRect)newFrame {
    NSInteger	x;
    DrawGraphic	*graphic;
    NSRect		graphicFrame;
    NSRect		deltaRect;

    if (!NSEqualRects(oldFrame, newFrame)) {
        if (NSEqualSizes(oldFrame.size, newFrame.size)) {

            deltaRect.origin.x = newFrame.origin.x - oldFrame.origin.x;
            deltaRect.origin.y = newFrame.origin.y - oldFrame.origin.y;
            deltaRect.size = (NSSize){1.0, 1.0};

            for (x = 0; x < (const NSInteger)[_subgraphics count]; x++) {
                graphic = [_subgraphics objectAtIndex:x];
                graphicFrame = [graphic frame];
                graphicFrame.origin.x += deltaRect.origin.x;
                graphicFrame.origin.y += deltaRect.origin.y;
                [graphic setFrame:graphicFrame];
            }
        } else {
            deltaRect.origin.x = newFrame.origin.x - oldFrame.origin.x;
            deltaRect.origin.y = newFrame.origin.y - oldFrame.origin.y;
            deltaRect.size.width = newFrame.size.width / oldFrame.size.width;
            deltaRect.size.height = newFrame.size.height / oldFrame.size.height;

            for (x = 0; x < (const NSInteger)[_subgraphics count]; x++) {
                graphic = [_subgraphics objectAtIndex:x];
                graphicFrame = [graphic frame];
                graphicFrame.origin.x = (graphicFrame.origin.x - oldFrame.origin.x) * deltaRect.size.width + newFrame.origin.x;
                graphicFrame.origin.y = (graphicFrame.origin.y - oldFrame.origin.y) * deltaRect.size.height + newFrame.origin.y;
                graphicFrame.size.width *= deltaRect.size.width;
                graphicFrame.size.height *= deltaRect.size.height;
                [graphic setFrame:graphicFrame];
            }
        }
    }
}

- (void)addClip {
    [_supergraphic addClip];
    [_path addClip];
}

- (void)_setSupergraphic:(DrawGraphic *)aSupergraphic {
    _supergraphic = aSupergraphic;
}

- (void)setAutoresizingMask:(DrawAutosizeMask)mask {
    if (_autosizingMask != mask) {
        [(NSView *)[self.document prepareWithInvocationTarget:self] setAutoresizingMask:(NSAutoresizingMaskOptions)_autosizingMask];
        _autosizingMask = mask;
    }
}

- (DrawAutosizeMask)autoresizingMask {
    return _autosizingMask;
}

@end

