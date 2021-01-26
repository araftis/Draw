//
//  DrawStrokeRibbonInspector.m
//  Draw
//
//  Created by Alex Raftis on 8/12/11.
//  Copyright (c) 2011 Apple, Inc. All rights reserved.
//

#import "DrawStrokeRibbonInspector.h"

#import "DrawDocument.h"
#import "DrawGraphic.h"
#import "DrawMeasurementUnit.h"
#import "DrawRibbonInspectorController.h"
#import "DrawStroke.h"
#import "DrawStrokeDash.h"

#import <AJRInterface/AJRInterface.h>

NSString * const DrawStrokeRibbonInspectorID = @"strokeRibbonInspector";

DrawAspectCreationCallback DrawStrokeCreationBlock = ^DrawAspect *(DrawGraphic *graphic, DrawAspectPriority priority) {
    DrawAspect *aspect = [[[[graphic document] templateGraphic] firstAspectOfType:[DrawStroke class] withPriority:priority] copy];
    if (aspect == nil) {
        aspect = [[DrawStroke alloc] initWithGraphic:graphic];
    }
    [graphic addAspect:aspect withPriority:priority];

    return aspect;
};

@implementation DrawStrokeRibbonInspector

#pragma mark - Load

//+ (void)load {
//    [DrawInspectorGroupController registerInspectorClass:self forName:DrawInspectorGroupRibbon];
//}

#pragma mark - DrawInspector - Factory

+ (NSSet *)inspectedClasses {
    return [NSSet setWithObjects:[DrawGraphic class], nil];
}

+ (CGFloat)priority {
    return 1.0;
}

+ (NSString *)identifier {
    return DrawStrokeRibbonInspectorID;
}

+ (NSString *)name {
    return [[AJRTranslator translatorForClass:self] valueForKey:@"Fill"];
}

#pragma mark - Data

+ (NSArray<NSNumber *> *)standardPointSizes {
    static NSArray *standardPointSizes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        standardPointSizes = @[@(0.25), @(0.5), @(1.0), @(1.25), @(1.5), @(2.0), @(3.0), @(4.0), @(5.0), @(6.0), @(7.0), @(8.0), @(9.0), @(10.0)];
    });
    return standardPointSizes;
}

#pragma mark - Utilities

- (NSFormatter *)widthFormatter {
    return [DrawMeasurementUnit formatterForMeasurementUnit:@"Points"];
}

#pragma mark - NSNibAwakening

- (void)awakeFromNib {
    NSMenu *menu;
    NSMenuItem *item;
    NSArray *dashes = [DrawStrokeDash defaultDashes];

    [_strokePopUp removeAllItems];
    [_strokePopUp setAutoenablesItems:NO];
    menu = [_strokePopUp menu];

    item = [menu addItemWithTitle:[[self translator] valueForKey:@"None"] action:NULL keyEquivalent:@""];
    for (DrawStrokeDash *dash in dashes) {
        item = [menu addItemWithImage:[dash image] action:NULL keyEquivalent:@""];
        [item setRepresentedObject:dash];
    }

    [menu addItem:[NSMenuItem separatorItem]];
    item = [menu addItemWithTitle:[[self translator] valueForKey:@"Show More..."] action:@selector(showMore:) keyEquivalent:@""];

    [_widthCombo setNumberOfVisibleItems:14];
}

#pragma mark - Actions

- (IBAction)showMore:(id)sender {
}

- (IBAction)selectStrokeStyle:(id)sender {
    id object = [[sender selectedItem] representedObject];

    if (object == nil) {
        [self removeInspectedAspectFromSelection];
        [self update];
    } else if ([object isKindOfClass:[DrawStrokeDash class]]) {
        [self setInspectedValue:object forKeyPath:@"dash" creationCallback:DrawStrokeCreationBlock];
    } else {
        [self update];
    }
}

- (IBAction)selectWidth:(id)sender {
    NSNumber *width;
    NSString *error;

    if ([[self widthFormatter] getObjectValue:&width forString:[_widthCombo stringValue] errorDescription:&error]) {
        if (width == nil) {
            width = @(0);
        }
        [self setInspectedValue:width forKeyPath:@"width" creationCallback:DrawStrokeCreationBlock];
    }
    [self update];
}

