/* DrawObjectSizeInspector.h created by alex on Wed 03-Feb-1999 */

#import "DrawInspectorModule.h"

@interface DrawObjectSizeInspector : DrawInspectorModule
{
   IBOutlet NSTextField		*xTextField;
   IBOutlet NSTextField		*yTextField;
   IBOutlet NSTextField		*widthTextField;
   IBOutlet NSTextField		*heightTextField;
   IBOutlet NSButton			*horizontalButton;
   IBOutlet NSButton			*verticalButton;
   IBOutlet NSButton			*leftEdgeButton;
   IBOutlet NSButton			*rightEdgeButton;
   IBOutlet NSButton			*topEdgeButton;
   IBOutlet NSButton			*bottomEdgeButton;
   IBOutlet NSImageView		*objectImage;
}

- (void)setX:(id)sender;
- (void)setY:(id)sender;
- (void)setWidth:(id)sender;
- (void)setHeight:(id)sender;

- (void)toggleLeftEdge:(id)sender;
- (void)toggleRightEdge:(id)sender;
- (void)toggleTopEdge:(id)sender;
- (void)toggleBottomEdge:(id)sender;
- (void)toggleHorizontal:(id)sender;
- (void)toggleVertical:(id)sender;

@end
