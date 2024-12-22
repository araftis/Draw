/*
 DrawPen.h
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

#import <AJRFoundation/AJRFoundation.h>
#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct __drawPolyPos {
   AJRBezierPathElement	currentOp;
   AJRBezierPathElement	previousOp;
   AJRBezierPathElement	nextOp;
   NSInteger currentOffset;
   NSInteger previousOffset;
   NSInteger nextOffset;
   DrawHandle handle;
} _DrawPolyPos;

extern const AJRInspectorIdentifier AJRInspectorIdentifierPen;

@interface DrawPen : DrawGraphic <AJRXMLCoding>

- (id)initWithFrame:(NSRect)aFrame;
- (id)initWithFrame:(NSRect)frame path:(AJRBezierPath *)aPath;

- (BOOL)appendLineToPoint:(NSPoint)point;
/**
 Offers an override point where subclasses can prevent adding new move to points.

 This can happen with certain graphics that don't want to allow subpaths. For example, DrawLinks.

 @param point Where the move to would be added.

 @return `YES` if the point can be added.
 */
- (BOOL)canAppendMoveToPoint:(NSPoint)point;
- (BOOL)appendMoveToPoint:(NSPoint)point;
- (BOOL)appendBezierCurve:(AJRBezierCurve)curve;
- (BOOL)appendBezierCurveToPoint:(NSPoint)point controlPoint1:(NSPoint)controlPoint1 controlPoint2:(NSPoint)controlPoint2;
- (BOOL)insertPoint:(NSPoint)point atIndex:(NSUInteger)index;
- (BOOL)insertPoint:(NSPoint)point;
- (BOOL)removePointAtIndex:(NSUInteger)index;
- (BOOL)removePoint:(NSPoint)point;

- (BOOL)isLine;

- (DrawHandle)initializePositionForHandle:(DrawHandle)handle;

@property (nonatomic,assign) BOOL closed;
@property (nonatomic,assign) BOOL creating;

- (BOOL)isEqualToPen:(DrawPen *)other;

@end

NS_ASSUME_NONNULL_END
