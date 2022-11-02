/*
 DrawImage.m
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

#import "DrawImage.h"

#import "DrawFunctions.h"
#import "DrawPage.h"
#import "DrawDocument.h"

#import <AJRInterface/AJRInterface.h>

NSString * const DrawImageAspectKey = @"DrawImageAspectKey";

NSString * const DrawPreferencesImageAlignmentKey = @"imageAlignment";
NSString * const DrawPreferencesImageScalingKey = @"imageScaling";

@interface DrawImage ()

@property (nonatomic,strong) NSDate *modificationDate;

@end

@implementation DrawImage {
    NSImageCell *_imageCell;
}


- (id)initWithGraphic:(DrawGraphic *)aGraphic {
    if ((self = [super initWithGraphic:aGraphic])) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        [self setImageAlignment:[defaults integerForKey:DrawPreferencesImageAlignmentKey]];
        [self setImageScaling:[defaults integerForKey:DrawPreferencesImageScalingKey]];
    }

    return self;
}

- (DrawGraphicCompletionBlock)drawPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    NSRect frame = [self.graphic frame];
    NSBezierPath *workPath;

    [[NSGraphicsContext currentContext] saveGraphicsState];
    @try {
        [path addClip];
        [_imageCell drawInteriorWithFrame:frame inView:[self.graphic page]];
        // Force an error to occur if it's going to occur.
        [[NSGraphicsContext currentContext] flushGraphics];
    } @catch (NSException *localException) {
        NSFrameRect(frame);
        [[NSColor blackColor] set];
        workPath = [[NSBezierPath alloc] init];
        [workPath moveToPoint:frame.origin];
        [workPath relativeLineToPoint:(NSPoint){frame.size.width, frame.size.height}];
        [workPath moveToPoint:(NSPoint){frame.origin.x+frame.size.width,frame.origin.y}];
        [workPath relativeLineToPoint:(NSPoint){-frame.size.width, frame.size.height}];
        [workPath stroke];
    }
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    
    return NULL;
}

- (BOOL)isPoint:(NSPoint)aPoint inPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    return [path isHitByPoint:aPoint];
}

- (void)setImage:(NSImage *)anImage {
    if (_image != anImage) {
        _image = anImage;

        _naturalSize = [_image size];

        _imageCell = [[NSImageCell alloc] initImageCell:_image];
        [_imageCell setImageAlignment:_imageAlignment];
        [_imageCell setImageScaling:_imageScaling];

        [_image setNaturalSize:_image.size];
    }
}

- (void)setFilename:(NSString *)aFilename {
    if (![aFilename isEqualToString:_filename]) {
        _filename = aFilename;
        [self updateImage];
    }
}

- (void)setImageAlignment:(NSImageAlignment)newAlign {
    if (_imageAlignment != newAlign) {
        _imageAlignment = newAlign;
        [_imageCell setImageAlignment:_imageAlignment];
    }
}

- (void)setImageScaling:(NSImageScaling)newScaling {
    if (_imageScaling != newScaling) {
        _imageScaling = newScaling;
        [_imageCell setImageScaling:_imageScaling];
    }
}

- (id)copyWithZone:(NSZone *)zone {
    DrawImage *aspect = [super copyWithZone:zone];

    aspect->_image = [_image copyWithZone:zone];
    aspect->_imageAlignment = _imageAlignment;
    aspect->_imageScaling = _imageScaling;
    if (_filename) {
        aspect->_filename = [_filename copyWithZone:zone];
        aspect->_modificationDate = _modificationDate;
    }

    return aspect;
}

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super decodeWithXMLCoder:coder];

    _imageCell = [[NSImageCell alloc] initImageCell:nil];

    [coder decodeObjectForKey:@"image" setter:^(id  _Nonnull object) {
        self->_image = object;
        self->_imageCell.image = self->_image;
    }];
    [coder decodeSizeForKey:@"naturalSize" setter:^(CGSize size) {
        self->_naturalSize = size;
    }];
    [coder decodeObjectForKey:@"filename" setter:^(id  _Nonnull object) {
        self->_filename = object;
    }];
    [coder decodeObjectForKey:@"modificationDate" setter:^(id  _Nonnull object) {
        self->_modificationDate = object;
    }];
    [coder decodeIntegerForKey:@"imageAlignment" setter:^(NSInteger value) {
        self->_imageAlignment = value;
        [self->_imageCell setImageAlignment:self->_imageAlignment];
    }];
    [coder decodeIntegerForKey:@"imageScaling" setter:^(NSInteger value) {
        self->_imageScaling = value;
        [self->_imageCell setImageScaling:self->_imageScaling];
    }];
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)encoder {
    [super encodeWithXMLCoder:encoder];

    [encoder encodeObject:_image forKey:@"image"];
    [encoder encodeSize:_naturalSize forKey:@"naturalSize"];
    [encoder encodeString:_filename forKey:@"filename"];
    [encoder encodeObject:_modificationDate forKey:@"modificationDate"];

    [encoder encodeInteger:_imageAlignment forKey:@"imageAlignment"];
    [encoder encodeInteger:_imageScaling forKey:@"imageScaling"];
}

- (void)updateImage {
    if (_filename) {
        NSImage *work = [[NSImage alloc] initWithContentsOfFile:_filename];
        [self setImage:work];
    }
}

@end
