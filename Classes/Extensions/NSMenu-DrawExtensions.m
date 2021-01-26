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
