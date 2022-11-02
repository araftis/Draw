/*
 DrawDocument-ToolBar.m
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

#import "DrawTool.h"
#import "DrawToolAction.h"
#import "DrawToolSet.h"

#import <AJRFoundation/AJRFoundation.h>
#import <Draw/Draw-Swift.h>

@implementation DrawDocument (ToolBar)

- (IBAction)selectTool:(id)sender {
    DrawToolSet *toolSet = nil;
    DrawTool *tool = nil;
    DrawToolAction *action = nil;

    if ([sender isKindOfClass:[NSSegmentedControl class]]) {
        if (sender == self.toolSegments) {
            toolSet = self.displayedToolSet;
        } else if (sender == self.globalToolSegments) {
            toolSet = DrawToolSet.globalToolSet;
        }
        if (toolSet) {
            tool = [[toolSet tools] objectAtIndex:[sender selectedSegment]];
            action = [tool currentAction];
        }
    } else if ([sender isKindOfClass:[NSMenuItem class]]) {
        action = [sender representedObject];
        tool = [action tool];
    }

    if (action != nil && tool != nil) {
        tool.currentAction = action;
        self.currentTool = tool;
    }
}

- (IBAction)selectToolSet:(NSMenuItem *)sender {
    AJRPrintf(@"%C: %S", self, _cmd);
    self.currentToolSet = sender.representedObject;
}

- (void)toolDidBecomeActive:(NSNotification *)notification {
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return @[NSToolbarPrintItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, NSToolbarShowFontsItemIdentifier, @"layers", @"leftTracking", @"grid", @"globalTools", @"toolSets", @"tools", @"rightTracking", @"inspectors"];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return @[@"layers", @"leftTracking", @"grid", NSToolbarFlexibleSpaceItemIdentifier, @"globalTools", @"toolSets", @"tools", @"rightTracking", NSToolbarFlexibleSpaceItemIdentifier, @"inspectors"];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    if ([itemIdentifier isEqualToString:@"layers"]) {
        return self.layersToolbarItem;
    } else if ([itemIdentifier isEqualToString:@"leftTracking"]) {
        return [NSTrackingSeparatorToolbarItem trackingSeparatorToolbarItemWithIdentifier:@"leftTracking" splitView:self.splitViewController.splitView dividerIndex:0];
    } else if ([itemIdentifier isEqualToString:@"grid"]) {
        return self.gridToolbarItem;
    } else if ([itemIdentifier isEqualToString:@"globalTools"]) {
        return self.globalToolToolbarItem;
    } else if ([itemIdentifier isEqualToString:@"toolSets"]) {
        return self.toolSetsToolbarItem;
    } else if ([itemIdentifier isEqualToString:@"tools"]) {
        return self.toolsToolbarItem;
    } else if ([itemIdentifier isEqualToString:@"rightTracking"]) {
        return [NSTrackingSeparatorToolbarItem trackingSeparatorToolbarItemWithIdentifier:@"rightTracking" splitView:self.splitViewController.splitView dividerIndex:1];
    } else if ([itemIdentifier isEqualToString:@"inspectors"]) {
        return self.inspectorsToolbarItem;
    }

    return nil;
}

@end
