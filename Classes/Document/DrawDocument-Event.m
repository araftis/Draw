/*
DrawDocument-Event.m
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
