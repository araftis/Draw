//
//  DrawLinkRibbonInspector.h
//  Draw
//
//  Created by Alex Raftis on 9/15/11.
//  Copyright (c) 2011 Apple, Inc. All rights reserved.
//

#import <Draw/DrawInspector.h>

extern NSString * const DrawLinkRibbonInspectorID;

@interface DrawLinkRibbonInspector : DrawInspector

@property (nonatomic,strong) IBOutlet NSPopUpButton *sourcePopUp;
@property (nonatomic,strong) IBOutlet NSPopUpButton *destinationPopUp;

@end
