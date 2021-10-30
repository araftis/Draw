/*
DrawDocument-Pasteboard.m
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

#import "DrawDocumentStorage.h"
#import "DrawGraphic.h"
#import "DrawPage.h"
#import "NSPasteboard-DrawExtensions.h"

NSString * const DrawGraphicPboardType = @"com.ajr.draw.graphic";

@interface DrawDocument (Private)

- (void)_addGraphic:(DrawGraphic *)graphic;

@end

@implementation DrawDocument (Pasteboard)

- (void)_resetCopyParameters {
    CGFloat spacing = _storage.gridSpacing;

    while (spacing < 5.0) {
        spacing += _storage.gridSpacing;
    }

    _storage.copyDelta = (NSPoint){spacing, -spacing};
    _storage.copyOffset = (NSSize){spacing, -spacing};
}

- (void)copy:(id)sender {
    if ([_storage.selection count]) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        NSArray *selection = [self sortedSelection];

        [pasteboard declareTypes:[NSArray arrayWithObjects:DrawGraphicPboardType, NSPasteboardTypePDF, nil] owner:nil];
        _useShallowEncode = YES;
        [pasteboard setDrawGraphics:selection forType:DrawGraphicPboardType];
        [pasteboard setDrawGraphics:selection forType:NSPasteboardTypePDF];
        _useShallowEncode = NO;

        [self _resetCopyParameters];
    } else {
        NSBeep();
    }
}

- (void)cut:(id)sender {
    if ([_storage.selection count]) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        NSArray *selection = [self sortedSelection];

        [pasteboard declareTypes:[NSArray arrayWithObjects:DrawGraphicPboardType, NSPasteboardTypePDF, nil] owner:nil];
        _useShallowEncode = YES;
        [pasteboard setDrawGraphics:selection forType:DrawGraphicPboardType];
        [pasteboard setDrawGraphics:selection forType:NSPasteboardTypePDF];
        _useShallowEncode = NO;

        [self deleteSelection];

        [self _resetCopyParameters];
    } else {
        NSBeep();
    }
}

- (void)paste:(id)sender {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSString *type;

    type = [pasteboard availableTypeFromArray:[NSArray arrayWithObjects:DrawGraphicPboardType, nil]];

    if ([type isEqualToString:DrawGraphicPboardType]) {
        NSArray<DrawGraphic *> *graphics;
        NSPoint origin;
        DrawPage *page = self.page;

        graphics = [pasteboard drawGraphicsForType:DrawGraphicPboardType];

        if ([graphics count]) {
            for (DrawGraphic *graphic in graphics) {
                origin = [graphic frame].origin;
                origin.x += _storage.copyOffset.width;
                origin.y += _storage.copyOffset.height;
                [graphic setFrameOrigin:origin];
                [page addGraphic:graphic toLayer:[self layer]];
            }
            _storage.copyOffset = (NSSize){_storage.copyOffset.width + _storage.copyDelta.x, _storage.copyOffset.height + _storage.copyDelta.y};

            [self clearSelection];
            [self addGraphicsToSelection:graphics];
        }
    }
}

@end
