//
//  DrawFillRibbonInspector.m
//  Draw
//
//  Created by Alex Raftis on 8/13/11.
//  Copyright (c) 2011 Apple, Inc. All rights reserved.
//

#import "DrawFillRibbonInspector.h"

#import "DrawDocument.h"
#import "DrawColorFill.h"
#import "DrawGraphic.h"
#import "DrawRibbonInspectorController.h"

#import <AJRInterface/AJRInterface.h>

NSString * const DrawFillRibbonInspectorID = @"drawFillRibbonInspector";

DrawAspectCreationCallback DrawFillCreationBlock = ^DrawAspect *(DrawGraphic *graphic, DrawAspectPriority priority) {
	DrawAspect *aspect = [[[[graphic document] templateGraphic] firstAspectOfType:[DrawColorFill class] withPriority:priority] copy];
	if (aspect == nil) {
		aspect = [[DrawColorFill alloc] initWithGraphic:graphic];
	}
	[graphic addAspect:aspect withPriority:priority];
    
	return aspect;
};

@implementation DrawFillRibbonInspector

#pragma mark - Load

//+ (void)load {
//    [DrawInspectorGroupController registerInspectorClass:self forName:DrawInspectorGroupRibbon];
//}

#pragma mark - DrawInspector - Factory

+ (NSSet *)inspectedClasses {
    return [NSSet setWithObjects:[DrawGraphic class], nil];
}

+ (CGFloat)priority {
    return 2.0;
}

+ (NSString *)identifier {
    return DrawFillRibbonInspectorID;
}

+ (NSString *)name {
    return [[AJRTranslator translatorForClass:self] valueForKey:@"Fill"];
}

#pragma mark - Properties

@synthesize colorWell = _colorWell;

#pragma mark - Actions

- (IBAction)selectColor:(AJRColorWell *)sender {
    if ([sender displayMode] == AJRColorWellDisplayNone) {
		for (DrawGraphic *graphic in [self selection]) {
			for (DrawAspect *aspect in [[graphic aspectsForPriority:DrawAspectPriorityBackground] copy]) {
				if ([aspect isKindOfClass:[DrawColorFill class]]) {
					[graphic removeAspect:aspect];
				}
			}
		}
    } else {
        [self setInspectedValue:[sender color] forKeyPath:@"color" creationCallback:DrawFillCreationBlock];
    }
    [self update];
}

#pragma mark - DrawInspector

- (void)updateFillColorForAspects {
	NSSet	*colors = [self inspectedValuesForKeyPath:@"color"];
	
	if ([colors count] == 0) {
        [_colorWell setDisplayMode:AJRColorWellDisplayNone];
	} else if ([colors count] == 1) {
		[_colorWell setColor:[colors anyObject]];
        [_colorWell setDisplayMode:AJRColorWellDisplayColor];
	} else {
        [_colorWell setDisplayMode:AJRColorWellDisplayMultiple];
	}
}

- (void)update {
	[super update];
	[self updateFillColorForAspects];
}

#pragma mark - DrawAspectInspector

- (DrawAspectPriority)inspectedPriority {
	return DrawAspectPriorityBackground;
}

- (Class)inspectedType {
	return [DrawFill class];
}

@end
