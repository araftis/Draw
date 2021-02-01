//
//  DrawToolSet.h
//  Draw
//
//  Created by Alex Raftis on 6/24/11.
//  Copyright 2011 Apple, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class DrawDocument, DrawEvent, DrawTool;

typedef NSString *DrawToolSetId NS_EXTENSIBLE_STRING_ENUM;

@interface DrawToolSet : NSObject

#pragma mark - Factory

+ (void)registerToolSet:(Class)toolSetClass properties:(NSDictionary<NSString *, id> *)properties;
+ (void)registerTool:(Class)toolClass properties:(NSDictionary<NSString *, id> *)properties;

@property (class,nonatomic,readonly) NSArray<DrawToolSetId> *toolSetIdentifiers;
@property (class,nonatomic,readonly) NSArray<DrawToolSet *> *toolSets;
+ (DrawToolSet *)toolSetForClass:(Class)toolsetClass;
+ (nullable DrawToolSet *)toolSetForIdentifier:(DrawToolSetId)identifier;

#pragma mark - Creation

- (id)init;

#pragma mark - Properties

@property (nonatomic,readonly) NSString *currentToolPreferenceKey;
@property (nonatomic,readonly) NSString *name;
@property (nonatomic,readonly) DrawToolSetId identifier;
@property (nullable,nonatomic,readonly) NSImage *icon;
@property (nonatomic,readonly) BOOL isGlobal;
@property (class,nonatomic,readonly) DrawToolSet *globalToolSet;
@property (nonatomic,strong) DrawTool *currentTool;

#pragma mark - Tools

- (void)registerToolClass:(Class)toolClass properties:(NSDictionary<NSString *, id> *)properties;

- (NSArray<DrawTool *> *)tools;
- (nullable DrawTool *)toolForIdentifier:(DrawToolSetId)identifier;

#pragma mark - Activation

- (BOOL)toolSetShouldActivateForDocument:(DrawDocument *)document;
- (BOOL)toolSetShouldDeactivateForDocument:(DrawDocument *)document;

#pragma mark - Canvas Menus

- (nullable NSMenu *)menuForEvent:(DrawEvent *)event;

#pragma mark - Document Querries

/*!
 Sent by the document when it otherwise has no selection to inspect itself. Your toolset may return a "generic" object that it wished to have inspected. For example, the DrawGraphicsToolSet returns the document's templateGraphic, because the template graphic is used for the initial aspect settings on new graphics. By returning the template graphic, the user can change things like fill or stroke settings prior to actually creating a new graphic. 
 */
- (NSSet *)selectionForInspectionForDocument:(DrawDocument *)document;

@end

NS_ASSUME_NONNULL_END
