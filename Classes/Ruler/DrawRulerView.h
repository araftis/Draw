/* DrawRulerView.h created by alex on Thu 12-Nov-1998 */

#import <AppKit/AppKit.h>

@interface DrawRulerView : NSRulerView
{
    NSDictionary    *_unitAttributes;
}

@property (nonatomic,strong) NSColor *backgroundColor;
@property (nonatomic,strong) NSColor *rulerBackgroundColor;
@property (nonatomic,strong) NSColor *rulerMarginBackgroundColor;
@property (nonatomic,strong) NSColor *tickColor;
@property (nonatomic,strong) NSColor *unitColor;

- (NSString *)rulerUnitAbbreviation;
- (CGFloat)rulerUnitConversionFactor;

@end

@protocol DrawRulerViewClient <NSObject>

@optional - (void)rulerViewDidSetClientView:(NSRulerView *)rulerView;

@end
