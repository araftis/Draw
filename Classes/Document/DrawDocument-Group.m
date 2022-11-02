/*
 DrawDocument-Group.m
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

#import "DrawDocument.h"

#import "DrawDocumentStorage.h"
#import "DrawPage.h"
#import "DrawRectangle.h"

@implementation DrawDocument (Group)

+ (void)_setupGroupMenu {
    static BOOL		hasSetup = NO;
    
    if (!hasSetup) {
        NSMenuItem		*menuItem;
        NSMutableArray	*items = [NSMutableArray array];

        menuItem = [[NSMenuItem alloc] initWithTitle:@"Group" action:@selector(group:) keyEquivalent:@"g"];
        [items addObject:menuItem];

        menuItem = [[NSMenuItem alloc] initWithTitle:@"Ungroup" action:@selector(ungroup:) keyEquivalent:@"G"];
        [items addObject:menuItem];

        [DrawDocument addItems:items toMenu:[DrawDocument arrangeMenu]];
        [items removeAllObjects];

        menuItem = [[NSMenuItem alloc] initWithTitle:@"Enter Group" action:@selector(enterGroup:) keyEquivalent:@""];
        [items addObject:menuItem];

        menuItem = [[NSMenuItem alloc] initWithTitle:@"Exit Group" action:@selector(exitGroup:) keyEquivalent:@""];
        [items addObject:menuItem];

        [DrawDocument addItems:items toMenu:[DrawDocument arrangeMenu]];

        hasSetup = YES;
    }
}

- (IBAction)group:(id)sender {
    DrawRectangle *group = nil;
    NSArray *subgroup;
    
    if ([_storage.selection count] > 1) {
        group = [[DrawRectangle alloc] initWithFrame:NSZeroRect];
    } else {
        NSBeep();
        return;
    }
    
    [group removeAllAspects];
    [self addGraphic:group];
    
    subgroup = [[NSArray alloc] initWithArray:[self sortedSelection]];
    
    for (DrawGraphic *graphic in subgroup) {
        [self removeGraphicFromSelection:graphic];
    }
    for (DrawGraphic *graphic in subgroup) {
        [group addSubgraphic:graphic];
    }
    
    [[self page] addGraphic:group];

    [self addGraphicToSelection:group];
}

- (IBAction)ungroup:(id)sender {
    NSMutableArray *subgraphics;
    NSArray *graphicsSubgraphics;
    
    subgraphics = [[NSMutableArray alloc] init];
    for (DrawGraphic *graphic in [self sortedSelection]) {
        graphicsSubgraphics = [graphic subgraphics];
        if ([graphicsSubgraphics count]) {
            [subgraphics addObjectsFromArray:graphicsSubgraphics];
            [self removeGraphic:graphic];
            for (DrawGraphic *subgraphic in [graphicsSubgraphics reverseObjectEnumerator]) {
                [subgraphic removeFromSupergraphic];
            }
        }
        [graphic setNeedsDisplay];
    }
    
    for (DrawGraphic *graphic in subgraphics) {
        [[self page] addGraphic:graphic];
    }
    [self clearSelection];
    [self addGraphicsToSelection:subgraphics];
    
    [self ping];
}

- (IBAction)enterGroup:(id)sender {
    DrawGraphic	*aGroup = [self groupFromSelection];
    
    if (!aGroup) NSBeep();
    else {
        [self focusGroup:aGroup];
    }
}

- (IBAction)exitGroup:(id)sender {
    if (!_storage.group) NSBeep();
    else [self unfocusGroup];
}

- (void)focusGroup:(DrawGraphic *)aGroup {
    if (_storage.group != aGroup) {
        [self clearSelection];
        _storage.group = aGroup;
        [_storage.group setEditing:YES];
        [_storage.group setNeedsDisplay];
    }
}

- (void)unfocusGroup {
    if (_storage.group) {
        DrawGraphic	*oldGroup = _storage.group;
        
        [_storage.group setEditing:NO];
        _storage.group = [_storage.group supergraphic];
        [_storage.group setEditing:YES];
        
        [self clearSelection];
        [_storage.selection addObject:oldGroup];
        
        [_storage.group	setNeedsDisplay];
        [oldGroup setNeedsDisplay];
    }
}

- (void)unfocusAllGroups {
    while (_storage.group) {
        [self unfocusGroup];
    }
}

- (DrawGraphic *)focusedGroup {
    return _storage.group;
}

@end
