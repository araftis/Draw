
#import <AppKit/AppKit.h>
#import <AJRFoundation/AJRFoundation.h>

@class DrawDocument;

NS_ASSUME_NONNULL_BEGIN

@interface DrawLayer : NSObject <AJRXMLCoding>

- (id)initWithName:(NSString *)aName document:(DrawDocument *)aDocumentView;

@property (nonatomic,weak) DrawDocument *document;
@property (nonatomic,strong) NSString *name;
@property (nonatomic,assign) BOOL locked;
@property (nonatomic,assign) BOOL visible;
@property (nonatomic,assign) BOOL printable;

- (NSDictionary<NSString *, id> *)snapshot;
- (void)restoreFromSnapshot:(NSDictionary<NSString *, id> *)snapshot;

@end

NS_ASSUME_NONNULL_END
