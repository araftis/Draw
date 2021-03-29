
#import <Draw/DrawGraphic.h>

#import <AJRFoundation/AJRFoundation.h>
#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct __drawPolyPos {
   AJRBezierPathElementType	currentOp;
   AJRBezierPathElementType	previousOp;
   AJRBezierPathElementType	nextOp;
   NSInteger currentOffset;
   NSInteger previousOffset;
   NSInteger nextOffset;
   DrawHandle handle;
} _DrawPolyPos;

extern const AJRInspectorIdentifier AJRInspectorIdentifierPen;

@interface DrawPen : DrawGraphic <AJRXMLCoding>

- (id)initWithFrame:(NSRect)aFrame;
- (id)initWithFrame:(NSRect)frame path:(AJRBezierPath *)aPath;

- (void)appendLineToPoint:(NSPoint)point;
- (void)appendMoveToPoint:(NSPoint)point;
- (void)appendBezierCurve:(AJRBezierCurve)curve;
- (void)appendBezierCurveToPoint:(NSPoint)point controlPoint1:(NSPoint)controlPoint1 controlPoint2:(NSPoint)controlPoint2;
- (void)insertPoint:(NSPoint)point atIndex:(NSUInteger)index;
- (void)insertPoint:(NSPoint)point;
- (void)removePointAtIndex:(NSUInteger)index;
- (void)removePoint:(NSPoint)point;

- (BOOL)isLine;

@property (nonatomic,assign) BOOL closed;
@property (nonatomic,assign) BOOL creating;

- (BOOL)isEqualToPen:(DrawPen *)other;

@end

NS_ASSUME_NONNULL_END
