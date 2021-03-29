
#import "DrawViewController.h"

#import <Draw/Draw-Swift.h>

#import <AJRFoundation/AJRFoundation.h>
#import <AJRInterface/AJRInterface.h>

@interface DrawViewController ()

@end

@implementation DrawViewController

- (DrawDocument *)document {
    return [AJRObjectIfKindOfClass([self.view.window.contentViewController ajr_descendantViewControllerOfClass:DrawDocumentViewController.class], DrawDocumentViewController) document];
}

- (DrawLayerViewController *)layerViewController {
    return AJRObjectIfKindOfClass([self.view.window.contentViewController ajr_descendantViewControllerOfClass:DrawLayerViewController.class], DrawLayerViewController);
}

- (DrawInspectorGroupsController *)inspectorGroupsViewController {
    return AJRObjectIfKindOfClass([self.view.window.contentViewController ajr_descendantViewControllerOfClass:DrawInspectorGroupsController.class], DrawInspectorGroupsController);
}

- (void)loadView {
    BOOL loaded = NO;

    if ([[NSBundle bundleForClass:self.class] pathForResource:AJRStringFromClassSansModule(self.class) ofType:@"nib"]) {
        loaded = [[NSBundle bundleForClass:self.class] loadNibNamed:AJRStringFromClassSansModule(self.class) owner:self topLevelObjects:nil];
    }

    if (!loaded) {
        [super loadView];
    }
}

#pragma mark - Life Cycle

- (void)documentDidLoad:(DrawDocument *)document {
    // We don't do anything by default.
}

- (void)documentWillClose:(DrawDocument *)document {
    // We don't do anything by default.
}

@end
