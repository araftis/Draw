/* DrawView-Pages.m created by alex on Tue 06-Oct-1998 */

#import "DrawDocument.h"

#import "DrawDocumentStorage.h"
#import "DrawFunctions.h"
#import "DrawPage.h"
#import "DrawLayer.h"

#import <AJRInterface/AJRInterface.h>
#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

@implementation DrawDocument (Pages)

- (BOOL)knowsPageRange:(NSRange *)range {
    range->location = _storage.startingPageNumber;
    range->length = [_storage.pages count];
    
    return YES;
}

- (NSRect)rectForPage:(NSInteger)aPageNumber {
    if (_storage.pageNumber <= [_storage.pages count]) {
        if (![[NSGraphicsContext currentContext] isDrawingToScreen]) {
            _storage.pageNumber = aPageNumber;
        }
    }
    
    return (NSRect){{0.0, 0.0}, [[self printInfo] paperSize]};
}

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
        [[NSPrintOperation printOperationWithView:self.pagedView printInfo:[self printInfo]] runOperation];
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

@end
