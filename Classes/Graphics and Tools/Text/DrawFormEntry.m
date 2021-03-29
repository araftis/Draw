
#import "DrawFormEntry.h"

#import "DrawFunctions.h"

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

@implementation DrawFormEntry

- (void)setupTextView:(NSTextView *)textView {
    [super setupTextView:textView];

    [textView setRichText:NO];
    [textView setImportsGraphics:NO];
}

- (DrawGraphicCompletionBlock)drawPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    DrawGraphicCompletionBlock completionBlock = [super drawPath:path withPriority:priority];

    [[NSColor lightGrayColor] set];
    [path stroke];

    return completionBlock;
}

@end
