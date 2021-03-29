
#import <Draw/DrawInspector.h>

extern NSString * const DrawLinkRibbonInspectorID;

@interface DrawLinkRibbonInspector : DrawInspector

@property (nonatomic,strong) IBOutlet NSPopUpButton *sourcePopUp;
@property (nonatomic,strong) IBOutlet NSPopUpButton *destinationPopUp;

@end
