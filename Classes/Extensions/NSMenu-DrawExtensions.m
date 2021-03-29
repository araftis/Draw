/*
NSMenu-DrawExtensions.m
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
/* NSMenu-DrawExtensions.m created by alex on Tue 09-Mar-1999 */

#import "NSMenu-DrawExtensions.h"

@implementation NSMenu (DrawExtensions)

- (id)copyWithZone:(NSZone *)zone
{
   NSMenu		*copy;
   NSArray		*items = [self itemArray];
   NSInteger			x;
   NSMenuItem	*item, *copiedItem;

   copy = [[NSMenu allocWithZone:zone] initWithTitle:[self title]];

   for (x = 0; x < (const NSInteger)[items count]; x++) {
      item = [items objectAtIndex:x];
      [copy addItemWithTitle:[item title] action:[item action] keyEquivalent:[item keyEquivalent]];
      copiedItem = [[copy itemArray] lastObject];
      if ([item hasSubmenu]) {
         NSMenu	*submenuCopy = [[item target] copyWithZone:zone];
         [copy setSubmenu:submenuCopy forItem:copiedItem];
         //[submenuCopy release];
      } else {
         [copiedItem setTarget:[item target]];
         [copiedItem setAction:[item action]];
      }
      [copiedItem setTag:[item tag]];
      [copiedItem setEnabled:[item isEnabled]];
      [copiedItem setRepresentedObject:[item representedObject]];
   }

   [copy setAutoenablesItems:[self autoenablesItems]];
   [copy setMenuChangedMessagesEnabled:[self menuChangedMessagesEnabled]];
   [copy update];

   return copy;
}

@end
