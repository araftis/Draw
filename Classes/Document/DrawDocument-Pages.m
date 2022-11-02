/*
 DrawDocument-Pages.m
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

#import "DrawDocumentStorage.h"
#import "DrawFunctions.h"
#import "DrawPage.h"
#import "DrawLayer.h"

#import <AJRInterface/AJRInterface.h>
#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

@implementation DrawDocument (Pages)

// TODO: Candidate for deletion
//- (BOOL)knowsPageRange:(NSRange *)range {
//    range->location = _storage.startingPageNumber;
//    range->length = [_storage.pages count];
//
//    return YES;
//}
//
//- (NSRect)rectForPage:(NSInteger)aPageNumber {
//    if (_storage.pageNumber <= [_storage.pages count]) {
//        if (self.isPrinting) {
//            _storage.pageNumber = aPageNumber;
//        }
//    }
//
//    return (NSRect){{0.0, 0.0}, [[self printInfo] paperSize]};
//}

- (NSView *)viewForPage:(NSInteger)aPageNumber {
    return [_storage.pages objectAtIndex:aPageNumber - _storage.startingPageNumber];
}

- (NSView *)viewForPage {
    return [self page];
}

- (NSArray *)pages {
    return _storage.pages;
}

- (void)setPage:(DrawPage *)page {
    if ([self page] != page) {
        NSScrollView *scrollView = [self.pagedView enclosingScrollView];

        _storage.pageNumber = [_storage.pages indexOfObjectIdenticalTo:page] + _storage.startingPageNumber;

        [[scrollView horizontalRulerView] setClientView:page];
        [[scrollView verticalRulerView] setClientView:page];
    }
}

- (DrawPage *)page {
    if ((_storage.pageNumber - 1 < 0) || (_storage.pageNumber - 1 > [_storage.pages count])) return nil;
    return [_storage.pages objectAtIndex:_storage.pageNumber - 1];
}

- (void)addPage:(id)sender {
    //DrawPage *page = [[DrawPage alloc] initWithDocument:self];
    NSView *page = [[NSView alloc] initWithFrame:(NSRect){NSZeroPoint, {1.0, 1.0}}];

    // TODO: Why am I not creating a DrawPage?
    [self willChangeValueForKey:@"pages"];
    if (_storage.pageNumber == [_storage.pages count]) {
        [_storage.pages addObject:(DrawPage *)page];
    } else {
        [_storage.pages insertObject:(DrawPage *)page atIndex:_storage.pageNumber];
    }
    [self didChangeValueForKey:@"pages"];
}

- (void)insertPage:(id)sender {
    DrawPage *page = [[DrawPage alloc] initWithDocument:self];
    
    [self willChangeValueForKey:@"pages"];
    [_storage.pages insertObject:page atIndex:_storage.pageNumber - 1];
    [self didChangeValueForKey:@"pages"];
}

- (void)appendPage:(id)sender {
    DrawPage *page = [[DrawPage alloc] initWithDocument:self];

    [self willChangeValueForKey:@"pages"];
    [_storage.pages addObject:page];
    [self didChangeValueForKey:@"pages"];
}

- (void)deletePage:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];

    [alert setMessageText:[NSString stringWithFormat:@"Are you sure you want to delete page %ld?", (long)_storage.pageNumber]];
    [alert addButtonWithTitle:@"No"];
    [alert addButtonWithTitle:@"Yes"];

    [alert beginSheetModalForWindow:[[self pagedView] window] completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertSecondButtonReturn) {
            [self willChangeValueForKey:@"pages"];
            [self->_storage.pages removeObjectAtIndex:self->_storage.pageNumber - 1];
            [self didChangeValueForKey:@"pages"];
        }
    }];
}

- (NSInteger)pageNumberForPage:(DrawPage *)page {
    NSInteger number = [_storage.pages indexOfObjectIdenticalTo:page];
    if (number != NSNotFound) return number + 1;
    return number;
}

- (void)printDocument:(id)sender {
    if (_isPrinting) {
        [super printDocument:sender];
    } else {
        NSInteger savedPageNumber = _storage.pageNumber;
        
        _isPrinting = YES;
        [[NSPrintOperation printOperationWithView:self.pagedView printInfo:self.printInfo] runOperation];
        _isPrinting = NO;
        _storage.pageNumber = savedPageNumber;
    }
}

#pragma mark - AJRPagedViewDataSource

- (NSUInteger)pageCountForPagedView:(AJRPagedView *)pagedView {
    return [_storage.pages count];
}

- (NSView *)pagedView:(AJRPagedView *)pagedView viewForPage:(NSInteger)pageNumber {
    return [_storage.pages objectAtIndex:pageNumber];
}

- (NSSize)pagedView:(AJRPagedView *)pagedView sizeForPage:(NSInteger)pageNumber {
    return [[self printInfo] paperSize];
}

- (NSColor *)pagedView:(AJRPagedView *)pagedView colorForPage:(NSInteger)pageNumber {
    return _storage.paperColor;
}

- (void)setPagesNeedDisplay:(BOOL)flag {
    NSIndexSet *pageIndexes = [self.pagedView visiblePageIndexes];
    NSUInteger index;
    
    index = [pageIndexes firstIndex];
    while (index != NSNotFound) {
        [[_storage.pages objectAtIndex:index] setNeedsDisplay:flag];
        index = [pageIndexes indexGreaterThanIndex:index];
    }
}

- (BOOL)_enumerateGraphicsInPage:(DrawPage *)page using:(void (^)(DrawGraphic *graphic, BOOL *stop))block {
    for (DrawLayer *layer in _storage.layers) {
        for (DrawGraphic *graphic in [page graphicsForLayer:layer]) {
            BOOL stop = NO;
            block(graphic, &stop);
            if (stop) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)enumerateGraphicsUsing:(void (^)(DrawGraphic *graphic, BOOL *stop))block {
    for (DrawPage *page in _storage.pages) {
        if ([self _enumerateGraphicsInPage:page using:block]) {
            return;
        }
    }
    if ([self _enumerateGraphicsInPage:_storage.masterPageOdd using:block]) {
        return;
    }
    if ([self _enumerateGraphicsInPage:_storage.masterPageEven using:block]) {
        return;
    }
}

@end
