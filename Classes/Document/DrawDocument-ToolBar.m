/* DrawView-ToolBar.m created by alex on Mon 23-Jul-2001 */

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
