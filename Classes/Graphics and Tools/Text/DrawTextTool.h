/* DrawTextTool.h created by alex on Thu 08-Oct-1998 */

#import <Draw/DrawTool.h>

typedef NS_ENUM(uint8_t, DrawTextTag) {
    DrawTextTagText,
    DrawTextTagFormEntry
};

NS_ASSUME_NONNULL_BEGIN

extern NSString * const DrawTextToolIdentifier;

@interface DrawTextTool : DrawTool <NSMenuItemValidation>

@end

NS_ASSUME_NONNULL_END
