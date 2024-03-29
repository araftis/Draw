/*
 DrawInspectorGroupController.m
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
//
//  DrawInspectorGroupController.m
//  Draw
//
//  Created by Alex Raftis on 10/9/11.
//  Copyright (c) 2011 Apple, Inc. All rights reserved.
//

#import "DrawInspectorGroupController.h"

#import "DrawInspector.h"
#import "DrawInspectorController.h"
#import "DrawInspectorGroup.h"

#import <AJRFoundation/AJRLogging.h>

#pragma mark - Inspector Groups

NSString * const DrawInspectorGroupDocument = @"Document";
NSString * const DrawInspectorGroupLeft = @"Left";
NSString * const DrawInspectorGroupRight = @"Right";
NSString * const DrawInspectorGroupStyles = @"Styles";

@interface DrawInspectorGroupController ()

@property (nonatomic,strong) NSMutableDictionary *inspectorControllersByGroup;
@property (nonatomic,strong) NSMutableDictionary *inspectorGroupsByGroup;

@end

@implementation DrawInspectorGroupController

static NSMutableDictionary	*_inspectorControllerByGroup;
static NSMutableDictionary	*_inspectorControllersInGroup;
// (dictionary of (set of inspector classes) by inspectedClasses) of dictionaries by group name. 
static NSMutableDictionary	*_inspectorsByGroup;

#pragma mark - Initialization

+ (void)initialize
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_inspectorControllerByGroup = [[NSMutableDictionary alloc] init];
		_inspectorControllersInGroup = [[NSMutableDictionary alloc] init];
		_inspectorsByGroup = [[NSMutableDictionary alloc] init];
	});
}

#pragma mark - Factory

+ (void)registerControllerClass:(Class)class forName:(NSString *)inspectorGroup
{
	[_inspectorControllerByGroup setObject:class forKey:inspectorGroup];
	
	AJRLogDebug(@"Inspector Controller: %C for %@", class, inspectorGroup);
}

+ (Class)controllerClassForName:(NSString *)inspectorGroup
{
	return [_inspectorControllerByGroup objectForKey:inspectorGroup];
}

+ (void)registerControllerClass:(Class)class inGroup:(NSString *)name
{
	NSMutableSet	*classes = [_inspectorControllersInGroup objectForKey:name];
	
	if (classes == nil) {
		classes = [[NSMutableSet alloc] init];
		[_inspectorControllersInGroup setObject:classes forKey:name];
	}
	
	[classes addObject:class];
}

+ (NSSet *)controllerClassesInGroup:(NSString *)name
{
	return [_inspectorControllersInGroup objectForKey:name];
}

+ (void)registerInspectorClass:(Class)inspectorClass forName:(NSString *)inspectorGroup
{
	@autoreleasepool {
		NSMutableDictionary	*inspectorsForGroup = [_inspectorsByGroup objectForKey:inspectorGroup];
		if (inspectorsForGroup == nil) {
			inspectorsForGroup = [[NSMutableDictionary alloc] init];
			[_inspectorsByGroup setObject:inspectorsForGroup forKey:inspectorGroup];
		}
		for (Class inspectedClass in [inspectorClass inspectedClasses]) {
			NSMutableSet	*bucket = [inspectorsForGroup objectForKey:inspectedClass];
			if (bucket == nil) {
				bucket = [[NSMutableSet alloc] init];
				[inspectorsForGroup setObject:bucket forKey:(id)inspectedClass];
			}
			[bucket addObject:inspectorClass];
		}
	}
}

+ (NSSet *)inspectorClassesForClass:(Class)inspectedClass forName:(NSString *)inspectorGroup
{
	NSMutableDictionary	*inspectorsForGroup = [_inspectorsByGroup objectForKey:inspectorGroup];
	NSMutableSet		*set = [NSMutableSet set];
	
	for (Class class in inspectorsForGroup) {
		if ([inspectedClass isSubclassOfClass:class]) {
			[set unionSet:[inspectorsForGroup objectForKey:class]];
		}
	}
	
	return set;
}

#pragma mark - Creation

- (id)initWithDocument:(DrawDocument *)document
{
	if ((self = [super init])) {
		_document = document;
		_inspectorControllersByGroup = [[NSMutableDictionary alloc] init];
		_inspectorGroupsByGroup = [[NSMutableDictionary alloc] init];
	}
	return self;
}

#pragma mark - Inspector Groups

- (DrawInspectorController *)inspectorControllerForName:(NSString *)name
{
	DrawInspectorController *inspectorController = [_inspectorControllersByGroup objectForKey:name];
	
	if (inspectorController == nil) {
		inspectorController = [[[[self class] controllerClassForName:name] alloc] initWithDocument:_document];
		if (inspectorController) {
			[_inspectorControllersByGroup setObject:inspectorController forKey:name];
		} else {
			AJRLogWarning(@"We don't seem to have an inspector controller registered for the group %@", name);
		}
	}
	
	return inspectorController;
}

- (DrawInspectorGroup *)inspectorGroupForName:(NSString *)name
{
	DrawInspectorGroup	*inspectorGroup = [_inspectorGroupsByGroup objectForKey:name];
	
	if (inspectorGroup == nil) {
		inspectorGroup = [[[[self class] controllerClassForName:name] alloc] initWithDocument:_document];
		if (inspectorGroup == nil) {
			inspectorGroup = [[DrawInspectorGroup alloc] initWithDocument:_document name:name];
		}
		[_inspectorGroupsByGroup setObject:inspectorGroup forKey:name];
	}
	
	return inspectorGroup;
}

#pragma mark - Selection Change

- (void)updateInspectors
{
	for (DrawInspectorController *inspectorController in _inspectorControllersByGroup) {
		[inspectorController updateInspectors];
	}
	for (DrawInspectorGroup *inspectorGroup in _inspectorGroupsByGroup) {
		[inspectorGroup updateInspectors];
	}
}

@end
