
#import <Draw/DrawTool.h>

#import <Draw/DrawGraphic.h>

typedef NS_ENUM(uint8_t, DrawSquiggleTag) {
	DrawSquiggleTagOpen,
	DrawSquiggleTagClosed,
	DrawSquiggleTagSmart,
};

@interface DrawSquiggleTool : DrawTool

@end
