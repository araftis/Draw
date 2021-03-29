/*
DrawEPSImageRep.m
Draw

Copyright © 2021, AJ Raftis and AJRFoundation authors
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this 
  list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, 
  this list of conditions and the following disclaimer in the documentation 
  and/or other materials provided with the distribution.
* Neither the name of Draw nor the names of its contributors may be 
  used to endorse or promote products derived from this software without 
  specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL AJ RAFTIS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
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
