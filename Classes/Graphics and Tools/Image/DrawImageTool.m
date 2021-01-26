/* DrawImageTool.m created by alex on Wed 28-Oct-1998 */

#import "DrawImageTool.h"

#import "DrawImage.h"
#import "DrawPage.h"
#import "DrawRectangle.h"
#import "DrawDocument.h"

#import <AJRInterface/AJRInterface.h>

@implementation DrawImageTool {
    NSString *_dragSourceType;
 }

- (id)init {
    self = [super init];

    [DrawDocument registerTool:self forDraggedTypes:@[NSPasteboardTypeTIFF, @"com.adobe.encapsulated-postscript", NSPasteboardTypeFileURL]];

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
    if ([[pasteboard types] indexOfObject:@"com.adobe.encapsulated-postscript"] != NSNotFound) {
        if (sourceDragMask & NSDragOperationCopy) {
            _dragSourceType = @"com.adobe.encapsulated-postscript";
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

    if ([[pasteboard types] indexOfObject:@"com.adobe.encapsulated-postscript"] != NSNotFound) {
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
