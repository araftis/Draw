/* DrawObjectInspector.h created by alex on Fri 16-Oct-1998 */

#import "DrawInspectorModule.h"

@interface DrawObjectInspector : DrawInspectorModule
{
   IBOutlet NSMatrix		*repetitionMatrix;
   IBOutlet NSBox			*subinspector;
   IBOutlet NSTextField	*flatnessText;
   IBOutlet NSSlider		*flatnessSlider;
}

- (void)setFlatness:(id)sender;
- (void)setObjectRepetition:(id)sender;

@end
