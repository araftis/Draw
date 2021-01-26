/* DrawPenTool.h created by alex on Fri 16-Oct-1998 */

#import <Draw/DrawTool.h>

#import <Draw/DrawGraphic.h>

typedef NS_ENUM(uint8_t, DrawPenTag) {
	DrawPenTagLine,
	DrawPenTagOpen,
	DrawPenTagClosed
};

@interface DrawPenTool : DrawTool <NSMenuItemValidation>

@end
