/* DrawDocumentInspector.m created by alex on Fri 16-Oct-1998 */

#import "DrawDocumentInspector.h"

#import "DrawPageLayout.h"
#import "DrawDocument.h"

#import <ASInterface/ASInterface.h>
#import <ASInterface/NSPrintInfo-Extensions.h>

@implementation DrawDocumentInspector

- (id)init
{
    self = [super init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update) name:DrawViewDidUpdateNotification object:nil];
#warning Implement
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update) name:DrawViewDidBecomeCurrentNotification object:nil];
    
    return self;
}

- (NSString *)title
{
    return @"Document";
}

- (void)update
{
#warning Implement
    DrawDocument		*drawView;// = [[DrawController sharedInstance] currentView];
    NSPrintInfo	*printInfo = nil;
    
    if (drawView) {
        printInfo = [drawView printInfo];
        
        [paperColorWell setColor:[drawView paperColor]];
        
        [marksColorWell setColor:[drawView markColor]];
        [marksVisibleCheck setState:[drawView marksVisible]];
        [marksActiveCheck setState:[drawView marksEnabled]];
        
        [gridColorWell setColor:[drawView gridColor]];
        [gridVisibleCheck setState:[drawView gridVisible]];
        [gridActiveCheck setState:[drawView gridEnabled]];
        [gridSpacingText setStringValue:[printInfo pointsAsMeasureString:[drawView gridSpacing] places:5]];
    } else {
        NSUserDefaults		*defaults = [NSUserDefaults standardUserDefaults];
        
        printInfo = [NSPrintInfo sharedPrintInfo];
        
        [paperColorWell setColor:[defaults colorForKey:DrawPaperColorKey]];
        
        [marksColorWell setColor:[defaults colorForKey:DrawMarkColorKey]];
        [marksVisibleCheck setState:[[defaults stringForKey:DrawMarksVisibleKey] hasPrefix:@"Y"]];
        [marksActiveCheck setState:[[defaults stringForKey:DrawMarksVisibleKey] hasPrefix:@"Y"]];
        
        [gridColorWell setColor:[defaults colorForKey:DrawGridColorKey]];
        [gridVisibleCheck setState:[[defaults stringForKey:DrawGridVisibleKey] hasPrefix:@"Y"]];
        [gridActiveCheck setState:[[defaults stringForKey:DrawGridEnabledKey] hasPrefix:@"Y"]];
        [gridSpacingText setStringValue:[printInfo pointsAsMeasureString:[defaults floatForKey:DrawGridSpacingKey] places:5]];
    }
    
    if (!printInfo) {
        printInfo = [NSPrintInfo sharedPrintInfo];
    }
    
    [leftMarginCell setStringValue:[printInfo pointsAsMeasureString:[printInfo leftMargin]]];
    [rightMarginCell setStringValue:[printInfo pointsAsMeasureString:[printInfo rightMargin]]];
    [topMarginCell setStringValue:[printInfo pointsAsMeasureString:[printInfo topMargin]]];
    [bottomMarginCell setStringValue:[printInfo pointsAsMeasureString:[printInfo bottomMargin]]];
    [unitsOfMeasureButton selectItemWithTitle:[printInfo unitsOfMeasure]];
}

- (void)setPaperColor:(NSColorWell *)sender
{
#warning Implement
    //[[[DrawController sharedInstance] currentView] setPaperColor:[sender color]];
}

- (void)setMarkColor:(NSColorWell *)sender
{
#warning Implement
    //[[[DrawController sharedInstance] currentView] setMarkColor:[sender color]];
}

- (void)setMarkVisible:(NSButton *)sender
{
#warning Implement
    //[[[DrawController sharedInstance] currentView] setShowMarks:[sender state]];
}

- (void)setMarkActive:(NSButton *)sender
{
#warning Implement
    //[[[DrawController sharedInstance] currentView] setSnapToMarks:[sender state]];
}

- (void)setGridColor:(NSColorWell *)sender
{
#warning Implement
    //[[[DrawController sharedInstance] currentView] setGridColor:[sender color]];
}

- (void)setGridActive:(NSButton *)sender
{
#warning Implement
    //[[[DrawController sharedInstance] currentView] setGridEnabled:[sender state]];
    //[[NSUserDefaults standardUserDefaults] setObject:[sender state] ? @"YES" : @"NO" forKey:DrawGridEnabledKey];
}

- (void)setGridVisible:(NSButton *)sender
{
#warning Implement
    //[[[DrawController sharedInstance] currentView] setGridVisible:[sender state]];
    //[[NSUserDefaults standardUserDefaults] setObject:[sender state] ? @"YES" : @"NO" forKey:DrawGridVisibleKey];
}

