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

#pragma mark - Live Cycle

/** Once this is called as the document gets loaded into memory. When this is called, self.document is guaranteed to return a non-nil value. */
- (void)documentDidLoad:(DrawDocument *)document;
/** Sent just prior to the document closing. This gives you a chance to stop observing things on the document. At this point, self.document may or may not be valid. This is necessary, because observations often create retain cycles with the document, so breaking those observations in an override of this method will allow the document to be released. */
- (void)documentWillClose:(DrawDocument *)document;

@end

NS_ASSUME_NONNULL_END
