/* DrawText.m created by alex on Fri 30-Oct-1998 */

#import "DrawText.h"

#import "DrawFunctions.h"
#import "DrawPage.h"
#import "DrawTextContainer.h"
#import "DrawTextView.h"
#import "DrawDocument.h"

#import <AJRFoundation/AJRFoundation.h>
#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

NSString * const DrawTextIdentifier = @"text";

//#if !defined (UseDrawTextContainer)
//#define DrawTextContainer NSTextContainer
//@interface NSTextContainer (Extensions)
//- (void)setGraphic:(DrawGraphic *)graphic;
//- (void)graphicDidChangeShape:(DrawGraphic *)graphic;
//@end
//@implementation NSTextContainer (Extensions)
//- (void)setGraphic:(DrawGraphic *)graphic { }
//- (void)graphicDidChangeShape:(DrawGraphic *)graphic { }
//@end
//#endif

@implementation DrawText {
    NSTextStorage *_textStorage;

    BOOL _editing;
    BOOL _ignoreGraphicShapeChange;
}

#pragma mark - Creation

- (void)initializeFromString:(NSAttributedString *)string {
    NSLayoutManager *manager;
    DrawTextContainer *container;
    DrawTextView *textView;
    NSSize size;
    
    _textStorage = [[NSTextStorage alloc] init];
    
    if (string) {
        [self setAttributedString:string];
    }
    
    manager = [[NSLayoutManager alloc] init];
    [_textStorage addLayoutManager:manager];
    
    if (self.graphic) {
        size = [self.graphic frame].size;
        if (size.width < 15.0) size.width = 15.0;
        if (size.height < 15.0) size.height = 15.0;
    } else {
        size = (NSSize){15.0, 15.0};
    }
    _lineFragmentPadding = 2.0;
    container = [[DrawTextContainer alloc] initWithContainerSize:size];
    [container setLineFragmentPadding:_lineFragmentPadding];
    [manager addTextContainer:container];
    [container setGraphic:self.graphic];
    [container setHeightTracksTextView:YES];
    [container setWidthTracksTextView:YES];
    
    textView = [[DrawTextView alloc] initWithFrame:(NSRect){{0.0, 0.0}, size} textContainer:container];
    [textView setDrawsBackground:NO];
    [textView setEditable:NO];
    [textView setSelectable:NO];
    [textView setHorizontallyResizable:NO];
    [textView setVerticallyResizable:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewFrameDidChange:) name:NSViewFrameDidChangeNotification object:textView];
}

- (id)initWithGraphic:(DrawGraphic *)aGraphic {
    if ((self = [super initWithGraphic:aGraphic])) {
        [self initializeFromString:nil];
    }
    return self;
}

- (id)initWithGraphic:(DrawGraphic *)aGraphic text:(NSAttributedString *)someText {
    if ((self = [super initWithGraphic:aGraphic])) {
        [self initializeFromString:someText];
    }
    return self;
}


- (DrawGraphicCompletionBlock)drawPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    if (!_editing) {
        NSLayoutManager *layoutManager = [self layoutManager];
        NSRect frame = [self.graphic frame];
        NSRange range = [layoutManager glyphRangeForTextContainer:[self textContainer]];
        
        [layoutManager drawBackgroundForGlyphRange:range atPoint:frame.origin];
        [layoutManager drawGlyphsForGlyphRange:range atPoint:frame.origin];

//        [[NSColor.systemRedColor colorWithAlphaComponent:0.5] set];
//        NSBezierPath *newPath = [NSBezierPath bezierPathWithRect:self.graphic.bounds];
//        [newPath appendBezierPath:(NSBezierPath *)path];
//        [newPath setWindingRule:NSWindingRuleEvenOdd];
//        [newPath fill];
    }
	
	return NULL;
}

- (void)setAttributedString:(NSAttributedString *)string {
    [[self.graphic document] registerUndoWithTarget:self selector:@selector(setAttributedString:) object:string];
    [_textStorage setAttributedString:string];
}

- (NSAttributedString *)attributedString {
    return _textStorage;
}

- (void)setLineFragmentPadding:(CGFloat)aPadding {
    if (aPadding != _lineFragmentPadding) {
        NSInteger x;
        NSArray *textContainers = [[[_textStorage layoutManagers] lastObject] textContainers];
        NSTextContainer	*container;
        
        [[[self.graphic document] prepareWithInvocationTarget:self] setLineFragmentPadding:_lineFragmentPadding];
        _lineFragmentPadding = aPadding;
        
        for (x = 0; x < (const NSInteger)[textContainers count]; x++) {
            container = [textContainers objectAtIndex:x];
            [container setLineFragmentPadding:_lineFragmentPadding];
        }
    }
}

- (NSLayoutManager *)layoutManager {
    return [[_textStorage layoutManagers] lastObject];
}

- (DrawTextView *)textView {
    return (DrawTextView *)[(NSTextContainer *)[[[[_textStorage layoutManagers] lastObject] textContainers] lastObject] textView];
}

- (DrawTextContainer *)textContainer {
    return AJRObjectIfKindOfClass([[[[_textStorage layoutManagers] lastObject] textContainers] lastObject], DrawTextContainer);
}

- (void)setGraphic:(DrawGraphic *)graphic {
    if (self.graphic != graphic) {
        [super setGraphic:graphic];
        [[self textContainer] setGraphic:self.graphic];
    }
}

