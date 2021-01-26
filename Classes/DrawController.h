/* DrawController.h created by alex on Thu 23-Apr-1998 */

#import <AppKit/AppKit.h>

@class DrawTool, DrawView;

extern NSString *DrawViewDidBecomeCurrentNotification;

@interface DrawController : NSObject
{
   NSMutableArray   *tools;

   DrawTool         *currentTool;
   DrawView			*currentView;

   NSMenu			*actionMenu;
}

+ (id)sharedInstance;

- (BOOL)setCurrentTool:(DrawTool *)aTool;
- (DrawTool *)currentTool;
- (NSArray *)tools;
- (void)setCurrentView:(DrawView *)aView;
- (DrawView *)currentView;

- (NSMenu *)actionMenu;
- (NSMenu *)actionMenuCopyWithZone:(NSZone *)zone;

@end
