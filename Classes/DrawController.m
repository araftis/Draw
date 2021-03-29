/*
DrawController.m
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
/* DrawController.m created by alex on Thu 23-Apr-1998 */

#import "DrawController.h"

#import "Document.h"
#import "DrawFill.h"
#import "DrawInspector.h"
#import "DrawStroke.h"
#import "DrawTool.h"
#import "DrawView.h"
#import "NSMenu-DrawExtensions.h"

#import <ASFoundation/ASFoundation.h>
#import <ASInterface/ASInterface.h>

static DrawController	*SELF = nil;

NSString *DrawViewDidBecomeCurrentNotification = @"DrawViewDidBecomeCurrentNotification";

@implementation DrawController

+ (id)allocWithZone:(NSZone *)aZone
{
   if (!SELF) {
      aZone = NSCreateZone(NSPageSize(), NSPageSize(), YES);
      NSSetZoneName(aZone, @"Draw");
      SELF = [super allocWithZone:aZone];
   }
   return SELF;
}

+ (id)sharedInstance
{
   return [[self allocWithZone:NSDefaultMallocZone()] init];
}

- (id)init
{
   static BOOL	hasInitialized = NO;

   if (!hasInitialized) {
      NSPrintInfo		*printInfo;

      hasInitialized = YES;

      self = [super init];

      tools = [[NSMutableArray alloc] init];
      currentTool = [[tools objectAtIndex:0] retain];

      printInfo = [[NSUserDefaults standardUserDefaults] printInfoForKey:@"DefaultPrintInfo"];
      if (printInfo) {
         [NSPrintInfo setSharedPrintInfo:printInfo];
      }

      [[DrawInspector allocWithZone:[self zone]] init];
   }

   return self;
}

- (void)dealloc
{
   [tools release];

   [super dealloc];
}

- (void)addTool:(Class)aClass;
{
   id		tool;

   ASPrintf(@"Tool: %@\n", aClass);
   tool = [[aClass alloc] init];
   [tools addObject:tool];
}

- (BOOL)setCurrentTool:(DrawTool *)aTool
{
   if (aTool != currentTool) {

      [currentTool resign];
      
      [currentTool release];
      currentTool = [aTool retain];

      return YES;
   }

   return NO;
}

- (DrawTool *)currentTool
{
   return currentTool;
}

- (void)setCurrentView:(DrawView *)aView
{
   if (currentView != aView) {
      [currentView release];
      currentView = [aView retain];

      [[NSNotificationCenter defaultCenter] postNotificationName:DrawViewDidBecomeCurrentNotification object:currentView];
   }
}

- (NSArray *)tools
{
   return tools;
}

- (DrawView *)currentView
{
   return currentView;
}

- (NSMenu *)_findActionMenuInMenu:(NSMenu *)menu
{
   NSArray		*items;
   NSInteger			x;
   NSMenuItem	*item;
   NSString		*title;
   NSMenu		*found = nil;

   items = [menu itemArray];
   for (x = 0; x < (const NSInteger)[items count]; x++) {
      found = nil;
      item = [items objectAtIndex:x];
      title = [item title];
      if ([title isEqualToString:@"Actions"]
#if !defined(MacOSX)
          && ([item tag] == -4321)
#endif
         ) {
         return [item target];
      }
      if ([item hasSubmenu]) {
         found = [self _findActionMenuInMenu:[item target]];
         if (found) return found;
      }
   }

   return nil;
}

- (NSMenu *)actionMenu
{
   if (!actionMenu) {
      actionMenu = [[self _findActionMenuInMenu:[NSApp mainMenu]] retain];
      [actionMenu removeItem:[[actionMenu itemArray] objectAtIndex:0]];
   }

   [actionMenu itemArray];
   
   if (actionMenu == nil) {
      actionMenu = [[NSMenu allocWithZone:[self zone]] init];
      [actionMenu setTitle:@"Actions"];
   }

   return actionMenu;
}

- (NSMenu *)actionMenuCopyWithZone:(NSZone *)zone
{
   return [[[self actionMenu] copyWithZone:zone] autorelease];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
   DrawView		*view;
   NSString		*error = nil;

   NS_DURING
      view = [[DrawView allocWithZone:NSCreateZone(NSPageSize(), NSPageSize(), YES)] initWithContentsOfURL:[NSURL fileURLWithPath:filename]];
   NS_HANDLER
      error = [localException description];
   NS_ENDHANDLER

   if (view && !error) {
      [[Document allocWithZone:[view zone]] initWithDrawView:view url:[NSURL fileURLWithPath:filename]];
   } else {
      return NO;
   }

   return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
   NSMenu		*menu;
#ifdef WIN32
   [[Document allocWithZone:NSCreateZone(NSPageSize(), NSPageSize(), YES)] initEmpty];
#endif

   menu = [[self _findActionMenuInMenu:[NSApp mainMenu]] retain];
   if (menu != actionMenu) {
      NSMenu	*supermenu = [menu supermenu];
      [supermenu setSubmenu:actionMenu forItem:[supermenu itemWithTitle:@"Actions"]];
   }
}

- (void)performUndo:(id)sender
{
   [[[self currentView] undoManager] undo];
}

- (void)performRedo:(id)sender
{
   [[[self currentView] undoManager] redo];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
   NSString			*title = [item title];
   NSUndoManager	*manager;
   
   if ([title hasPrefix:@"Undo"]) {
      manager = [[self currentView] undoManager];
      if ([manager canUndo]) {
         [item setTitle:[NSString stringWithFormat:@"Undo %@", [manager undoActionName]]];
         return YES;
      }
      [item setTitle:@"Undo"];
   } else if ([title hasPrefix:@"Redo"]) {
      manager = [[self currentView] undoManager];
      if ([manager canRedo]) {
         [item setTitle:[NSString stringWithFormat:@"Redo %@", [manager redoActionName]]];
         return YES;
      }
      [item setTitle:@"Redo"];
   }
   
   return NO;
}

@end
