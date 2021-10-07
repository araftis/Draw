/*
DrawToolSet.h
Draw

Copyright © 2021, AJ Raftis and AJRFoundation authors
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this 
  list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, 
  this list of conditions and the following disclaimer in the documentation 
  and/or other materials provided with the distribution.
* Neither the name of Draw nor the names of its contributors may be 
  used to endorse or promote products derived from this software without 
  specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL AJ RAFTIS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class DrawDocument, DrawEvent, DrawTool, DrawToolAccessory;

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
@property (nonatomic,readonly,nullable) NSString *activationKey;
@property (class,nonatomic,readonly) DrawToolSet *globalToolSet;
@property (nonatomic,strong) DrawTool *currentTool;
@property (nonatomic,readonly) NSArray<DrawToolAccessory *> *accessories;

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
