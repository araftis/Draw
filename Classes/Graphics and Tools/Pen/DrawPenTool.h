
#import <Draw/DrawTool.h>

#import <Draw/DrawGraphic.h>

typedef NS_ENUM(uint8_t, DrawPenTag) {
	DrawPenTagLine,
	DrawPenTagOpen,
	DrawPenTagClosed
};

@interface DrawPenTool : DrawTool <NSMenuItemValidation>

@end
