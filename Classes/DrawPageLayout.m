/*
 DrawPageLayout.m
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

#import "DrawPageLayout.h"

#import "DrawDocument.h"

#import <AJRInterface/AJRInterface.h>

NSString *NSPrintInfoDidUpdateNotification = @"NSPrintInfoDidUpdateNotification";
NSString *DrawPrintInfoKey = @"DrawPrintInfoKey";

@implementation DrawPageLayout

- (NSInteger)runModalWithPrintInfo:(NSPrintInfo *)info {
    if (!_leftMargin) {
		[[NSBundle bundleForClass:[self class]] loadNibNamed:@"PageLayoutAccessory" owner:self topLevelObjects:nil];
    }
    
    return [super runModalWithPrintInfo:info];
}

- (void)pickedUnits:(id)sender {
    CGFloat oldm = 1;//, newm = 1;
    CGFloat left, right, top, bottom;
    NSString *saveUnits;
    
    //[self convertOldFactor:&oldm newFactor:&newm];
    
    left = [_leftMargin floatValue] / oldm;
    right = [_rightMargin floatValue] / oldm;
    top = [_topMargin floatValue] / oldm;
    bottom = [_bottomMargin floatValue] / oldm;
    
    saveUnits = [[[self printInfo] dictionary] objectForKey:NSUnitsOfMeasure];
    [[[self printInfo] dictionary] setObject:[(NSCell *)sender title] forKey:NSUnitsOfMeasure];
    [_leftMargin setStringValue:[[self printInfo] pointsAsMeasureString:left]];
    [_rightMargin setStringValue:[[self printInfo] pointsAsMeasureString:right]];
    [_topMargin setStringValue:[[self printInfo] pointsAsMeasureString:top]];
    [_bottomMargin setStringValue:[[self printInfo] pointsAsMeasureString:bottom]];
    [[[self printInfo] dictionary] setObject:saveUnits forKey:NSUnitsOfMeasure];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification {
    [_leftMargin setStringValue:[[self printInfo] pointsAsMeasureString:[[self printInfo] measureToPoints:[_leftMargin floatValue]]]];
    [_rightMargin setStringValue:[[self printInfo] pointsAsMeasureString:[[self printInfo] measureToPoints:[_rightMargin floatValue]]]];
    [_topMargin setStringValue:[[self printInfo] pointsAsMeasureString:[[self printInfo] measureToPoints:[_topMargin floatValue]]]];
    [_bottomMargin setStringValue:[[self printInfo] pointsAsMeasureString:[[self printInfo] measureToPoints:[_bottomMargin floatValue]]]];
}

- (void)readPrintInfo {
    NSString *unitString;
    
    //[super readPrintInfo];
    [_leftMargin setStringValue:[[self printInfo] pointsAsMeasureString:[[self printInfo] leftMargin]]];
    [_rightMargin setStringValue:[[self printInfo] pointsAsMeasureString:[[self printInfo] rightMargin]]];
    [_topMargin setStringValue:[[self printInfo] pointsAsMeasureString:[[self printInfo] topMargin]]];
    [_bottomMargin setStringValue:[[self printInfo] pointsAsMeasureString:[[self printInfo] bottomMargin]]];
    
    unitString = [[[self printInfo] dictionary] objectForKey:NSUnitsOfMeasure];
    if (!unitString) {
        unitString = @"Inches";
    }
}

- (void)writePrintInfo {
    //[super writePrintInfo];
    
    [[self printInfo] setLeftMargin:[[self printInfo] measureToPoints:[_leftMargin floatValue]]];
    [[self printInfo] setRightMargin:[[self printInfo] measureToPoints:[_rightMargin floatValue]]];
    [[self printInfo] setTopMargin:[[self printInfo] measureToPoints:[_topMargin floatValue]]];
    [[self printInfo] setBottomMargin:[[self printInfo] measureToPoints:[_bottomMargin floatValue]]];
    [[[self printInfo] dictionary] setObject:[self units] forKey:NSUnitsOfMeasure];
}

- (NSString *)units {
    return @"Inches";
}

@end

@implementation NSApplication (DrawPageLayout)

- (void)runPageLayout:(id)sender {
    DrawDocument *document = [DrawDocument focusedDocument];
    NSPrintInfo *info;
    NSPageLayout *layout;
    
    if (document) {
        info = [document printInfo];
    } else {
        info = [NSPrintInfo sharedPrintInfo];
    }
    
    layout = [DrawPageLayout pageLayout];
    
    if ([layout runModalWithPrintInfo:info] == NSAlertFirstButtonReturn) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NSPrintInfoDidUpdateNotification object:info];
    }
    
    [[NSUserDefaults standardUserDefaults] setPrintInfo:info forKey:DrawPrintInfoKey];
}

@end

