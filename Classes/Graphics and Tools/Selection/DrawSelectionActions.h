
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DrawSelectionActions : NSObject <NSMenuItemValidation>

+ (id)sharedInstance;

- (void)activate;
- (void)deactivate;

- (void)flipVertical:(id)sender;
- (void)flipHorizontal:(id)sender;
- (void)makeSquare:(id)sender;
- (void)snapToGrid:(id)sender;

@end

NS_ASSUME_NONNULL_END
