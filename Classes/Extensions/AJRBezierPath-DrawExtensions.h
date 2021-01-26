/* AJRBezierPath-DrawExtensions.h created by alex on Thu 14-Jan-1999 */

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

#import <Draw/DrawGraphic.h>

@interface AJRBezierPath (DrawExtensions)

- (DrawHandle)drawHandleForPoint:(NSPoint)aPoint error:(CGFloat)error;

- (CGFloat)angleInDegreesOfInitialLineSegment;
- (CGFloat)angleInDegreesOfTerminatingLineSegment;

@end
