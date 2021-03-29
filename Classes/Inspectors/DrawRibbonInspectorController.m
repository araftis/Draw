
#import "DrawRibbonInspectorController.h"

#import "DrawInspector.h"

#import <AJRInterface/AJRInterface.h>

NSString * const DrawInspectorGroupRibbon = @"Ribbon";

@implementation DrawRibbonInspectorController

#pragma mark - Factory

//+ (void)load {
//    [DrawInspectorGroupController registerControllerClass:self forName:DrawInspectorGroupRibbon];
//}

#pragma mark - Properties

- (NSStackView *)stackView {
    return (NSStackView *)[self view];
}

#pragma mark - DrawInspectorController

- (NSSet *)inspectorClassesForObject:(id)object {
    return [NSSet set]; //[DrawInspectorGroupController inspectorClassesForClass:[object class] forName:DrawInspectorGroupRibbon];
}

- (void)updateInspectors {
    NSStackView *stackView = [self stackView];
    NSArray *views = [[stackView viewsInGravity:NSStackViewGravityCenter] copy];

    [super updateInspectors];

    for (NSView *view in views) {
        [stackView removeView:view];
    }

    [stackView setViews:@[] inGravity:NSStackViewGravityLeading];
    for (NSViewController *viewController in [self currentInspectors]) {
        NSView *newView = [viewController view];

        [newView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [stackView addView:newView inGravity:NSStackViewGravityLeading];
        [stackView addConstraint:[NSLayoutConstraint constraintWithItem:newView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:0 multiplier:1.0 constant:26.0]];

        NSBox *box = [[NSBox alloc] initWithFrame:(NSRect){NSZeroPoint, {1.0, 26.0}}];
        [box setTitlePosition:NSNoTitle];
        [box setBoxType:NSBoxCustom];
        box.borderWidth = 0.0;
        [box setFillColor:NSColor.separatorColor];
        [box setTranslatesAutoresizingMaskIntoConstraints:NO];
        [stackView addView:box inGravity:NSStackViewGravityLeading];
        [stackView addConstraint:[NSLayoutConstraint constraintWithItem:box attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:26.0]];
        [stackView addConstraint:[NSLayoutConstraint constraintWithItem:box attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:1.0]];
    }
}

@end
