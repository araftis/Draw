/*
 DrawLinkRibbonInspector.m
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

#import "DrawLinkRibbonInspector.h"

#import "DrawLink.h"
#import "DrawLinkCap.h"
#import "DrawLinkCapArrow.h"
#import "DrawLinkTool.h"
#import "DrawRibbonInspectorController.h"

#import <AJRFoundation/AJRFoundation.h>
#import <AJRInterface/AJRInterface.h>

static NSString * const DrawMutlipleMarker = @"multiple";

NSString * const DrawLinkRibbonInspectorID = @"linkRibbonInspector";

@implementation DrawLinkRibbonInspector

#pragma mark - Load

//+ (void)load {
//    [DrawInspectorGroupController registerInspectorClass:self forName:DrawInspectorGroupRibbon];
//}

#pragma mark - DrawInspector - Factory

+ (NSSet *)inspectedClasses {
    return [NSSet setWithObjects:[DrawLink class], nil];
}

+ (CGFloat)priority {
    return 5.0;
}

+ (NSString *)identifier {
    return DrawLinkRibbonInspectorID;
}

+ (NSString *)name {
    return [[AJRTranslator translatorForClass:self] valueForKey:@"Fill"];
}

#pragma mark - NSNibAwakening

- (void)awakeFromNib {
    NSArray *caps = [DrawLinkTool linkCaps];
    NSMenu *headMenu = [_sourcePopUp menu];
    NSMenu *tailMenu = [_destinationPopUp menu];
    NSMenuItem *item;

    [_sourcePopUp removeAllItems];
    [_destinationPopUp removeAllItems];

    item = [headMenu addItemWithTitle:[[self translator] valueForKey:@"None"] action:@selector(selectSourceCap:) keyEquivalent:@""];
    [item setTarget:self];
    item = [tailMenu addItemWithTitle:[[self translator] valueForKey:@"None"] action:@selector(selectDestinationCap:) keyEquivalent:@""];
    [item setTarget:self];
    
    for (Class linkCap in caps) {
        item = [headMenu addItemWithImage:[linkCap sourceImageFilled:YES] action:@selector(selectSourceCap:) keyEquivalent:@""];
        [item setTarget:self];
        [item setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:linkCap, @"linkCap", [NSNumber numberWithBool:YES], @"filled", nil]];
        item = [headMenu addItemWithImage:[linkCap sourceImageFilled:NO] action:@selector(selectSourceCap:) keyEquivalent:@""];
        [item setTarget:self];
        [item setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:linkCap, @"linkCap", [NSNumber numberWithBool:NO], @"filled", nil]];
        
        item = [tailMenu addItemWithImage:[linkCap destinationImageFilled:YES] action:@selector(selectDestinationCap:) keyEquivalent:@""];
        [item setTarget:self];
        [item setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:linkCap, @"linkCap", [NSNumber numberWithBool:YES], @"filled", nil]];
        item = [tailMenu addItemWithImage:[linkCap destinationImageFilled:NO] action:@selector(selectDestinationCap:) keyEquivalent:@""];
        [item setTarget:self];
        [item setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:linkCap, @"linkCap", [NSNumber numberWithBool:NO], @"filled", nil]];
    }
}

#pragma mark - Actions

- (IBAction)selectSourceCap:(id)sender {
    for (DrawGraphic *graphic in [self selection]) {
        if ([graphic isKindOfClass:[DrawLink class]]) {
            NSDictionary *container = [sender representedObject];

            [NSUserDefaults.standardUserDefaults setClass:container[@"linkCap"] forKey:DrawLinkCapTailStyleKey];
            [NSUserDefaults.standardUserDefaults setBool:[container[@"filled"] boolValue] forKey:DrawLinkCapTailFilledKey];

            DrawLinkCap *cap = [[[NSUserDefaults.standardUserDefaults classForKey:DrawLinkCapTailStyleKey defaultValue:[DrawLinkCapArrow class]] alloc] initWithType:DrawLinkCapTypeTail];
            [(DrawLink *)graphic setSourceCap:cap];
        }
    }
}

- (IBAction)selectDestinationCap:(id)sender {
    for (DrawGraphic *graphic in [self selection]) {
        if ([graphic isKindOfClass:[DrawLink class]]) {
            NSDictionary *container = [sender representedObject];

            [NSUserDefaults.standardUserDefaults setClass:container[@"linkCap"] forKey:DrawLinkCapHeadStyleKey];
            [NSUserDefaults.standardUserDefaults setBool:[container[@"filled"] boolValue] forKey:DrawLinkCapHeadFilledKey];

            DrawLinkCap *cap = [[[NSUserDefaults.standardUserDefaults classForKey:DrawLinkCapHeadStyleKey defaultValue:[DrawLinkCapArrow class]] alloc] initWithType:DrawLinkCapTypeHead];
            [(DrawLink *)graphic setDestinationCap:cap];
        }
    }
}

#pragma mark - Utilities

- (void)_removeMultipleFromPopUp:(NSPopUpButton *)button {
    NSMenuItem *multiple = [[button menu] itemWithRepresentedObject:DrawMutlipleMarker];

    if (multiple) {
        [[button menu] removeItem:multiple];
    }
}

- (void)_addMultipleToPopUp:(NSPopUpButton *)button {
    NSMenuItem *multiple = [[button menu] itemWithRepresentedObject:DrawMutlipleMarker];

    if (multiple == nil) {
        multiple = [[button menu] addItemWithTitle:[[self translator] valueForKey:@"Multiple"] action:NULL keyEquivalent:@""];
        [multiple setTarget:self];
    }

    [button selectItem:multiple];
}

- (NSMenuItem *)_itemInMenu:(NSMenu *)menu forLinkCap:(Class)linkCapClass {
    NSMenuItem *item = nil;

    for (item in [menu itemArray]) {
        id	representedObject = [item representedObject];
        if ([representedObject isKindOfClass:[NSDictionary class]] && [representedObject objectForKey:@"linkCap"] == linkCapClass) break;
    }

    return item;
}

- (void)updateSourceCap {
    NSMutableSet *values = [NSMutableSet set];

    for (DrawLink *link in [self inspectedObjectsWithCreationCallback:NULL]) {
        Class class = [[link sourceCap] class];
        if (class) {
            [values addObject:class];
        }
    }

    if ([values count] == 0) {
        [_sourcePopUp selectItemAtIndex:0];
        [self _removeMultipleFromPopUp:_sourcePopUp];
    } else if ([values count] == 1) {
        [_sourcePopUp selectItem:[self _itemInMenu:[_sourcePopUp menu] forLinkCap:[values anyObject]]];
        [self _removeMultipleFromPopUp:_sourcePopUp];
    } else {
        [self _addMultipleToPopUp:_sourcePopUp];
    }
}

- (void)updateDestinationCap {
    NSMutableSet *values = [NSMutableSet set];

    for (DrawLink *link in [self inspectedObjectsWithCreationCallback:NULL]) {
        Class	class = [[link destinationCap] class];
        if (class) {
            [values addObject:class];
        }
    }

    if ([values count] == 0) {
        [_destinationPopUp selectItemAtIndex:0];
        [self _removeMultipleFromPopUp:_destinationPopUp];
    } else if ([values count] == 1) {
        [_destinationPopUp selectItem:[self _itemInMenu:[_destinationPopUp menu] forLinkCap:[values anyObject]]];
        [self _removeMultipleFromPopUp:_destinationPopUp];
    } else {
        [self _addMultipleToPopUp:_destinationPopUp];
    }
}

#pragma mark - DrawInspector

- (Class)inspectedType {
    return [DrawLink class];
}

- (void)update {
    [self updateSourceCap];
    [self updateDestinationCap];
}

@end
