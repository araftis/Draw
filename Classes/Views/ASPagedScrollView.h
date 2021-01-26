//
//  ASPagedScrollView.h
//  ASInterface
//
//  Created by Alex Raftis on 6/22/11.
//  Copyright 2011 Apple, Inc. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface ASPagedScrollView : NSScrollView
{
	NSPopUpButton	*_viewPopUp;
	NSTextField		*_pagesLabel;
	NSGradient		*_controlsGradient;
	NSColor			*_controlsDividerColor;
	NSColor			*_controlsTopDividerColor;
}

@end