- (IBAction)selectColor:(AJRColorWell *)sender {
    if ([sender displayMode] == AJRColorWellDisplayNone) {
        [self setInspectedValue:nil forKeyPath:@"color" creationCallback:NULL];
    } else {
        [self setInspectedValue:[sender color] forKeyPath:@"color" creationCallback:DrawStrokeCreationBlock];
    }
    [self update];
}

#pragma mark - NSComboBoxDataSource

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
    return [[DrawStrokeRibbonInspector standardPointSizes] count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index {
    return [[self widthFormatter] stringForObjectValue:[[DrawStrokeRibbonInspector standardPointSizes] objectAtIndex:index]];
}

#pragma mark - DrawInspector

- (void)updateStrokeStyleForAspects {
    NSMutableSet *values = [NSMutableSet set];
    NSMenuItem *multipleItem;
    NSMenuItem *createdItem;

    for (DrawStroke *object in [self inspectedObjectsWithCreationCallback:NULL]) {
        id value = [object dash];
        if (value) {
            [values addObject:value];
        }
    }

    multipleItem = [[_strokePopUp menu] menuItemWithTag:1];
    createdItem = [[_strokePopUp menu] menuItemWithTag:2];

    if ([values count] == 0) {
        [_strokePopUp selectItemWithTitle:[[self translator] valueForKey:@"None"]];
        if (multipleItem) [[_strokePopUp menu] removeItem:multipleItem];
        if (createdItem) [[_strokePopUp menu] removeItem:createdItem];
    } else if ([values count] == 1) {
        DrawStrokeDash	*dash = [values anyObject];
        BOOL			found = NO;
        for (NSMenuItem *item in [_strokePopUp itemArray]) {
            if ([[item representedObject] isEqual:dash]) {
                [_strokePopUp selectItem:item];
                found = YES;
                break;
            }
        }
        if (!found) {
            createdItem = [[_strokePopUp menu] addItemWithImage:[dash image] action:NULL keyEquivalent:@""];
            [createdItem setRepresentedObject:dash];
            [createdItem setTag:2];
            [_strokePopUp selectItem:createdItem];
        }
        if (multipleItem) [[_strokePopUp menu] removeItem:multipleItem];
    } else {
        if (!multipleItem) {
            multipleItem = [[NSMenuItem alloc] initWithTitle:[[self translator] valueForKey:@"Multiple"] action:NULL keyEquivalent:@""];
            [multipleItem setEnabled:NO];
            [multipleItem setTag:1];
            [[_strokePopUp menu] insertItem:multipleItem atIndex:0];
            [_strokePopUp selectItem:multipleItem];
        }
        if (createdItem) [[_strokePopUp menu] removeItem:createdItem];
    }
}

- (void)updateStrokeColorForAspects {
    NSSet	*colors = [self inspectedValuesForKeyPath:@"color"];

    if ([colors count] == 0 || [colors anyObject] == [NSNull null]) {
        [_colorWell setDisplayMode:AJRColorWellDisplayNone];
    } else if ([colors count] == 1) {
        [_colorWell setColor:[colors anyObject]];
        [_colorWell setDisplayMode:AJRColorWellDisplayColor];
    } else {
        [_colorWell setDisplayMode:AJRColorWellDisplayMultiple];
    }
}

- (void)updateStrokeWidthForAspects {
    NSSet	*widths = [self inspectedValuesForKeyPath:@"width"];

    if ([widths count] == 0) {
    } else if ([widths count] == 1) {
        [_widthCombo setStringValue:[[self widthFormatter] stringForObjectValue:[widths anyObject]]];
    } else {
        [_widthCombo setStringValue:@""];
        [[_widthCombo cell] setPlaceholderString:[[self translator] valueForKey:@"Multiple"]];
    }
}

- (void)update {
    [super update];
    [self updateStrokeStyleForAspects];
    [self updateStrokeColorForAspects];
    [self updateStrokeWidthForAspects];
}

#pragma mark - DrawAspectInspector

- (DrawAspectPriority)inspectedPriority {
    return DrawAspectPriorityForeground;
}

- (Class)inspectedType {
    return [DrawStroke class];
}

@end
