/* DrawAspectInspector.h created by alex on Fri 16-Oct-1998 */

#import "DrawInspectorModule.h"

@interface DrawAspectInspector : DrawInspectorModule
{
   IBOutlet NSButton		*activeCheck;
}

- (void)graphicDidInit:(DrawGraphic *)aGraphic;

- (NSString *)aspectKey;
- (DrawAspect *)aspectWithGraphic:(DrawGraphic *)graphic;

- (void)setActive:(BOOL)flag;
- (BOOL)active;
- (void)toggleActive:(id)sender;

@end
