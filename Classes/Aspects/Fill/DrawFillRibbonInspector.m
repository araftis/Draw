/*
DrawFillRibbonInspector.m
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
