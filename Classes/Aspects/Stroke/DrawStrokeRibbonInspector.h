//
//  DrawStrokeRibbonInspector.h
//  Draw
//
//  Created by Alex Raftis on 8/12/11.
//  Copyright (c) 2011 Apple, Inc. All rights reserved.
//

#import <Draw/DrawAspectInspector.h>

extern NSString * const DrawStrokeRibbonInspectorID;

extern DrawAspectCreationCallback DrawStrokeCreationBlock;

@class AJRColorWell;

@interface DrawStrokeRibbonInspector : DrawAspectInspector <NSComboBoxDataSource>

@property (nonatomic,weak) IBOutlet NSPopUpButton *strokePopUp;
@property (nonatomic,weak) IBOutlet AJRColorWell *colorWell;
@property (nonatomic,weak) IBOutlet NSComboBox *widthCombo;

- (IBAction)selectStrokeStyle:(id)sender;
- (IBAction)selectWidth:(id)sender;
- (IBAction)selectColor:(id)sender;

@end
