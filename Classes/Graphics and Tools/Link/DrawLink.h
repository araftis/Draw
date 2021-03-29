/*
DrawLink.h
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

#import <Draw/DrawPen.h>

#import <AJRFoundation/AJRFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class DrawLinkCap;

extern const AJRInspectorIdentifier AJRInspectorIdentifierLink;

@interface DrawLink : DrawPen <AJRXMLCoding>

- (id)initWithSource:(nullable DrawGraphic *)sourceGraphic;

@property (nullable,nonatomic,strong) DrawGraphic *source;
- (void)setSource:(DrawGraphic *)aSource withHandle:(DrawHandle)aHandle;
@property (nonatomic,assign) NSPoint sourcePoint;
@property (nonatomic,readonly) NSPoint adjustedSourcePoint;
@property (nonatomic,assign) DrawHandle sourceHandle;
- (void)updateSourcePoint;
@property (nullable,nonatomic,strong) DrawLinkCap *sourceCap;

@property (nullable,nonatomic,strong) DrawGraphic *destination;
- (void)setDestination:(DrawGraphic *)destination withHandle:(DrawHandle)aHandle;
@property (nonatomic,assign) NSPoint destinationPoint;
@property (nonatomic,readonly) NSPoint adjustedDestinationPoint;
@property (nonatomic,assign) DrawHandle destinationHandle;
- (void)updateDestinationPoint;
@property (nullable,nonatomic,strong) DrawLinkCap *destinationCap;

- (CGFloat)angleInDegreesOfSourceSegment;
- (CGFloat)angleInDegreesOfDestinationSegment;

#pragma mark - Equality

- (BOOL)isEqualToLink:(DrawLink *)other;

@end

NS_ASSUME_NONNULL_END
