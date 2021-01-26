
#import <AppKit/AppKit.h>

@class DrawDocument;

@interface DrawViewRulerAccessory : NSObject
{
	IBOutlet NSColorWell 	*gridColorWell;
	IBOutlet NSTextField 	*gridSpacingText;
	IBOutlet NSButton		*showGridSwitch;
	IBOutlet NSButton		*showSnapLinesSwitch;
	IBOutlet NSColorWell 	*snapLineColorWell;
	IBOutlet NSButton		*snapToGridSwitch;
	IBOutlet NSButton		*snapToSnapLinesSwitch;
	IBOutlet NSView		 	*view;
	IBOutlet NSWindow		*window;
	
	DrawDocument			*drawView;
}

- (id)initWithDocument:(DrawDocument *)aGraphicView;

- (NSView *)view;

- (void)update;

- (void)setGridColor:(id)sender;
- (void)setGridSpacing:(id)sender;
- (void)setShowGrid:(id)sender;
- (void)setShowSnapLines:(id)sender;
- (void)setSnapLineColor:(id)sender;
- (void)setSnapToGrid:(id)sender;
- (void)setSnapToSnapLines:(id)sender;

@end
