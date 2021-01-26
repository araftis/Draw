
#import "DrawViewRulerAccessory.h"

#import "DrawDocument.h"
#import "DrawPageLayout.h"

#import <AJRInterface/AJRInterface.h>

@implementation DrawViewRulerAccessory

- (id)initWithDocument:(DrawDocument *)aGraphicView {
    if ((self = [super init])) {
        drawView = aGraphicView;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update) name:DrawViewDidUpdateNotification object:drawView];
    }
    return self;
}


- (NSView *)view {
    if (!view) {
        [[NSBundle bundleForClass:[self class]] loadNibNamed:@"DrawViewRulerAccessory" owner:self topLevelObjects:nil];
        [view removeFromSuperview];
    }

    return view;
}

- (void)update {
    [snapLineColorWell setColor:[drawView markColor]];
    [showSnapLinesSwitch setState:[drawView marksVisible]];
    [snapToSnapLinesSwitch setState:[drawView marksEnabled]];

    [gridColorWell setColor:[drawView gridColor]];
    [showGridSwitch setState:[drawView gridVisible]];
    [snapToGridSwitch setState:[drawView gridEnabled]];
    [gridSpacingText setFloatValue:[[drawView printInfo] pointsToMeasure:[drawView gridSpacing]]];
}

- (void)awakeFromNib {
    //	[[showGridSwitch cell] setGradientType:NSGradientConcaveWeak];
    //	[[showSnapLinesSwitch cell] setGradientType:NSGradientConcaveWeak];
    //	[[snapToGridSwitch cell] setGradientType:NSGradientConcaveWeak];
    //	[[snapToSnapLinesSwitch cell] setGradientType:NSGradientConcaveWeak];

    [self update];
}

- (void)setGridColor:(id)sender {
    [drawView setGridColor:[gridColorWell color]];
}

- (void)setGridSpacing:(id)sender {
    [drawView setGridSpacing:[[drawView printInfo] measureToPoints:[gridSpacingText floatValue]]];
    [gridSpacingText setFloatValue:[[drawView printInfo] pointsToMeasure:[drawView gridSpacing]]];
}

- (void)setShowGrid:(id)sender {
    [drawView setGridVisible:[(NSButton *)sender state]];
}

- (void)setShowSnapLines:(id)sender {
    [drawView setMarksVisible:[(NSButton *)sender state]];
}

- (void)setSnapLineColor:(id)sender {
    [drawView setMarkColor:[snapLineColorWell color]];
}

- (void)setSnapToGrid:(id)sender {
    [drawView setGridEnabled:[(NSButton *)sender state]];
}

- (void)setSnapToSnapLines:(id)sender {
    [drawView setMarksEnabled:[(NSButton *)sender state]];
}

@end
