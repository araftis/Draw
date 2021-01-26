/* DrawLinkCap.h created by alex on Thu 18-Feb-1999 */

#import <AppKit/AppKit.h>
#import <AJRFoundation/AJRFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class DrawGraphic, DrawLink, AJRBezierPath;

typedef NS_ENUM(uint8_t, DrawLinkCapType) {
    DrawLinkCapTypeHead,
    DrawLinkCapTypeTail
};

extern NSString *DrawStringFromLinkCapType(DrawLinkCapType type);
extern DrawLinkCapType DrawLinkCapTypeFromString(NSString *string);

extern NSString *DrawLinkCapHeadStyleKey;
extern NSString *DrawLinkCapHeadThicknessKey;
extern NSString *DrawLinkCapHeadLengthKey;
extern NSString *DrawLinkCapHeadFilledKey;
extern NSString *DrawLinkCapTailStyleKey;
extern NSString *DrawLinkCapTailThicknessKey;
extern NSString *DrawLinkCapTailLengthKey;
extern NSString *DrawLinkCapTailFilledKey;

@interface DrawLinkCap : NSObject <NSCopying, AJRXMLCoding>

/*!
 Creates a default styled link cap. Note that this not the preferred initializer. You should call -initWithType: instead, as knowing whether the cap is a head or tail cap can be important. This initializer is primarily used for archiving purposes.

 @return A newly created, default link cap.
 */
- (id)init;

/*!
 Create a new link cap that will act as either a "head" or "tail" cap. A head cap points into the destination graphic while the tail cap points back to the source graphic.

 @param type The type of the link cap.

 @return A newly created link cap.
 */
- (id)initWithType:(DrawLinkCapType)type;

- (void)graphicDidChangeShape:(DrawGraphic *)aGraphic;

- (void)linkCapWillAddToLink:(DrawLink *)aLink asType:(DrawLinkCapType)aType;
- (void)linkCapDidAddToLink:(DrawLink *)aLink asType:(DrawLinkCapType)aType;
- (void)linkCapWillRemoveFromLink:(DrawLink *)aLink;
- (void)linkCapDidRemoveFromLink:(DrawLink *)aLink;

@property (nonatomic,readonly,weak) DrawLink *link;
@property (nonatomic,readonly) DrawLinkCapType capType;
@property (nonatomic,assign) CGFloat thickness;
@property (nonatomic,assign) CGFloat length;
@property (nonatomic,assign) BOOL filled;
@property (nonatomic,readonly) AJRBezierPath *path;

- (NSPoint)initialPointFromPoint:(NSPoint)originalPoint;

- (void)update;

+ (NSImage *)sourceImageFilled:(BOOL)flag;
+ (NSImage *)destinationImageFilled:(BOOL)flag;

#pragma mark - Equality

- (BOOL)isEqualToLinkCap:(DrawLinkCap *)other;

@end

NS_ASSUME_NONNULL_END
