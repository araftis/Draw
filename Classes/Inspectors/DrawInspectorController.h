
#import <Draw/DrawInspector.h>

@class DrawDocument;

@interface DrawInspectorController : NSViewController {
    __weak DrawDocument *_document;

    NSArrayController *_selectionController;

    NSMutableDictionary *_inspectors;
    NSArray *_currentInspectors;
}

#pragma mark - Factory Client

+ (NSString *)name;
+ (NSString *)identifier;
+ (NSImage *)icon;
+ (CGFloat)priority;

#pragma mark - Creation

- (id)initWithDocument:(DrawDocument *)document;

#pragma mark - Properties

@property (readonly,weak) DrawDocument *document;
@property (readonly) NSArray *currentInspectors;
@property (readonly) NSArrayController *selectionController;

#pragma mark - Installation

- (void)installInView:(NSView *)view;

#pragma mark - Inspectors

- (NSSet *)inspectorClassesForObject:(id)object;
- (NSSet *)inspectorClassesForSelection;
- (NSArray *)inspectorsForSelection;

/*!
 Called to update inspectors when the selection changes. Subclasses can override this method and then update their UI after call super.
 */
- (void)updateInspectors;

@end
