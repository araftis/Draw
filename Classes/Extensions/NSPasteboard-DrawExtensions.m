/*
NSPasteboard-DrawExtensions.m
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

#import "NSPasteboard-DrawExtensions.h"

#import "DrawDocument.h"
#import "DrawGraphic.h"
#import "DrawPage.h"

@implementation NSPasteboard (DrawExtensions)

- (void)setDrawGraphicsAsNative:(NSArray<DrawGraphic *> *)graphics {
    NSMutableArray *array = [graphics mutableCopyWithZone:NSDefaultMallocZone()];
    [self setData:[NSKeyedArchiver ajr_archivedObject:array error:NULL] forType:DrawGraphicPboardType];
}

- (void)setDrawGraphicsAsPDF:(NSArray<DrawGraphic *> *)graphics {
    NSData *data;

    data = [[[[graphics lastObject] page] document] PDFForGraphics:graphics];

    if (data) {
        [self setData:data forType:NSPasteboardTypePDF];
    }
}

- (void)setDrawGraphics:(NSArray<DrawGraphic *> *)graphics forType:(NSString *)dataType {
    if ([dataType isEqualToString:DrawGraphicPboardType]) {
        [self setDrawGraphicsAsNative:graphics];
    } else if ([dataType isEqualToString:NSPasteboardTypePDF]) {
        [self setDrawGraphicsAsPDF:graphics];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"An array of draw graphics cannot be represented as %@.", dataType];
    }
}

- (NSArray *)drawGraphicsFromNative {
    NSData *data;

    data = [self dataForType:DrawGraphicPboardType];
    if (!data) return nil;

    return [NSKeyedUnarchiver ajr_unarchivedObjectWithData:data error:NULL];
}

- (NSArray *)drawGraphicsFromEPS {
    return nil;
}

- (NSArray *)drawGraphicsForType:(NSString *)dataType {
    if ([dataType isEqualToString:DrawGraphicPboardType]) {
        return [self drawGraphicsFromNative];
    } else if ([dataType isEqualToString:@"com.adobe.encapsulated-postscript"]) {
        [self drawGraphicsFromEPS];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"An array of draw graphics cannot be represented as %@.", dataType];
    }

    return nil;
}

@end
