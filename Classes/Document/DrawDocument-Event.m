/*
 DrawDocument-Event.m
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

#import "DrawDocument.h"

#import "DrawEvent.h"
#import "DrawFunctions.h"
#import "DrawGraphic.h"
#import "DrawPage.h"

@interface DrawGraphicPasteboardWriter : NSObject <NSPasteboardWriting>

+ (id)writerWithPDFData:(NSData *)pdfData selection:(NSArray<DrawGraphic *> *)selection;
- (id)initWithPDFData:(NSData *)pdfData selection:(NSArray<DrawGraphic *> *)selection;

@property (nonatomic,strong) NSData *pdfData;
@property (nonatomic,strong) NSArray<DrawGraphic *> *selection;

@end

@implementation DrawGraphicPasteboardWriter

+ (id)writerWithPDFData:(NSData *)pdfData selection:(NSArray<DrawGraphic *> *)selection {
    return [[self alloc] initWithPDFData:pdfData selection:selection];
}

- (id)initWithPDFData:(NSData *)pdfData selection:(NSArray<DrawGraphic *> *)selection {
    if ((self = [super init])) {
        _pdfData = pdfData;
        _selection = selection;
    }
    return self;
}

- (nullable id)pasteboardPropertyListForType:(nonnull NSPasteboardType)type {
    NSData *data = nil;
    
    if ([type isEqualToString:DrawGraphicPboardType]) {
        data = [AJRXMLArchiver archivedDataWithRootObject:_selection];
    } else if ([type isEqualToString:NSPasteboardTypePDF]) {
        DrawDocument *document = _selection.lastObject.document;
        if (document != nil) {
            data = [document PDFForGraphics:_selection];
        }
    }
    return data;
}

- (nonnull NSArray<NSPasteboardType> *)writableTypesForPasteboard:(nonnull NSPasteboard *)pasteboard {
    return @[NSPasteboardTypePDF,
             DrawGraphicPboardType];
}

@end

@implementation DrawDocument (Event)

- (BOOL)dragSelection:(NSArray<DrawGraphic *> *)selection withLastHitGraphic:(DrawGraphic *)graphic fromEvent:(DrawEvent *)event {
    DrawPage *actualView = [[selection lastObject] page];
    NSSize offset;
    NSData *data;
    NSImage *image;
    NSPoint where;
    NSRect bounds;
    NSInteger x;

    for (x = 0; x < (const NSInteger)[selection count]; x++) {
        if ([[selection objectAtIndex:x] editing]) {
            return NO;
        }
    }

    data = [[event document] PDFForGraphics:[[event document] sortedSelection]];

    if (data != nil) {
        image = [[NSImage alloc] initWithData:data];

        where = [event locationOnPage];
        bounds = DrawBoundsForGraphics(selection);
        where.x -= (where.x - bounds.origin.x);
        where.y -= (where.y - bounds.origin.y);
        offset = (NSSize){0.0, 0.0};
        NSRect draggingFrame = (NSRect){where, image.size};

        NSDraggingItem *item = [[NSDraggingItem alloc] initWithPasteboardWriter:[DrawGraphicPasteboardWriter writerWithPDFData:data selection:selection]];
        item.draggingFrame = draggingFrame;
        item.imageComponentsProvider = ^NSArray<NSDraggingImageComponent *> * _Nonnull{
            NSDraggingImageComponent *component = [NSDraggingImageComponent draggingImageComponentWithKey:@"Test"];
            component.contents = image;
            component.frame = draggingFrame;
            return @[component];
        };

        [actualView beginDraggingSessionWithItems:@[item] event:event.event source:self];

        return YES;
    }

    return NO;
}

- (NSDragOperation)draggingSession:(nonnull NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    return NSDragOperationCopy;
}

@end