- (void)updateMaxSize {
    NSPrintInfo	*printInfo = [[self.graphic document] printInfo];
    NSSize paperSize = [printInfo paperSize];
    NSPoint origin = [self.graphic frame].origin;
    NSTextView *textView = [self textView];
    NSSize maxSize;
    
    if (!printInfo) return;
    
    maxSize.width = paperSize.width - [printInfo rightMargin] - origin.x;
    maxSize.height = paperSize.height - [printInfo bottomMargin] - origin.y;
    AJRLogDebug(@"maxSize = %@\n", NSStringFromSize(maxSize));
    [textView setMaxSize:maxSize];
}

- (void)graphicDidAddToView:(DrawDocument *)aView {
    [self updateMaxSize];
}

- (void)graphicWillRemoveFromView:(DrawDocument *)aView {
}

- (void)graphicDidChangeShape:(DrawGraphic *)aGraphic {
    if (!_ignoreGraphicShapeChange) {
        DrawTextView *textView = [self textView];
        DrawTextContainer *textContainer = [self textContainer];
        NSRect textFrame, graphicFrame;

        textFrame = [textView frame];
        graphicFrame = [self.graphic frame];
        if (!NSEqualRects(textFrame, graphicFrame)) {
            [textView setFrame:graphicFrame];
            //[textContainer graphicDidChangeShape:aGraphic];
        }
        
        if (![textContainer isSimpleRectangularTextContainer]) {
            [textContainer graphicDidChangeShape:aGraphic];
        }
        if (!NSEqualSizes(textFrame.size, graphicFrame.size)) {
            NSSize size = graphicFrame.size;
            if (size.width < 15.0) size.width = 15.0;
            if (size.height < 15.0) size.height = 15.0;
            [textContainer setContainerSize:size];
        }
        [self updateMaxSize];
    }
}

- (BOOL)aspectAcceptsEdit {
    return YES;
}

- (void)setupTextView:(NSTextView *)textView {
    NSRect frame = [self.graphic frame];
    NSRect bounds = frame;
    NSTextContainer	*container = [self textContainer];
    
    [textView setFrame:frame];
    [textView setBounds:bounds];
    [textView setEditable:YES];
    [textView setSelectable:YES];
    [textView setHorizontallyResizable:YES];
    [textView setVerticallyResizable:YES];
    [container setHeightTracksTextView:YES];
    [container setWidthTracksTextView:YES];
    [self updateMaxSize];
    [textView sizeToFit];
}

- (BOOL)beginEditingFromEvent:(NSEvent *)anEvent {
    DrawTextView *textView = [self textView];
    NSLayoutManager *layoutManager = [self layoutManager];
    NSPoint point, origin;
    CGFloat distance;
    NSRange range = {0, 0};
    NSRect frame, bounds;
    
    frame = [self.graphic frame];
    bounds = (NSRect){{0.0, 0.0}, frame.size};
    [self setupTextView:textView];
    [[self.graphic page] addSubview:textView];
    [[textView window] makeFirstResponder:textView];
    origin = [self.graphic frame].origin;
    point = [[self.graphic page] convertPoint:[anEvent locationInWindow] fromView:nil];
    point.x -= origin.x;
    point.y -= origin.y;
    range.location = [layoutManager glyphIndexForPoint:point inTextContainer:[self textContainer] fractionOfDistanceThroughGlyph:&distance];
    if (distance > 0.5) {
        range.location++;
    }
    [textView setSelectedRange:range];
    
    _editing = YES;
    
    return YES;
}

- (void)endEditing {
    DrawTextView *textView = self.textView;
    
    if (_editing) {
        textView.editable = NO;
        textView.selectable = NO;
        textView.horizontallyResizable = NO;
        textView.verticallyResizable = NO;
        [textView removeFromSuperview];
        
        _editing = NO;
        
        [NSNotificationCenter.defaultCenter postNotificationName:DrawObjectDidResignRulerNotification object:self.graphic.document];
    }
}

- (BOOL)isPoint:(NSPoint)aPoint inPath:(AJRBezierPath *)path {
    return [path isHitByPoint:aPoint];
}

- (void)textViewFrameDidChange:(NSNotification *)notification {
    //NSLog(@"Change\n");
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
    DrawText *new = [super copyWithZone:zone];
    
    new->_textStorage = [_textStorage copyWithZone:zone];
    new->_editing = _editing;
    new->_lineFragmentPadding = _lineFragmentPadding;
    
    return new;
}

#pragma mark NSCoding

+ (NSString *)ajr_nameForXMLArchiving {
    return @"text";
}

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super decodeWithXMLCoder:coder];

    [coder decodeObjectForKey:@"text" setter:^(id  _Nonnull object) {
        self->_textStorage = [[NSTextStorage alloc] init];
        [self->_textStorage setAttributedString:object];
        [self->_textStorage addLayoutManager:[[NSLayoutManager alloc] init]];
    }];
    [coder decodeBoolForKey:@"editing" setter:^(BOOL value) {
        self->_editing = value;
    }];
    [coder decodeFloatForKey:@"lineFragmentPadding" setter:^(float value) {
        self->_lineFragmentPadding = value;
    }];
}

- (id)finalizeXMLDecodingWithError:(NSError * _Nullable __autoreleasing *)error {
    CGFloat save = _lineFragmentPadding;

    [self initializeFromString:_textStorage];
    [self setLineFragmentPadding:0];
    [self setLineFragmentPadding:save];

    return self;
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)encoder {
    [super encodeWithXMLCoder:encoder];
    
    [encoder encodeObject:_textStorage forKey:@"text"];
	[encoder encodeBool:_editing forKey:@"editing"];
    [encoder encodeFloat:_lineFragmentPadding forKey:@"lineFragmentPadding"];
}

@end
