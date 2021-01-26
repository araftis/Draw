/* DrawEPSImageRep.m created by alex on Wed 28-Oct-1998 */

#import "DrawEPSImageRep.h"

#import <ASFoundation/ASFoundation.h>
#import <PS/PSInterpreter.h>
#import <PS/PSShowPageAction.h>

#ifdef WIN32
#import "PROCESS.H"
#endif

static PSInterpreter		*_drawInterpreter = nil;
static NSMutableArray	*_drawActions = nil;
static NSLock				*_drawLock = nil;

@implementation DrawEPSImageRep

+ (void)load
{
   [self poseAsClass:[NSEPSImageRep class]];
}

- (BOOL)draw
{
   NSMutableArray		*actions = [self actions];
   NSGraphicsContext	*context;
   
   if (!actions) {
      [self setActions:[NSArray array]];
      actions = [self actions];
      if (!_drawLock) {
         _drawLock = [[NSLock alloc] init];
      }
      [_drawLock lock];
      NS_DURING
         if (!_drawInterpreter) {
            _drawInterpreter = [[PSInterpreter alloc] init];
         }
         _drawActions = [actions retain];
         [_drawInterpreter setDelegate:self];
         [_drawInterpreter setString:[[[NSString alloc] initWithData:[self EPSRepresentation] encoding:NSISOLatin1StringEncoding] autorelease]];
         [_drawInterpreter prepareForExecution];
         [_drawInterpreter execute];
         [_drawInterpreter setString:nil];
         [_drawInterpreter setDelegate:nil];
         [_drawActions release]; _drawActions = nil;
      NS_HANDLER
         // Ignore the error states.
      NS_ENDHANDLER
      [_drawLock unlock];
   }
   
   context = [NSGraphicsContext currentContext];
   [[NSColor blackColor] set];
   [context prepareForPSExecution];
   [actions makeObjectsPerformSelector:@selector(performWithContext:) withObject:context];
   /* Need an implementation for this
   [[NSGraphicsContext currentContext] printFormat:@"clippath true setglobal /__ClippingUPath%d [ false upath ] /Generic defineresource false setglobal\n", getpid()];
   */
   
   return YES;
}

- (void)prepareGState
{
   /* Need an implementation for this
   [[NSGraphicsContext currentContext] printFormat:@"/__ClippingUPath%d /Generic findresource 0 get uappend clip true setglobal /__ClippingUPath%d /Generic undefineresource false setglobal\n", getpid(), getpid()];
   */
}

- (NSMutableArray *)actions
{
   return [self instanceObjectForKey:@"actions"];
}

- (void)setActions:(NSMutableArray *)actions
{
   NSMutableArray		*temp = [actions mutableCopyWithZone:[self zone]];
   
   [self setInstanceObject:temp forKey:@"actions"];
   [temp release];
}

- (void)interpreter:(PSInterpreter *)sender recordAction:(id <PSAction>)action
{     
   if (![action isKindOfClass:[PSShowPageAction class]]) {
      [_drawActions addObject:action];
   }
}

@end
