/*
DrawText.m
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

#import "DrawText.h"

#import "DrawEvent.h"
#import "DrawFunctions.h"
#import "DrawPage.h"
#import "DrawTextContainer.h"
#import "DrawTextView.h"
#import "DrawDocument.h"

#import <AJRFoundation/AJRFoundation.h>
#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

NSString * const DrawTextIdentifier = @"text";

#if !defined (UseDrawTextContainer)
#define DrawTextContainer NSTextContainer
@interface NSTextContainer (Extensions)
- (void)setGraphic:(DrawGraphic *)graphic;
- (void)graphicDidChangeShape:(DrawGraphic *)graphic;
@end
@implementation NSTextContainer (Extensions)
- (void)setGraphic:(DrawGraphic *)graphic { }
- (void)graphicDidChangeShape:(DrawGraphic *)graphic { }
@end
#endif

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

- (void)prepareTextInLayoutManager {
    NSLayoutManager *layoutManager = [self layoutManager];
    NSRange range = [layoutManager glyphRangeForTextContainer:[self textContainer]];
    [layoutManager ensureLayoutForGlyphRange:range];
}

- (DrawGraphicCompletionBlock)drawPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
    if (!_editing) {
        NSLayoutManager *layoutManager = self.layoutManager;
        NSRect frame = self.graphic.frame;
        NSRange range = [layoutManager glyphRangeForTextContainer:self.textContainer];
        
        [layoutManager drawBackgroundForGlyphRange:range atPoint:frame.origin];
        [layoutManager drawGlyphsForGlyphRange:range atPoint:frame.origin];
    }
	
	return NULL;
}

- (void)setAttributedString:(NSAttributedString *)string {
    [self.graphic.document registerUndoWithTarget:self selector:@selector(setAttributedString:) object:[_textStorage copy]];
    [_textStorage setAttributedString:string];
    [self.graphic setNeedsDisplay];
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
        [self.graphic setNeedsDisplay];
    }
}

- (NSLayoutManager *)layoutManager {
    return [[_textStorage layoutManagers] lastObject];
}

- (DrawTextView *)textView {
    return (DrawTextView *)[(NSTextContainer *)[[[[_textStorage layoutManagers] lastObject] textContainers] lastObject] textView];
}

- (DrawTextContainer *)textContainer {
    return AJRObjectIfKindOfClass(_textStorage.layoutManagers.lastObject.textContainers.lastObject, DrawTextContainer);
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

- (void)graphicDidAddToDocument:(DrawDocument *)aView {
    [self updateMaxSize];
}

- (void)graphicWillRemoveFromDocument:(DrawDocument *)aView {
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

- (BOOL)beginEditingFromEvent:(DrawEvent *)event {
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
    point = event.locationOnPage;
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

#pragma mark - DrawAspect

+ (DrawAspect *)defaultAspectForGraphic:(DrawGraphic *)graphic {
    return [[self alloc] initWithGraphic:graphic];
}

#pragma mark - NSCopying

- (NSTextStorage *)_createTextStorageWithString:(NSAttributedString *)string {
    return [self _finishInitializingTextStorage:[[NSTextStorage alloc] init] with:string];
}

- (NSTextStorage *)_finishInitializingTextStorage:(NSTextStorage *)storage with:(NSAttributedString *)string {
    [storage setAttributedString:string];
    NSLayoutManager *manager = [[NSLayoutManager alloc] init];
    [storage addLayoutManager:manager];
    DrawTextContainer *container = [[DrawTextContainer alloc] initWithContainerSize:(NSSize){100, 100}];
    [container setLineFragmentPadding:_lineFragmentPadding];
    [container setHeightTracksTextView:YES];
    [container setWidthTracksTextView:YES];
    [manager addTextContainer:container];
    
    return storage;
}

- (id)copyWithZone:(NSZone *)zone {
    DrawText *new = [super copyWithZone:zone];
    
    // NOTE: Apparently copying an NSTextStorage produces an attributed string, not a text storage.
    new->_textStorage = [self _createTextStorageWithString:[_textStorage copy]];
    new->_editing = _editing;
    new->_lineFragmentPadding = _lineFragmentPadding;
    
    return new;
}

#pragma mark - AJRXMLArchiving

+ (NSString *)ajr_nameForXMLArchiving {
    return @"text";
}

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super decodeWithXMLCoder:coder];

    [coder decodeObjectForKey:@"text" setter:^(id  _Nonnull object) {
        // Make sure the input is actually an attributed string, since it might not be if someone fiddled with the document.
        NSAttributedString *string = AJRObjectIfKindOfClass(object, NSAttributedString);
        if (string != nil) {
            self->_textStorage = [self _createTextStorageWithString:string];
        } else {
            self->_textStorage = [self _createTextStorageWithString:[[NSAttributedString alloc] init]];
        }
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
