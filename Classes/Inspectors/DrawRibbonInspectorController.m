/*
DrawRibbonInspectorController.m
Draw

Copyright © 2021, AJ Raftis and AJRFoundation authors
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
