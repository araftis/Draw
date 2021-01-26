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
