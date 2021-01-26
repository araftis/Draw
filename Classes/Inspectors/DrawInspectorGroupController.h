//
//  DrawInspectorGroupController.h
//  Draw
//
//  Created by Alex Raftis on 10/9/11.
//  Copyright (c) 2011 Apple, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DrawDocument, DrawInspectorController, DrawInspectorGroup;

#pragma mark Inspector Groups

extern NSString * const DrawInspectorGroupDocument;
extern NSString * const DrawInspectorGroupLeft;
extern NSString * const DrawInspectorGroupRight;
extern NSString * const DrawInspectorGroupStyles;

@interface DrawInspectorGroupController : NSObject

#pragma mark - Factory

+ (void)registerControllerClass:(Class)class forName:(NSString *)name;
+ (Class)controllerClassForName:(NSString *)name;

+ (void)registerControllerClass:(Class)class inGroup:(NSString *)name;
+ (NSSet *)controllerClassesInGroup:(NSString *)name;

+ (void)registerInspectorClass:(Class)inspectorClass forName:(NSString *)name;
+ (NSSet *)inspectorClassesForClass:(Class)class forName:(NSString *)name;

#pragma mark - Creation

- (id)initWithDocument:(DrawDocument *)document;

#pragma mark Properties

@property (nonatomic,weak) DrawDocument *document;

#pragma mark - Inspectors

- (DrawInspectorController *)inspectorControllerForName:(NSString *)name;
- (DrawInspectorGroup *)inspectorGroupForName:(NSString *)name;

#pragma mark - Selection Change

- (void)updateInspectors;

@end
