
#import <AppKit/AppKit.h>

@interface DrawRulerMarker : NSRulerMarker {
    NSWindow *_measureWindow;
    BOOL _isRemoving;
}

@end
