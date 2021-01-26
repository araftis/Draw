/* DrawClip.m created by alex on Tue 26-Jan-1999 */

#import "DrawClip.h"

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

NSString *DrawClipIdentifier = @"clip";

@implementation DrawClip

#pragma mark - Factory

#pragma mark - DrawAspect

- (DrawGraphicCompletionBlock)drawPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority {
	[path addClip];
	return nil;
}

@end
