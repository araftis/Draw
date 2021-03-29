
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DrawGraphic;

@interface DrawTextContainer : NSTextContainer

- (instancetype)initWithGraphic:(DrawGraphic *)aGraphic;

@property (nonatomic,strong) DrawGraphic *graphic;

- (void)graphicDidChangeShape:(DrawGraphic *)graphic;

@end

NS_ASSUME_NONNULL_END
