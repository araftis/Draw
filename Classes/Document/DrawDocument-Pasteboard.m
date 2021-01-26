/* DrawView-Pasteboard.m created by alex on Wed 21-Oct-1998 */

#import "DrawDocument.h"

#import "DrawDocumentStorage.h"
#import "DrawGraphic.h"
#import "DrawPage.h"
#import "NSPasteboard-DrawExtensions.h"

NSString * const DrawGraphicPboardType = @"DrawGraphicPboardType";

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

        [pasteboard declareTypes:[NSArray arrayWithObjects:DrawGraphicPboardType, @"com.adobe.encapsulated-postscript", nil] owner:nil];
        _useShallowEncode = YES;
        [pasteboard setDrawGraphics:selection forType:DrawGraphicPboardType];
        [pasteboard setDrawGraphics:selection forType:@"com.adobe.encapsulated-postscript"];
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

        [pasteboard declareTypes:[NSArray arrayWithObjects:DrawGraphicPboardType, @"com.adobe.encapsulated-postscript", nil] owner:nil];
        _useShallowEncode = YES;
        [pasteboard setDrawGraphics:selection forType:DrawGraphicPboardType];
        [pasteboard setDrawGraphics:selection forType:@"com.adobe.encapsulated-postscript"];
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
        NSArray *graphics;
        DrawGraphic *graphic;
        NSInteger x;
        NSPoint origin;
        DrawPage *page = [self page];

        graphics = [pasteboard drawGraphicsForType:DrawGraphicPboardType];

        if ([graphics count]) {
            for (x = 0; x < (const NSInteger)[graphics count]; x++) {
                graphic = [graphics objectAtIndex:x];
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
