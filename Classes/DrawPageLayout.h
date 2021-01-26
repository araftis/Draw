
#import <AppKit/AppKit.h>

extern NSString	*NSPrintInfoDidUpdateNotification;
extern NSString	*DrawPrintInfoKey;

@interface DrawPageLayout : NSPageLayout <NSControlTextEditingDelegate>

@property (nonatomic,strong) IBOutlet NSCell *leftMargin;
@property (nonatomic,strong) IBOutlet NSCell *rightMargin;
@property (nonatomic,strong) IBOutlet NSCell *topMargin;
@property (nonatomic,strong) IBOutlet NSCell *bottomMargin;

/* Methods overridden from superclass */

- (void)pickedUnits:(id)sender;
- (void)readPrintInfo;
- (void)writePrintInfo;

- (NSString *)units;

@end


