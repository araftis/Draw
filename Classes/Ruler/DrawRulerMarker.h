//
//  DrawRulerMarker.h
//  Draw
//
//  Created by Alex Raftis on 7/26/11.
//  Copyright (c) 2011 Apple, Inc. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface DrawRulerMarker : NSRulerMarker {
    NSWindow *_measureWindow;
    BOOL _isRemoving;
}

@end
