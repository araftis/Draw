/* DrawText.h created by alex on Fri 30-Oct-1998 */

#import <Draw/DrawAspect.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const DrawTextIdentifier;

@class DrawTextView, DrawTextContainer;

@interface DrawText : DrawAspect

- (id)initWithGraphic:(nullable DrawGraphic *)graphic;
- (id)initWithGraphic:(nullable DrawGraphic *)aGraphic text:(NSAttributedString *)someText;

@property (nonatomic,strong) NSAttributedString *attributedString;
@property (nonatomic,assign) CGFloat lineFragmentPadding;

- (void)setupTextView:(NSTextView *)textView;

@property (nonatomic,readonly) NSLayoutManager *layoutManager;
@property (nonatomic,readonly) DrawTextView *textView;
@property (nullable,nonatomic,readonly) DrawTextContainer *textContainer;

- (void)updateMaxSize;

@end

NS_ASSUME_NONNULL_END
