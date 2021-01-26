
#import "DrawDocument.h"

#import "DrawDocumentStorage.h"

#import <AJRFoundation/NSObject+Extensions.h>

@implementation DrawDocument (Menus)

+ (NSMenuItem *)menuItemWithTitle:(NSString *)title in:(NSMenu *)menu {
    for (NSMenuItem *item in [menu itemArray]) {
        if ([[item title] isEqualToString:title]) {
            return item;
        }
    }

    return nil;
}

+ (NSMenu *)formatMenu {
    return nil;
}

+ (NSMenu *)arrangeMenu {
    NSMenu *mainMenu = [NSApp mainMenu];
    NSMenuItem *arrangeMenuItem = [self menuItemWithTitle:[[self translator] valueForKey:@"Arrange"] in:mainMenu];

    if (arrangeMenuItem == nil) {
        NSMenuItem	  *after = [self menuItemWithTitle:@"Format" in:mainMenu];
        if (after == nil) {
            after = [self menuItemWithTitle:@"Edit" in:mainMenu];
            if (after == nil) {
                after = [self menuItemWithTitle:@"File" in:mainMenu];
                if (after == nil) {
                    after = [[mainMenu itemArray] objectAtIndex:0];
                }
            }
        }
        if (after) {
            NSMenu		*arrangeMenu;

            arrangeMenuItem = [[NSMenuItem alloc] initWithTitle:[[self translator] valueForKey:@"Arrange"] action:NULL keyEquivalent:@""];
            arrangeMenu = [[NSMenu alloc] initWithTitle:[[self translator] valueForKey:@"Arrange"]];
            [arrangeMenuItem setSubmenu:arrangeMenu];

            [mainMenu insertItem:arrangeMenuItem atIndex:[mainMenu indexOfItem:after] + 1];
        }
    }

    return [arrangeMenuItem submenu];
}

+ (NSMenu *)viewMenu {
    NSMenu *mainMenu = [NSApp mainMenu];
    NSMenuItem *viewMenuItem = [self menuItemWithTitle:[[self translator] valueForKey:@"View"] in:mainMenu];

    if (viewMenuItem == nil) {
        NSMenuItem	  *after = [self menuItemWithTitle:[[self translator] valueForKey:@"Arrange"] in:mainMenu];
        if (after == nil) {
            after = [self menuItemWithTitle:@"Edit" in:mainMenu];
            if (after == nil) {
                after = [self menuItemWithTitle:@"File" in:mainMenu];
                if (after == nil) {
                    after = [[mainMenu itemArray] objectAtIndex:0];
                }
            }
        }
        if (after) {
            NSMenu		*viewMenu;

            viewMenuItem = [[NSMenuItem alloc] initWithTitle:[[self translator] valueForKey:@"View"] action:NULL keyEquivalent:@""];
            viewMenu = [[NSMenu alloc] initWithTitle:[[self translator] valueForKey:@"View"]];
            [viewMenuItem setSubmenu:viewMenu];

            [mainMenu insertItem:viewMenuItem atIndex:[mainMenu indexOfItem:after] + 1];
        }
    }

    return [viewMenuItem submenu];
}


+ (void)addItems:(NSArray *)items toMenu:(NSMenu *)menu {
    if ([[menu itemArray] count] != 0) {
        [menu addItem:[NSMenuItem separatorItem]];
    }
    for (NSMenuItem *item in items) {
        [menu addItem:item];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];

    if (action == @selector(toggleMarks:)) {
        [menuItem setTitle:[self marksVisible] ? @"Hide Marks" : @"Show Marks"];
    } else if (action == @selector(toggleRuler:)) {
        BOOL	visible = [[self.pagedView enclosingScrollView] rulersVisible];
        [menuItem setTitle:visible ? @"Hide Rulers" : @"Show Rulers"];
    } else if (action == @selector(toggleGridVisible:)) {
        [menuItem setTitle:[self gridVisible] ? @"Hide Grid" : @"Show Grid"];
    }

    if (action == @selector(undo:)) {
        return [[self undoManager] canUndo];
    } else if (action == @selector(redo:)) {
        return [[self undoManager] canRedo];
    } else if (action == @selector(deletePage:)) {
        return [_storage.pages count] > 1;
    } else if (action == @selector(group:)) {
        return [_storage.selection count] > 1;
    } else if (action == @selector(ungroup:)) {
        return [self selectionContainsGroups];
    } else if (action == @selector(enterGroup:)) {
        return [self selectionContainsGroups];
    } else if (action == @selector(exitGroup:)) {
        return _storage.group != nil;
    }

    return YES;
}

@end
