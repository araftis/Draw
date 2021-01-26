//
//  DrawSelectionActions.h
//  Draw
//
//  Created by Alex Raftis on 7/7/11.
//  Copyright 2011 Apple, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DrawSelectionActions : NSObject <NSMenuItemValidation>

+ (id)sharedInstance;

- (void)activate;
- (void)deactivate;

- (void)flipVertical:(id)sender;
- (void)flipHorizontal:(id)sender;
- (void)makeSquare:(id)sender;
- (void)snapToGrid:(id)sender;

@end

NS_ASSUME_NONNULL_END
