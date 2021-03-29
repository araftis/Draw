
#import <Draw/DrawAspectInspector.h>

@interface DrawORSRibbonInspector : DrawAspectInspector 

@property (nonatomic,readonly) Class inspectedType;
@property (nonatomic,strong) IBOutlet NSComboBox *opacityCombo;
@property (nonatomic,strong) IBOutlet NSButton *shadowButton;
@property (nonatomic,strong) IBOutlet NSButton *reflectionButton;

#pragma mark - Actions

- (IBAction)setOpacity:(id)sender;
- (IBAction)setShadow:(id)sender;
- (IBAction)setReflection:(id)sender;

@end
