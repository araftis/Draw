/*
DrawAdobeIllustrator.h
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

#import <Draw/DrawFilter.h>

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

@class DrawDocument;

@interface DrawAdobeIllustrator : DrawFilter
{
    NSFileHandle *file;
    NSMutableArray *stack;
    NSMutableArray *groupStack;
    DrawDocument *view;
    NSCharacterSet *separators;

    // Document Attributes.
    NSRect boundingBox;
    NSArray *dashArray;
    double dashPhase;
    double flatness;
    AJRLineJoinStyle lineJoin;
    AJRLineCapStyle lineCap;
    double miterLimit;
    double lineWidth;
    NSColor *strokeColor;
    NSColor *fillColor;
    AJRBezierPath *path;
    NSInteger textType;
    NSMutableParagraphStyle *paragraphStyle;
    NSMutableDictionary *attributes;
    NSMutableAttributedString *string;
    NSInteger textRenderingType;
    CGFloat textOffset;
    NSPoint textOrigin;

    struct _aiFlags {
        BOOL                    locked:1;
        BOOL                    winding:1;
        BOOL                    overprintStroke:1;
        BOOL                    overprintFill:1;
        NSUInteger              _reserved:28;
    } aiFlags;
}

@end