- (void)_setGridSpacing:(CGFloat)gridSpacing
{
    NSPrintInfo		*printInfo = [self printInfo];
#warning Implement
    DrawDocument		*drawView = nil;//[[DrawController sharedInstance] currentView];
    
    if (drawView) {
        [drawView setGridSpacing:gridSpacing];
        [gridSpacingText setStringValue:[printInfo pointsAsMeasureString:gridSpacing places:5]];
    }
    
    [[NSUserDefaults standardUserDefaults] setFloat:gridSpacing forKey:DrawGridSpacingKey];
}

- (void)setGridSpacing:(NSTextField *)sender
{
    [self _setGridSpacing:[[self printInfo] measureToPoints:[sender floatValue]]]; 
}

- (void)doubleGridSize:(NSButton *)sender
{
#warning Implement
    DrawDocument			*drawView = nil;//[[DrawController sharedInstance] currentView];
    
    if (drawView) {
        [self _setGridSpacing:[drawView gridSpacing] * 2.0];
    } else {
        [self _setGridSpacing:[[self printInfo] measureToPoints:[gridSpacingText floatValue]] * 2.0];
    }
}

- (void)halveGridSize:(NSButton *)sender
{
#warning Implement
    DrawDocument			*drawView = nil;//[[DrawController sharedInstance] currentView];
    
    if (drawView) {
        [self _setGridSpacing:[drawView gridSpacing] / 2.0];
    } else {
        [self _setGridSpacing:[[self printInfo] measureToPoints:[gridSpacingText floatValue]] / 2.0];
    }
}

- (void)setLeftMargin:(NSFormCell *)sender
{
    NSPrintInfo		*printInfo = [self printInfo];
    CGFloat				value = [printInfo measureToPoints:[sender floatValue]];
    
    if (value != [printInfo leftMargin]) {
        [printInfo setLeftMargin:value];
        [sender setStringValue:[printInfo pointsAsMeasureString:value]];
        
#warning Implement
        //[[[DrawController sharedInstance] currentView] updateMarkings];
    }
}

- (void)setRightMargin:(NSFormCell *)sender
{
    NSPrintInfo		*printInfo = [self printInfo];
    CGFloat				value = [printInfo measureToPoints:[sender floatValue]];
    
    if (value != [printInfo rightMargin]) {
        [printInfo setRightMargin:value];
        [sender setStringValue:[printInfo pointsAsMeasureString:value]];
        
#warning Implement
        //[[[DrawController sharedInstance] currentView] updateMarkings];
    }
}

- (void)setBottomMargin:(NSFormCell *)sender
{
    NSPrintInfo		*printInfo = [self printInfo];
    CGFloat				value = [printInfo measureToPoints:[sender floatValue]];
    
    if (value != [printInfo bottomMargin]) {
        [printInfo setBottomMargin:value];
        [sender setStringValue:[printInfo pointsAsMeasureString:value]];
        
        //[[[DrawController sharedInstance] currentView] updateMarkings];
    }
}

- (void)setTopMargin:(NSFormCell *)sender
{
    NSPrintInfo		*printInfo = [self printInfo];
    CGFloat				value = [printInfo measureToPoints:[sender floatValue]];
    
    if (value != [printInfo topMargin]) {
        [printInfo setTopMargin:value];
        [sender setStringValue:[printInfo pointsAsMeasureString:value]];
        
        //[[[DrawController sharedInstance] currentView] updateMarkings];
    }
}

- (void)setUnitsOfMeasure:(id)sender
{
    NSPrintInfo		*printInfo = [self printInfo];
    NSString			*value;
    
    if ([sender isKindOfClass:[NSString class]]) {
        value = sender;
    } else {
        value = [sender titleOfSelectedItem];
    }
    
    if (![value isEqualToString:[printInfo unitsOfMeasure]]) {
#warning Implement
        //[[[DrawController sharedInstance] currentView] registerUndoWithTarget:self selector:@selector(setUnitsOfMeasure:) object:[printInfo unitsOfMeasure]];
        //[[[DrawController sharedInstance] currentView] setActionName:@"Units of Measure"];
        [printInfo setUnitsOfMeasure:value];
        [self update];
    }
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
    id			object = [aNotification object];
    NSInteger		movement = [[[aNotification userInfo] objectForKey:@"NSTextMovement"] intValue];
    
    if ((movement == NSTabTextMovement) || (movement == NSBacktabTextMovement)) {
        if (object == gridSpacingText) {
            [self setGridSpacing:object];
        } else {
            NSFormCell	*cell = [object selectedCell];
            switch ([cell tag]) {
                case 0:
                    [self setLeftMargin:cell];
                    break;
                case 1:
                    [self setRightMargin:cell];
                    break;
                case 2:
                    [self setTopMargin:cell];
                    break;
                case 3:
                    [self setBottomMargin:cell];
                    break;
            }
        }
    }
}

@end
