/* DrawView-Event.m created by alex on Fri 06-Nov-1998 */

#import "DrawDocument.h"

#import "DrawEvent.h"
#import "DrawFunctions.h"
#import "DrawGraphic.h"
#import "DrawInspector.h"
#import "DrawPage.h"

@implementation DrawDocument (Event)

- (BOOL)dragSelection:(NSArray *)selection withLastHitGraphic:(DrawGraphic *)graphic fromEvent:(DrawEvent *)event {
    DrawPage *actualView = [[selection lastObject] page];
    NSSize offset;
    NSPasteboard *pasteboard;
    NSData *data;
    NSImage *image;
    NSPoint where;
    NSRect bounds;
    NSInteger x;

    for (x = 0; x < (const NSInteger)[selection count]; x++) {
        if ([[selection objectAtIndex:x] editing]) return NO;
    }

    data = [[event document] PDFForGraphics:[[event document] sortedSelection]];

    if (data) {
        image = [[NSImage alloc] initWithData:data];

        pasteboard = [NSPasteboard pasteboardWithName:NSPasteboardNameDrag];
        [pasteboard declareTypes:[NSArray arrayWithObjects:@"com.adobe.encapsulated-postscript", DrawGraphicPboardType, nil] owner:actualView];
        [pasteboard setData:data forType:@"com.adobe.encapsulated-postscript"];
        [pasteboard setData:[NSKeyedArchiver ajr_archivedObject:selection error:NULL] forType:DrawGraphicPboardType];

        where = [event locationOnPage];
        bounds = DrawBoundsForGraphics(selection);
        where.x -= (where.x - bounds.origin.x);
        where.y -= (where.y - bounds.origin.y);
        offset = (NSSize){0.0, 0.0};

        [actualView dragImage:image at:where offset:offset event:[event event] pasteboard:pasteboard source:actualView slideBack:YES];

        return YES;
    }

    return NO;
}

- (NSUInteger)draggingSourceOperationMaskForLocal:(BOOL)flag {
    return NSDragOperationCopy;
}

@end
