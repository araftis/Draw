
#import <Draw/DrawGraphic.h>

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>
#import <Draw/DrawGraphic.h>

NS_ASSUME_NONNULL_BEGIN

@interface DrawAspect : NSObject <NSCopying, AJRXMLCoding>

#pragma mark - Factory

+ (void)registerAspect:(Class)aspect properties:(NSDictionary<NSString *, id> *)properties;
+ (NSArray<DrawAspect *> *)aspects;
+ (NSArray<NSString *> *)aspectIdentifiers;
+ (Class)aspectForIdentifier:(NSString *)identifier; 

@property (nonatomic,readonly,class) NSString *identifier;
@property (nonatomic,readonly,class) NSString *name;
@property (nonatomic,readonly,class) NSImage *image;
@property (nonatomic,readonly,class) DrawAspectPriority defaultPriority;

#pragma mark - Creation

+ (DrawAspect *)defaultAspectForGraphic:(DrawGraphic *)graphic;

- (id)initWithGraphic:(nullable DrawGraphic *)aGraphic;

#pragma mark - Properties

@property (nullable,nonatomic,weak) DrawGraphic *graphic;
@property (nonatomic,assign,getter=isActive) BOOL active;

#pragma mark - Drawing

- (DrawGraphicCompletionBlock)drawPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority;
- (AJRBezierPath *)renderPathForPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority;

- (BOOL)isPoint:(NSPoint)point inPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority;
- (BOOL)doesRect:(NSRect)rect intersectPath:(AJRBezierPath *)path withPriority:(DrawAspectPriority)priority;
- (BOOL)aspectAcceptsEdit;

- (AJRRectAdjustment)boundsAdjustment;
- (NSRect)boundsForPath:(AJRBezierPath *)path;
- (BOOL)boundsExpandsGraphicBounds;
- (NSRect)boundsForGraphicBounds:(NSRect)graphicBounds;

- (void)graphicWillAddToView:(DrawDocument *)view;
- (void)graphicDidAddToView:(DrawDocument *)aView;
- (void)graphicWillAddToPage:(DrawPage *)page;
- (void)graphicDidAddToPage:(DrawPage *)page;
- (void)graphicWillRemoveFromView:(DrawDocument *)aView;
- (void)graphicDidRemoveFromView:(DrawDocument *)aView;
- (void)graphicDidChangeShape:(DrawGraphic *)aGraphic;

- (BOOL)beginEditingFromEvent:(NSEvent *)anEvent;
- (void)endEditing;

#pragma mark - Equality

- (BOOL)isEqualToAspect:(DrawAspect *)aspect;

@end

NS_ASSUME_NONNULL_END
