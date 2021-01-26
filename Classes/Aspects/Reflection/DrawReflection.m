//
//  DrawReflection.m
//  Draw
//
//  Created by Alex Raftis on 9/9/11.
//  Copyright (c) 2011 Apple, Inc. All rights reserved.
//

#import "DrawReflection.h"

#import "DrawShadow.h"

#import <AJRFoundation/AJRFoundation.h>

NSString * const DrawReflectionIdentifier = @"reflection";

@implementation DrawReflection

#pragma mark - Utilities

- (CGImageRef)fadeMask {
    static CGImageRef fadeMask = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        size_t  width = 1;
        size_t  height = 256;
        
        // To show the difference with an image mask, we take the above image and process it to extract
        // the alpha channel as a mask.
        // Allocate data
        NSMutableData *data = [NSMutableData dataWithLength:width * height * 1];
        unsigned char *bytes = [data mutableBytes];
        
        // Create a bitmap context (According to the docs, it's OK to pass kCGImageAlphaOnly here.
        CGContextRef context = CGBitmapContextCreate(fadeMask, width, height, 8, width, NULL, (CGBitmapInfo)kCGImageAlphaOnly);
        // Set the blend mode to copy to avoid any alteration of the source data
        CGContextSetBlendMode(context, kCGBlendModeCopy);
        // Draw the image to extract the alpha channel
        for (NSInteger y = 0; y < height; y++) {
            for (NSInteger x = 0; x < width; x++) {
                NSInteger value = (y + 25) * 2;
                if (value > 255) value = 255;
                bytes[y * width + x] = (unsigned char)value;
            }
        }
        // Now the alpha channel has been copied into our NSData object above, so discard the context and lets make an image mask.
        CGContextRelease(context);
        // Create a data provider for our data object (NSMutableData is tollfree bridged to CFMutableDataRef, which is compatible with CFDataRef)
        CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((__bridge CFMutableDataRef)data);
        // Create our new mask image with the same size as the original image
        fadeMask = CGImageMaskCreate(width, height, 8, 8, width, dataProvider, NULL, YES);
        // And release the provider.
        CGDataProviderRelease(dataProvider);
    });
    
    return fadeMask;
}

#pragma mark - DrawAspect

- (DrawGraphicCompletionBlock)drawPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    NSRect bounds = [path bounds];
    NSAffineTransform *transform = [[NSAffineTransform alloc] init];
    
    CGContextSaveGState(context);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextTranslateCTM(context, 0.0, (-2.0 * bounds.origin.y) + (-2.0 * bounds.size.height) - 2.0);
    [transform concat];
    CGContextClipToMask(context, NSInsetRect(bounds, -10.0, -10.0), [self fadeMask]);
    CGContextBeginTransparencyLayer(context, NULL);
    [self.graphic drawWithAspectFilter:^BOOL(DrawAspect *aspect, DrawAspectPriority priority) {
        if (aspect == self) return NO;
        if ([aspect isKindOfClass:[DrawShadow class]]) return NO;
        return YES;
    }];
    CGContextEndTransparencyLayer(context);
    CGContextRestoreGState(context);
    
    return NULL;
}

- (NSRect)boundsForPath:(AJRBezierPath *)path {
    NSRect bounds = [path bounds];
    
    bounds.size.height += (bounds.size.height / 2.0);
    
    return bounds;
}

@end
