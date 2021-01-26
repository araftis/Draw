//
//  DrawFillRibbonInspector.h
//  Draw
//
//  Created by Alex Raftis on 8/13/11.
//  Copyright (c) 2011 Apple, Inc. All rights reserved.
//

#import <Draw/DrawAspectInspector.h>

extern NSString * const DrawFillRibbonInspectorID;

@class AJRColorWell;

@interface DrawFillRibbonInspector : DrawAspectInspector
{
	AJRColorWell     *_colorWell;
}

@property (strong) IBOutlet NSColorWell *colorWell;

- (IBAction)selectColor:(id)sender;

@end
