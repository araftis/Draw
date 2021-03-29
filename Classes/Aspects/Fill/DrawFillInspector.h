
#import <Draw/DrawAspectInspector.h>

extern NSString *DrawFillKey;

@interface DrawFillInspector : DrawAspectInspector
{
   IBOutlet NSColorWell		*fillColorWell;
   IBOutlet NSMatrix		*fillTypeMatrix;
   
   NSMutableArray			*fills;
}

- (void)setFillColor:(id)sender;
- (void)selectFillType:(id)sender;

- (NSUInteger)tagForFillNamed:(NSString *)name;
- (Class)fillClassForName:(NSString *)name;

- (Class)fillClass;

@end
