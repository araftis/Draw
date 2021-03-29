
#import <Draw/DrawTool.h>

NS_ASSUME_NONNULL_BEGIN

@class DrawEvent;

@protocol DrawSelectionDragger

- (BOOL)dragSelection:(NSArray *)selection withLastHitGraphic:(DrawGraphic *)graphic fromEvent:(DrawEvent *)event;

@end


@interface DrawSelectionTool : DrawTool

- (NSCursor *)cursor;

+ (void)registerObject:(id <DrawSelectionDragger>)aTool forDragWithModifierMask:(NSUInteger)mask;

@end

NS_ASSUME_NONNULL_END
