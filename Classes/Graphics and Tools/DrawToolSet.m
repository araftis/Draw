/*
 DrawToolSet.m
 Draw

 Copyright © 2022, AJ Raftis and Draw authors
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

#import "DrawToolSet.h"

#import "DrawLogging.h"
#import "DrawTool.h"
#import <Draw/Draw-Swift.h>

#import <AJRFoundation/AJRFoundation.h>
#import <AJRInterface/AJRInterface.h>

@implementation DrawToolSet {
    NSImage *_icon;
    NSMutableDictionary<NSString *, DrawTool *> *_tools;
    NSMutableDictionary<NSString *, Class> *_toolClasses;
}

static NSMutableDictionary<NSString *, DrawToolSet *> *_toolSets = nil;
static NSMutableDictionary<Class, DrawToolSet *> *_toolSetsByClass = nil;

#pragma mark - Initialization

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _toolSets = [[NSMutableDictionary alloc] init];
        _toolSetsByClass = [[NSMutableDictionary alloc] init];
    });
}

#pragma mark - Factory

+ (void)registerToolSet:(Class)toolSetClass properties:(NSDictionary<NSString *, id> *)properties {
    if ([_toolSetsByClass objectForKey:toolSetClass] == Nil) {
        AJRLog(AJRLoggingDomainDrawPlugIn, AJRLogLevelDebug, @"Tool Set: %C", toolSetClass);
        DrawToolSet *toolSet = [[toolSetClass alloc] init];
        [_toolSets setObject:toolSet forKey:properties[@"id"]];
        [_toolSetsByClass setObject:toolSet forKey:(id)toolSetClass];
    }
}

+ (void)registerTool:(Class)toolClass properties:(NSDictionary<NSString *, id> *)properties {
    NSString *toolSetId = properties[@"toolset"];
    DrawToolSet *toolSet = _toolSets[toolSetId];

    if (toolSet == nil) {
        AJRLog(AJRLoggingDomainDrawPlugIn, AJRLogLevelError, @"No registered \"%@\" tool set, tool \"%@\" will not be loaded.", toolSetId);
    } else {
        [toolSet registerToolClass:toolClass properties:properties];
    }
}

+ (NSArray *)toolSetIdentifiers {
    return _toolSets.allKeys;
}

+ (NSArray<DrawToolSet *> *)toolSets {
    return _toolSets.allValues;
}

+ (DrawToolSet *)toolSetForClass:(Class)toolSetClass {
    return [_toolSetsByClass objectForKey:toolSetClass];
}

+ (DrawToolSet *)toolSetForIdentifier:(NSString *)identifier {
    return [_toolSets objectForKey:identifier];
}

#pragma mark - Creation

- (id)init {
    if ((self = [super init])) {
        _tools = [[NSMutableDictionary alloc] init];
        _toolClasses = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - Properties

- (NSString *)name {
    return [[[AJRPlugInManager sharedPlugInManager] extensionPointForName:@"draw-tool-set"] valueForProperty:@"name" onExtensionForClass:[self class]];
}

- (NSString *)identifier {
    return [[[AJRPlugInManager sharedPlugInManager] extensionPointForName:@"draw-tool-set"] valueForProperty:@"id" onExtensionForClass:[self class]];
}

- (NSImage *)icon {
    NSImage *image = [[[AJRPlugInManager sharedPlugInManager] extensionPointForName:@"draw-tool-set"] valueForProperty:@"icon" onExtensionForClass:[self class]];
    if (image == nil) {
        image = [AJRImages imageNamed:NSStringFromClass(self.class) forClass:self.class];
    }
    return image;
}

- (NSString *)activationKey {
    return [[[AJRPlugInManager sharedPlugInManager] extensionPointForName:@"draw-tool-set"] valueForProperty:@"activationKey" onExtensionForClass:[self class]];
}

- (BOOL)isGlobal {
    return [self.identifier isEqualToString:@"global"];
}

- (NSString *)currentToolPreferenceKey {
    return AJRFormat(@"%@.currentTool", [self identifier]);
}

+ (DrawToolSet *)globalToolSet {
    return [self toolSetForIdentifier:@"global"];
}

- (DrawTool *)currentTool {
    NSString *identifier = [[NSUserDefaults standardUserDefaults] stringForKey:self.currentToolPreferenceKey];
    if (identifier == nil) {
        return self.tools[0];
    }
    return [self toolForIdentifier:identifier] ?: self.tools[0];
}

- (void)setCurrentTool:(DrawTool *)currentTool {
    [[NSUserDefaults standardUserDefaults] setObject:currentTool.identifier forKey:self.currentToolPreferenceKey];
}

@synthesize accessories = _accessories;

- (NSArray<DrawToolAccessory *> *)accessories {
    if (_accessories == nil) {
        NSArray<NSDictionary *> *rawAccessories = [[AJRPlugInManager.sharedPlugInManager extensionPointForName:@"draw-tool-set"] valueForProperty:@"accessories" onExtensionForClass:self.class];
        NSMutableArray<DrawToolAccessory *> *build = [NSMutableArray array];
        for (NSDictionary *raw in rawAccessories) {
            NSUserInterfaceItemIdentifier identifier = raw[@"identifier"];
            NSString *title = raw[@"title"];
            NSImage *image = raw[@"image"];
            Class class = raw[@"controllerClass"];
            DrawToolAccessory *accessory = [[class alloc] initWithIdentifier:identifier title:title icon:image];
            [build addObjectIfNotNil:accessory];
        }
        _accessories = [build copy];
    }
    return _accessories;
}

#pragma mark - Tools

- (void)registerToolClass:(Class)toolClass properties:(NSDictionary<NSString *, id> *)properties {
    NSString *alias = properties[@"alias"];
    if (alias) {
        AJRLog(AJRLoggingDomainDrawPlugIn, AJRLogLevelDebug, @"Tool Alias: \"%@\" in %C", alias, self.class);
        NSArray<NSString *> *components = [alias componentsSeparatedByString:@":"];
        if (components.count == 2) {
            NSString *toolSetId = components[0];
            DrawToolSet *toolSet = [DrawToolSet toolSetForIdentifier:toolSetId];
            if (toolSet != nil) {
                NSString *toolId = components[1];
                DrawTool *tool = [toolSet toolForIdentifier:toolId];
                if (tool != nil) {
                    // Normally tools are created lazily, but in our case, we want to avoid creating an additional instance of the tool.
                    _toolClasses[toolId] = tool.class;
                    _tools[toolId] = tool;
                    [tool addAliasedToolSet:self];
                } else {
                    AJRLog(AJRLoggingDomainDrawPlugIn, AJRLogLevelError, @"Tool set \"%@\" contains no tool \"%@\".", toolSetId, toolId);
                }
            } else {
                AJRLog(AJRLoggingDomainDrawPlugIn, AJRLogLevelError, @"No tool set \"%@\".", toolSetId);
            }
        } else {
            AJRLog(AJRLoggingDomainDrawPlugIn, AJRLogLevelError, @"The \"alias\" property of a tool must contain a string in the form \"<tool set id>:<tool id>\", but we received \"%@\" instead.", alias);
        }
    } else {
        AJRLog(AJRLoggingDomainDrawPlugIn, AJRLogLevelDebug, @"Tool: %C in %C", toolClass, self.class);
        [_toolClasses setObject:toolClass forKey:properties[@"id"]];
    }
}

- (NSArray<DrawTool *> *)tools {
    NSMutableArray<DrawTool *> *tools = [NSMutableArray array];

    // Doing this this way, rather than just accessing _tools, makes sure we actually cause tool instantiation.
    for (NSString *identifier in _toolClasses) {
        [tools addObject:[self toolForIdentifier:identifier]];
    }
    
    return [tools sortedArrayUsingComparator:^NSComparisonResult(DrawTool *obj1, DrawTool *obj2) {
        CGFloat leftPriority = obj1.displayPriority;
        CGFloat rightPriority = obj2.displayPriority;
        if (leftPriority == rightPriority) {
            return [obj1.name caseInsensitiveCompare:obj2.name];
        } else if (leftPriority < rightPriority) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
}

- (DrawTool *)toolForIdentifier:(NSString *)identifier {
    DrawTool *tool = [_tools objectForKey:identifier];
    
    if (tool == nil && identifier != nil) {
        tool = [[[_toolClasses objectForKey:identifier] alloc] initWithToolSet:self];
        if (tool != nil) {
            // This happens if you ask a toolset for a tool it doesn't own.
            [_tools setObject:tool forKey:identifier];
        }
    }

    return tool;
}

#pragma mark - Activation

- (BOOL)toolSetShouldActivateForDocument:(DrawDocument *)document {
    BOOL result = YES;
    
    for (DrawTool *tool in [_tools objectEnumerator]) {
        if (![tool toolShouldActivateForDocument:document]) {
            result = NO;
        }
    }
    
    return result;
}

- (BOOL)toolSetShouldDeactivateForDocument:(DrawDocument *)document {
    BOOL result = YES;
    
    for (DrawTool *tool in [_tools objectEnumerator]) {
        if (![tool toolShouldDeactivateForDocument:document]) {
            result = NO;
        }
    }
    
    return result;
}

#pragma mark - Canvas Menus

- (nullable NSMenu *)menuForEvent:(DrawEvent *)event {
    return nil;
}

#pragma mark - Document Querries

- (NSSet *)selectionForInspectionForDocument:(DrawDocument *)document {
    return [NSSet set];
}

@end
