/*
 DrawImageTool.m
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

#import "DrawImageTool.h"

#import "DrawImage.h"
#import "DrawPage.h"
#import "DrawDocument.h"
#import <Draw/Draw-Swift.h>

#import <AJRInterface/AJRInterface.h>

@implementation DrawImageTool {
    NSString *_dragSourceType;
 }

- (id)init {
    self = [super init];

    [DrawDocument registerTool:self forDraggedTypes:@[NSPasteboardTypeTIFF, NSPasteboardTypePDF, NSPasteboardTypeFileURL]];

    return self;
}

- (NSUInteger)draggingEntered:(id <NSDraggingInfo>)sender inView:(DrawPage *)drawPage {
    NSPasteboard *pasteboard;
    NSUInteger sourceDragMask;

    sourceDragMask = [sender draggingSourceOperationMask];
    pasteboard = [sender draggingPasteboard];

    if ([[pasteboard types] indexOfObject:NSPasteboardTypeTIFF] != NSNotFound) {
        if (sourceDragMask & NSDragOperationCopy) {
            _dragSourceType = NSPasteboardTypeTIFF;
            return NSDragOperationCopy;
        }
    }
    if ([[pasteboard types] indexOfObject:NSPasteboardTypePDF] != NSNotFound) {
        if (sourceDragMask & NSDragOperationCopy) {
            _dragSourceType = NSPasteboardTypePDF;
            return NSDragOperationCopy;
        }
    }
    if ([[pasteboard types] indexOfObject:NSPasteboardTypeFileURL] != NSNotFound) {
        if ((sourceDragMask & NSDragOperationCopy) || (sourceDragMask & NSDragOperationLink)) {
            NSArray *filenames = [pasteboard propertyListForType:NSPasteboardTypeFileURL];
            NSInteger x;

            for (x = 0; x < (const NSInteger)[filenames count]; x++) {
                if ([NSImage ajr_supportsFileExtension:[[filenames objectAtIndex:x] pathExtension]]) {
                    _dragSourceType = NSPasteboardTypeFileURL;
                    if (sourceDragMask & NSDragOperationCopy) return NSDragOperationCopy;
                    return NSDragOperationLink;
                }
            }
        }
    }

    return NSDragOperationNone;
}

- (NSUInteger)draggingUpdated:(id <NSDraggingInfo>)sender inView:(DrawPage *)drawPage {
    NSUInteger sourceDragMask = [sender draggingSourceOperationMask];

    if (_dragSourceType == NSPasteboardTypeFileURL) {
        if (sourceDragMask & NSDragOperationCopy) return NSDragOperationCopy;
        else if (sourceDragMask & NSDragOperationLink) return NSDragOperationLink;
    } else {
        if (sourceDragMask & NSDragOperationCopy) return NSDragOperationCopy;
    }

    return NSDragOperationNone;
}

- (void)addImageAspect:(DrawImage *)imageAspect toPage:(DrawPage *)drawPage at:(NSPoint)location {
    DrawRectangle *rectangle;
    NSImage *image = [imageAspect image];
    NSSize size;

    if (image) {
        size = [image size];
    } else {
        size = (NSSize){1.0, 1.0};
    }

    if ([drawPage isFlipped]) {
        location.y -= size.height;
    }

    rectangle = [[DrawRectangle alloc] initWithFrame:(NSRect){location, size}];
    [imageAspect setGraphic:rectangle];
    [rectangle addAspect:imageAspect withPriority:DrawAspectPriorityBackground];
    [drawPage addGraphic:rectangle];
}

- (void)addImageWithFilename:(NSString *)filename toPage:(DrawPage *)drawPage at:(NSPoint)location {
    DrawImage *imageAspect;

    imageAspect = [[DrawImage alloc] initWithGraphic:nil];
    [imageAspect setFilename:filename];
    [self addImageAspect:imageAspect toPage:drawPage at:location];
}

- (void)addImage:(NSImage *)image toPage:(DrawPage *)drawPage at:(NSPoint)location {
    DrawImage *imageAspect;

    imageAspect = [[DrawImage alloc] initWithGraphic:nil];
    [imageAspect setImage:image];
    [self addImageAspect:imageAspect toPage:drawPage at:location];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender inView:(DrawPage *)drawPage {
    NSPasteboard *pasteboard;
    NSPoint location = [drawPage convertPoint:[sender draggedImageLocation] fromView:nil];

    pasteboard = [sender draggingPasteboard];

    if ([[pasteboard types] indexOfObject:NSPasteboardTypePDF] != NSNotFound) {
        return YES;
    } else if ([[pasteboard types] indexOfObject:NSPasteboardTypeTIFF] != NSNotFound) {
        NSData *data;
        NSImage *image;

        data = [pasteboard dataForType:NSPasteboardTypeTIFF];
        if (data) {
            image = [[NSImage alloc] initWithData:data];
            if (image) {
                [self addImage:image toPage:drawPage at:location];
            }
        }

        return YES;
    } else if ([[pasteboard types] indexOfObject:NSPasteboardTypeFileURL] != NSNotFound) {
        NSArray *filenames = [pasteboard propertyListForType:NSPasteboardTypeFileURL];
        NSString *filename;
        NSInteger x;
        NSImage *image;
        BOOL linking = [sender draggingSourceOperationMask] == NSDragOperationLink;

        for (x = 0; x < (const NSInteger)[filenames count]; x++) {
            filename = [filenames objectAtIndex:x];
            if (linking) {
                [self addImageWithFilename:filename toPage:drawPage at:location];
            } else {
                image = [[NSImage alloc] initWithContentsOfFile:filename];
                if (image) {
                    [self addImage:image toPage:drawPage at:location];
                    location.x += 10.0;
                    location.y += [drawPage isFlipped] ? 10.0 : -10.0;
                }
            }
        }

        return YES;
    }

    return NO;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender inView:(DrawPage *)drawPage {
    NSUInteger sourceDragMask = [sender draggingSourceOperationMask];

    if (_dragSourceType == NSPasteboardTypeFileURL) {
        if (sourceDragMask & NSDragOperationCopy) return YES;
        else if (sourceDragMask & NSDragOperationLink) return YES;
    } else {
        if (sourceDragMask & NSDragOperationCopy) return YES;
    }

    return NO;
}

@end
