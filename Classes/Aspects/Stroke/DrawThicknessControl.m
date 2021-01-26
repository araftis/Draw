/* DrawThicknessControl.m created by alex on Sun 18-Oct-1998 */

#import "DrawThicknessControl.h"

#import "DrawThicknessCell.h"

@implementation DrawThicknessControl

+ (Class)cellClass
{
    return [DrawThicknessCell class];
}

- (void)setFloatValue:(float)value
{
    [super setFloatValue:value];
    [self setNeedsDisplay:YES];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

@end
