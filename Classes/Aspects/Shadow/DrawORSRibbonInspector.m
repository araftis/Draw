/*
DrawORSRibbonInspector.m
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

#import "DrawORSRibbonInspector.h"

#import "DrawDocument.h"
#import "DrawGraphic.h"
#import "DrawInspector.h"
#import "DrawOpacity.h"
#import "DrawReflection.h"
#import "DrawRibbonInspectorController.h"
#import "DrawShadow.h"

#import <AJRFoundation/AJRFoundation.h>

NSString * const DrawORSRibbonInspectorID = @"drawOpacityReflectionShadowRibbonInspector";

DrawAspectCreationCallback DrawOpacityCreationBlock = ^DrawAspect *(DrawGraphic *graphic, DrawAspectPriority priority) {
    DrawAspect *aspect = [[[[graphic document] templateGraphic] firstAspectOfType:[DrawOpacity class] withPriority:priority] copy];
    if (aspect == nil) {
        aspect = [[DrawOpacity alloc] initWithGraphic:graphic];
    }
    [graphic addAspect:aspect withPriority:priority];
    
    return aspect;
};

DrawAspectCreationCallback DrawShadowCreationBlock = ^DrawAspect *(DrawGraphic *graphic, DrawAspectPriority priority) {
    DrawAspect *aspect = [[[[graphic document] templateGraphic] firstAspectOfType:[DrawShadow class] withPriority:priority] copy];
    if (aspect == nil) {
        aspect = [[DrawShadow alloc] initWithGraphic:graphic];
    }
    [graphic addAspect:aspect withPriority:priority];
    
    return aspect;
};

DrawAspectCreationCallback DrawReflectionCreationBlock = ^DrawAspect *(DrawGraphic *graphic, DrawAspectPriority priority) {
    DrawAspect *aspect = [[[[graphic document] templateGraphic] firstAspectOfType:[DrawReflection class] withPriority:priority] copy];
    if (aspect == nil) {
        aspect = [[DrawReflection alloc] initWithGraphic:graphic];
    }
    [graphic addAspect:aspect withPriority:priority];
    
    return aspect;
};

@implementation DrawORSRibbonInspector

#pragma mark - Load

//+ (void)load {
//    [DrawInspectorGroupController registerInspectorClass:self forName:DrawInspectorGroupRibbon];
//}

#pragma mark - DrawInspector - Factory

+ (NSSet *)inspectedClasses {
    return [NSSet setWithObjects:[DrawGraphic class], nil];
}

+ (CGFloat)priority {
    return 3.0;
}

+ (NSString *)identifier {
    return DrawORSRibbonInspectorID;
}

+ (NSString *)name {
    return [[AJRTranslator translatorForClass:self] valueForKey:@"Opacity, Shadow, and Reflection"];
}

#pragma mark - Data

+ (NSArray *)standardOpacities {
    static NSArray  *standardOpacities;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        standardOpacities = @[@(1.0), @(0.9), @(0.8), @(0.7), @(0.6), @(0.5), @(0.4), @(0.3), @(0.2), @(0.1), @(0.0)];
    });
    return standardOpacities;
}

#pragma mark - NSNibAwakening

- (void)awakeFromNib {
    [_opacityCombo setNumberOfVisibleItems:11];
    [_opacityCombo reloadData];
}

#pragma mark - NSComboxBoxDataSource

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)comboBox {
    return [[DrawORSRibbonInspector standardOpacities] count];
}

- (id)comboBox:(NSComboBox *)comboBox objectValueForItemAtIndex:(NSInteger)index {
    return [[DrawORSRibbonInspector standardOpacities] objectAtIndex:index];
}

#pragma mark - Actions

- (IBAction)setOpacity:(id)sender {
    _inspectedType = [DrawOpacity class];
    
    [self setInspectedFloat:[[sender objectValue] floatValue] forKeyPath:@"opacity" creationCallback:DrawOpacityCreationBlock];
}

- (IBAction)setShadow:(id)sender {
    _inspectedType = [DrawShadow class];
    
    [self setInspectedBool:[sender state] == NSControlStateValueOn forKeyPath:@"active" creationCallback:DrawShadowCreationBlock];
}

- (IBAction)setReflection:(id)sender {
    _inspectedType = [DrawReflection class];
    
    [self setInspectedBool:[sender state] == NSControlStateValueOn forKeyPath:@"active" creationCallback:DrawReflectionCreationBlock];
}

#pragma mark - Utilities

- (void)updateOpacity {
    NSSet *opacities;

    _inspectedType = [DrawOpacity class];

    opacities = [self inspectedValuesForKeyPath:@"opacity"];

    if ([opacities count] == 0) {
        [_opacityCombo setObjectValue:[NSNumber numberWithFloat:1.0]];
    } else if ([opacities count] == 1) {
        [_opacityCombo setObjectValue:[opacities anyObject]];
    } else {
        [_opacityCombo setStringValue:[[self translator] valueForKey:@"Multiple"]];
    }
}

- (void)updateShadow {
    NSSet *actives;

    _inspectedType = [DrawShadow class];

    actives = [self inspectedValuesForKeyPath:@"active"];

    if ([actives count] == 0) {
        [_shadowButton setState:NSControlStateValueOff];
    } else if ([actives count] == 1) {
        [_shadowButton setState:[[actives anyObject] boolValue] ? NSControlStateValueOn : NSControlStateValueOff];
    } else {
        [_shadowButton setState:NSControlStateValueMixed];
    }
}

- (void)updateReflection {
    NSSet *actives;

    _inspectedType = [DrawReflection class];

    actives = [self inspectedValuesForKeyPath:@"active"];
    
    if ([actives count] == 0) {
        [_reflectionButton setState:NSControlStateValueOff];
    } else if ([actives count] == 1) {
        [_reflectionButton setState:[[actives anyObject] boolValue] ? NSControlStateValueOn : NSControlStateValueOff];
    } else {
        [_reflectionButton setState:NSControlStateValueMixed];
    }
}

#pragma mark - DrawInspector

- (DrawAspectPriority)inspectedPriority {
    return [_inspectedType defaultPriority];
}

- (void)update {
    [super update];
    [self updateOpacity];
    [self updateShadow];
    [self updateReflection];
}

@end
