/*
DrawCircle.h
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

#import <AJRFoundation/AJRFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(uint8_t, DrawCircleHandleIndex) {
    DrawCircleHandleFirst = 0,
    DrawCircleHandleStartAngle = 1,
    DrawCircleHandleEndAngle = 2,
    DrawCircleHandleOrigin = 3
};

typedef NS_ENUM(uint8_t, DrawCircleType) {
    DrawCircleTypeCircle,
    DrawCircleTypePie,
    DrawCircleTypeChord,
};

extern const AJRInspectorIdentifier AJRInspectorIdentifierCircle;

@interface DrawCircle : DrawGraphic <AJRXMLCoding>

@property (nonatomic,readonly) BOOL isCircle;
@property (nonatomic,assign) NSPoint origin;
@property (nonatomic,assign) CGFloat radius;
@property (nonatomic,assign) CGFloat startAngle;
@property (nonatomic,assign) CGFloat endAngle;
@property (nonatomic,assign) NSRect arcBounds;
@property (nonatomic,assign) DrawCircleType type;

@end

extern NSString *DrawStringFromDrawCircleType(DrawCircleType type);
extern DrawCircleType DrawCircleTypeFromString(NSString *type);

NS_ASSUME_NONNULL_END
