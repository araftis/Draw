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
