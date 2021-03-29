
#import <Draw/DrawAspectInspector.h>

@class DrawStrokeDash, DrawThicknessControl, AJRBox, AJRObjectBroker;

@interface DrawStrokeInspector : DrawAspectInspector <NSControlTextEditingDelegate> {
   IBOutlet NSColorWell *colorWell;
   IBOutlet DrawThicknessControl *thickness;
   IBOutlet NSTextField *thicknessText;
   IBOutlet NSMatrix *strokeType;
   IBOutlet NSMatrix *joinType;
   IBOutlet NSMatrix *lineCap;
   IBOutlet AJRBox *subinspector;
   IBOutlet NSTextField *miterLimitText;
   IBOutlet NSSlider *miterLimitSlider;
   IBOutlet NSMatrix *dashes;

   IBOutlet NSWindow *newDashWindow;
   IBOutlet NSImageView *newDashPreview;
   IBOutlet NSButton *newDashOKButton;
   IBOutlet NSButton *newDashCancelButton;
   IBOutlet NSButton *newDashTextField;

   NSMutableArray *strokes;

   DrawStrokeDash *_workDash;
}

- (void)setStrokeColor:(id)sender;
- (void)setStrokeThickness:(id)sender;
- (void)selectStrokeType:(id)sender;
- (void)selectJoinType:(id)sender;
- (void)selectLineCap:(id)sender;
- (void)setStokeMiterLimit:(id)sender;
- (void)selectDash:(id)sender;
- (void)createNewDashPattern:(id)sender;

- (NSUInteger)tagForStrokeNamed:(NSString *)name;
- (Class)strokeClassForName:(NSString *)name;
- (void)setStrokeType:(NSMatrix *)aMatrix;
- (Class)strokeClass;

- (void)ok:(id)sender;
- (void)cancel:(id)sender;

@end
