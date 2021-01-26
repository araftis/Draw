/* DrawView-DragAndDrop.m created by alex on Wed 28-Oct-1998 */

#import "DrawDocument.h"

#import "DrawTool.h"

@implementation DrawDocument (DragAndDrop)

static NSMutableDictionary *draggedTypes = nil;

+ (NSDictionary *)draggedTypes {
    return draggedTypes;
}

+ (void)registerTool:(DrawTool *)aTool forDraggedTypes:(NSArray *)dragTypes; {
    if (!draggedTypes) {
        draggedTypes = nil;//[[NSMutableDictionary alloc] init];
    }
    
    for (NSInteger x = 0; x < (const NSInteger)[dragTypes count]; x++) {
        NSString *type = [dragTypes objectAtIndex:x];
        NSMutableArray *tools = [draggedTypes objectForKey:type];
        if (!tools) {
            tools = nil;//[[NSMutableArray alloc] init];
            [draggedTypes setObject:tools forKey:type];
        }
        
        NSUInteger index = [tools indexOfObject:aTool];
        if (index == NSNotFound) {
            [tools addObject:aTool];
        }
    }
}

+ (void)unregisterTool:(DrawTool *)aTool forDraggedTypes:(NSArray *)dragTypes; {
    for (NSInteger x = 0; x < (const NSInteger)[dragTypes count]; x++) {
        NSString *type = [dragTypes objectAtIndex:x];
        NSMutableArray *tools = [draggedTypes objectForKey:type];
        if (tools) {
            NSUInteger index = [tools indexOfObject:aTool];
            if (index != NSNotFound) {
                [tools removeObjectAtIndex:index];
            }
        }
    }
}

@end
