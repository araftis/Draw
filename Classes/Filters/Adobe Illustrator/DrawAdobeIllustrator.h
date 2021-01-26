/* DrawAdobeIllustrator.h created by alex on Sun 10-Jan-1999 */

#import <Draw/DrawFilter.h>

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

@class DrawDocument;

@interface DrawAdobeIllustrator : DrawFilter
{
    NSFileHandle *file;
    NSMutableArray *stack;
    NSMutableArray *groupStack;
    DrawDocument *view;
    NSCharacterSet *separators;

    // Document Attributes.
    NSRect boundingBox;
    NSArray *dashArray;
    double dashPhase;
    double flatness;
    AJRLineJoinStyle lineJoin;
    AJRLineCapStyle lineCap;
    double miterLimit;
    double lineWidth;
    NSColor *strokeColor;
    NSColor *fillColor;
    AJRBezierPath *path;
    NSInteger textType;
    NSMutableParagraphStyle *paragraphStyle;
    NSMutableDictionary *attributes;
    NSMutableAttributedString *string;
    NSInteger textRenderingType;
    CGFloat textOffset;
    NSPoint textOrigin;

    struct _aiFlags {
        BOOL                    locked:1;
        BOOL                    winding:1;
        BOOL                    overprintStroke:1;
        BOOL                    overprintFill:1;
        NSUInteger              _reserved:28;
    } aiFlags;
}

@end
