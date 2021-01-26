/* DrawDocumentInspector.h created by alex on Fri 16-Oct-1998 */

#import "DrawInspectorModule.h"

@interface DrawDocumentInspector : DrawInspectorModule
{
   IBOutlet NSColorWell		*paperColorWell;

   IBOutlet NSButton			*marksActiveCheck;
   IBOutlet NSButton			*marksVisibleCheck;
   IBOutlet NSColorWell		*marksColorWell;

   IBOutlet NSFormCell		*leftMarginCell;
   IBOutlet NSFormCell		*rightMarginCell;
   IBOutlet NSFormCell		*topMarginCell;
   IBOutlet NSFormCell		*bottomMarginCell;

   IBOutlet NSButton			*gridActiveCheck;
   IBOutlet NSButton			*gridVisibleCheck;
   IBOutlet NSColorWell		*gridColorWell;
   IBOutlet NSTextField		*gridSpacingText;
   
   IBOutlet NSPopUpButton	*unitsOfMeasureButton;
}

- (void)setPaperColor:(NSColorWell *)sender;

- (void)setMarkColor:(NSColorWell *)sender;
- (void)setMarkVisible:(NSButton *)sender;
- (void)setMarkActive:(NSButton *)sender;

- (void)setGridColor:(NSColorWell *)sender;
- (void)setGridActive:(NSButton *)sender;
- (void)setGridVisible:(NSButton *)sender;
- (void)setGridSpacing:(NSTextField *)sender;
- (void)doubleGridSize:(NSButton *)sender;
- (void)halveGridSize:(NSButton *)sender;

- (void)setLeftMargin:(NSFormCell *)sender;
- (void)setRightMargin:(NSFormCell *)sender;
- (void)setBottomMargin:(NSFormCell *)sender;
- (void)setTopMargin:(NSFormCell *)sender;

- (void)setUnitsOfMeasure:(NSPopUpButton *)sender;

@end
