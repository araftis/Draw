
#import <Draw/DrawAspect.h>

extern NSString * const DrawShadowIdentifier;

@interface DrawShadow : DrawAspect <AJRXMLCoding>

@property (strong) NSColor *color;
@property (assign) NSSize offset;
@property (assign) CGFloat blurRadius;

@end
