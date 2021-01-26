//
//  DrawViewController.h
//  Draw
//
//  Created by AJ Raftis on 1/10/21.
//  Copyright © 2021 Apple, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DrawDocument, DrawLayerViewController, DrawInspectorGroupsController;

NS_ASSUME_NONNULL_BEGIN

@interface DrawViewController : NSViewController

@property (nullable,nonatomic,readonly) DrawDocument *document;
@property (nullable,nonatomic,readonly) DrawLayerViewController *layerViewController;
@property (nullable,nonatomic,readonly) DrawInspectorGroupsController *inspectorGroupsViewController;

@end

NS_ASSUME_NONNULL_END
