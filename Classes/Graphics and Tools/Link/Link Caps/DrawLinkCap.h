/*
DrawLinkCap.h
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

#import <AppKit/AppKit.h>
#import <AJRFoundation/AJRFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class DrawGraphic, DrawLink, AJRBezierPath;

typedef NS_ENUM(uint8_t, DrawLinkCapType) {
    DrawLinkCapTypeHead,
    DrawLinkCapTypeTail
};

extern NSString *DrawStringFromLinkCapType(DrawLinkCapType type);
extern DrawLinkCapType DrawLinkCapTypeFromString(NSString *string);

extern NSString *DrawLinkCapHeadStyleKey;
extern NSString *DrawLinkCapHeadThicknessKey;
extern NSString *DrawLinkCapHeadLengthKey;
extern NSString *DrawLinkCapHeadFilledKey;
extern NSString *DrawLinkCapTailStyleKey;
extern NSString *DrawLinkCapTailThicknessKey;
extern NSString *DrawLinkCapTailLengthKey;
extern NSString *DrawLinkCapTailFilledKey;

@interface DrawLinkCap : NSObject <NSCopying, AJRXMLCoding>

/*!
 Creates a default styled link cap. Note that this not the preferred initializer. You should call -initWithType: instead, as knowing whether the cap is a head or tail cap can be important. This initializer is primarily used for archiving purposes.

 @return A newly created, default link cap.
 */
- (id)init;

/*!
 Create a new link cap that will act as either a "head" or "tail" cap. A head cap points into the destination graphic while the tail cap points back to the source graphic.

 @param type The type of the link cap.

 @return A newly created link cap.
 */
- (id)initWithType:(DrawLinkCapType)type;

- (void)graphicDidChangeShape:(DrawGraphic *)aGraphic;

- (void)linkCapWillAddToLink:(DrawLink *)aLink asType:(DrawLinkCapType)aType;
- (void)linkCapDidAddToLink:(DrawLink *)aLink asType:(DrawLinkCapType)aType;
- (void)linkCapWillRemoveFromLink:(DrawLink *)aLink;
- (void)linkCapDidRemoveFromLink:(DrawLink *)aLink;

@property (nonatomic,readonly,weak) DrawLink *link;
@property (nonatomic,readonly) DrawLinkCapType capType;
@property (nonatomic,assign) CGFloat thickness;
@property (nonatomic,assign) CGFloat length;
@property (nonatomic,assign) BOOL filled;
@property (nonatomic,readonly) AJRBezierPath *path;

- (NSPoint)initialPointFromPoint:(NSPoint)originalPoint;

- (void)update;

+ (NSImage *)sourceImageFilled:(BOOL)flag;
+ (NSImage *)destinationImageFilled:(BOOL)flag;

#pragma mark - Equality

- (BOOL)isEqualToLinkCap:(DrawLinkCap *)other;

@end

NS_ASSUME_NONNULL_END
