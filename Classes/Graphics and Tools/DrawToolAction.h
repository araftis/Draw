//
//  DrawToolAction.h
//  Draw
//
//  Created by Alex Raftis on 6/24/11.
//  Copyright 2011 Apple, Inc. All rights reserved.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DrawTool;

@interface DrawToolAction : NSObject

+ (id)toolActionWithTool:(DrawTool *)tool title:(NSString *)title icon:(NSImage *)icon cursor:(NSCursor *)cursor tag:(NSInteger)tag;
+ (id)toolActionWithTool:(DrawTool *)tool title:(NSString *)title icon:(NSImage *)icon cursor:(NSCursor *)cursor tag:(NSInteger)tag graphicClass:(nullable Class)graphicClass;
- (id)initWithTool:(DrawTool *)tool title:(NSString *)title icon:(NSImage *)icon cursor:(NSCursor *)cursor tag:(NSInteger)tag;
- (id)initWithTool:(DrawTool *)tool title:(NSString *)title icon:(NSImage *)icon cursor:(NSCursor *)cursor tag:(NSInteger)tag graphicClass:(nullable Class)graphicClass;

@property (nonatomic,strong) DrawTool *tool;
@property (nonatomic,strong) NSString *title;
@property (nonatomic,strong) NSImage *icon;
@property (nonatomic,assign) NSInteger tag;
@property (nonatomic,strong) NSCursor *cursor;
@property (nullable,nonatomic,strong) Class graphicClass;

@end

NS_ASSUME_NONNULL_END
