/* DrawInspectorController.h created by alex on Sun 11-Oct-1998 */

@class DrawInspector;

#import <AppKit/AppKit.h>

@class ASBox;

extern NSString *DrawInspectorOrderKey;

@interface DrawInspectorController : NSObject
{
   IBOutlet NSWindow	*window;
   IBOutlet ASBox		*box;
   IBOutlet NSMatrix	*buttons;

   NSMutableArray		*inspectors;

   DrawInspector		*inspector;
}

+ (id)sharedInstance;
- (void)showDrawInspectorPanel:(id)sender;

- (BOOL)selectInspectorAtIndex:(NSUInteger)index;
- (void)setInspector:(DrawInspector *)anInspector;
- (void)selectInspector:(id)sender;

- (void)sortCells;

@end


@interface NSResponder (DrawInspectorController)

- (void)showDrawInspectorPanel:(id)sender;

@end
