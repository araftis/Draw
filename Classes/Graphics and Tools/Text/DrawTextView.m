
#import "DrawTextView.h"

@implementation DrawTextView

- (NSMenu *)menu {
   if (![self isEditable] && ![self isSelectable]) {
      return nil;
   }

   return [super menu];
}

- (void)mouseDown:(NSEvent *)anEvent {
   if (![self isEditable] && ![self isSelectable]) {
      void (*mouseDownFunction)(id, SEL, id);
      mouseDownFunction = (void (*)(id, SEL, id))[NSView instanceMethodForSelector:@selector(mouseDown:)];
      mouseDownFunction(self, @selector(mouseDown:), anEvent);
   } else {
      [super mouseDown:anEvent];
   }
}

@end
