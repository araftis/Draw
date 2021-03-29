
#import <Draw/DrawAspectInspector.h>

extern NSString * const DrawFillRibbonInspectorID;

@class AJRColorWell;

@interface DrawFillRibbonInspector : DrawAspectInspector
{
	AJRColorWell     *_colorWell;
}

@property (strong) IBOutlet NSColorWell *colorWell;

- (IBAction)selectColor:(id)sender;

@end
