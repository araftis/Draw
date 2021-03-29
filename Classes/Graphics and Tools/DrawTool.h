
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DrawPage, DrawDocument, DrawEvent, DrawGraphic, DrawToolAction, DrawToolSet;

extern NSString *DrawToolDidBecomeActiveNotification;

@interface DrawTool : NSObject 

#pragma mark - Factory

+ (NSString *)identifier;
+ (NSString *)name;
- (NSArray<DrawToolAction *> *)createActions;

#pragma mark - Creation

- (id)initWithToolSet:(DrawToolSet *)toolSet NS_DESIGNATED_INITIALIZER;

#pragma mark - Properties

@property (nonatomic,readonly,weak) DrawToolSet *toolSet;
@property (nonatomic,readonly) NSString *identifier;
@property (nonatomic,readonly) NSString *name;
@property (nonatomic,readonly,strong) NSArray<DrawToolAction *> *actions;
@property (nonatomic,strong) DrawToolAction *currentAction;
@property (nonatomic,readonly) CGFloat displayPriority;
@property (nullable,nonatomic,strong) DrawGraphic *graphic;

- (NSString *)activationKey;

- (NSCursor *)cursor;

#pragma mark - Creation

- (DrawGraphic *)graphicWithPoint:(NSPoint)point document:(DrawDocument *)document page:(DrawPage *)page;

#pragma mark - Event Handling

- (BOOL)waitForMouseDrag:(DrawEvent *)event;

- (BOOL)mouseDown:(DrawEvent *)event;
- (BOOL)mouseDragged:(DrawEvent *)event;
- (BOOL)mouseUp:(DrawEvent *)event;
- (BOOL)mouseMoved:(DrawEvent *)event;
- (BOOL)mouseEntered:(DrawEvent *)event;
- (BOOL)mouseExited:(DrawEvent *)event;
- (BOOL)rightMouseDown:(DrawEvent *)event;
- (BOOL)rightMouseDragged:(DrawEvent *)event;
- (BOOL)rightMouseUp:(DrawEvent *)event;
- (BOOL)keyDown:(DrawEvent *)event;
- (BOOL)keyUp:(DrawEvent *)event;
- (BOOL)flagsChanged:(DrawEvent *)event;
- (BOOL)helpRequested:(DrawEvent *)event;
- (nullable NSMenu *)menuForEvent:(DrawEvent *)event;

#pragma mark - Activation

- (BOOL)toolShouldActivateForDocument:(DrawDocument *)document;
- (void)toolDidActivateForDocument:(DrawDocument *)document;
- (BOOL)toolShouldDeactivateForDocument:(DrawDocument *)document;
- (void)toolDidDeactivateForDocument:(DrawDocument *)document;

- (DrawDocument *)activeDocument;

#pragma mark - Icon

/*!
 Represents the icon to display in the tool bar. This only displays the "current" icon, and is generally used when the tool's action doesn't have an icon. This may return nil to indicate that only the action's icon be used. The default is to return nil. The returned icon should be 25x25 points and have 1x and 2x representations.

 @return An image to display for the tools.
 */
@property (nonatomic,readonly,nullable) NSImage *icon;

@end

@interface DrawTool (DragAndDrop)

// Drag and Drop
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender inView:(DrawPage *)drawView;
- (NSUInteger)draggingEntered:(id <NSDraggingInfo>)sender inView:(DrawPage *)drawView;
- (void)draggingExited:(id <NSDraggingInfo>)sender inView:(DrawPage *)drawView;
- (NSUInteger)draggingUpdated:(id <NSDraggingInfo>)sender inView:(DrawPage *)drawView;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender inView:(DrawPage *)drawView;
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender inView:(DrawPage *)drawView;

@end

NS_ASSUME_NONNULL_END
