/* DrawView-Undo.m created by alex on Tue 27-Oct-1998 */

#import "DrawDocument.h"

#import "DrawDocumentStorage.h"

@implementation DrawDocument (Undo)

- (void)registerUndoWithTarget:(id)target selector:(SEL)aSelector object:(id)anObject {
   if (![[self undoManager] isUndoing] && ![[self undoManager] isRedoing]) {
      NSDate *newTime = [NSDate date];
      
      if (fabs([newTime timeIntervalSinceReferenceDate] - [_lastUndoTime timeIntervalSinceReferenceDate]) < 0.25) {
         if (_lastUndoTarget == target) {
            NSString *newAction = NSStringFromSelector(aSelector);
            
            if ([newAction isEqualToString:_lastUndoAction]) {
               _lastUndoTime = newTime;
               return;
            }
         }
      }
      _lastUndoTime = newTime;
      _lastUndoAction = NSStringFromSelector(aSelector);
      _lastUndoTarget = target;
   }
   [[self undoManager] registerUndoWithTarget:target selector:aSelector object:anObject];
}

- (void)registerUndoWithTarget:(id)target handler:(void (^)(id target))undoHandler {
    [[self undoManager] registerUndoWithTarget:target handler:undoHandler];
}

- (DrawDocument *)prepareUndoWithInvocation {
    return [self prepareWithInvocationTarget:self];
}

- (id)prepareWithInvocationTarget:(id)target {
   return [[self undoManager] prepareWithInvocationTarget:target];
}

- (void)setActionName:(NSString *)name {
   [[self undoManager] setActionName:name];
}

- (IBAction)undo:(id)sender {
   if ([[self undoManager] canUndo]) {
      [[self undoManager] undo];
      [[NSNotificationCenter defaultCenter] postNotificationName:DrawViewDidChangeSelectionNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:_storage.selection, DrawViewSelectionKey, nil]];
   }
}

- (IBAction)redo:(id)sender {
   if ([[self undoManager] canRedo]) {
      [[self undoManager] redo];
      [[NSNotificationCenter defaultCenter] postNotificationName:DrawViewDidChangeSelectionNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:_storage.selection, DrawViewSelectionKey, nil]];
   }
}

@end
