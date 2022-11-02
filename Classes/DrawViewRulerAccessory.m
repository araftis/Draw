/*
 DrawViewRulerAccessory.m
 Draw

 Copyright © 2022, AJ Raftis and Draw authors
 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 * Neither the name of Draw nor the names of its contributors may be
   used to endorse or promote products derived from this software without
   specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL AJ RAFTIS BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
