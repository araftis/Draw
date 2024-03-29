/*
 DrawDocument-Undo.m
 Draw

 Copyright © 2022, AJ Raftis and Draw authors
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

#import "DrawDocument.h"

#import "DrawGraphic.h"
#import "DrawDocumentStorage.h"

@implementation DrawDocument (Undo)

- (void)editWithoutUndoTracking:(void (^)(void))block {
    [self disableUndoRegistration];
    NSException *exception = nil;
    @try {
        block();
    } @catch (NSException *localException) {
        exception = localException;
    }
    [self enableUndoRegistration];
    if (exception != nil) {
        @throw exception;
    }
}

- (void)disableUndoRegistration {
    [self.undoManager disableUndoRegistration];
}

- (void)enableUndoRegistration {
    [self.undoManager enableUndoRegistration];
}

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

- (void)addGraphicObserver:(id <DrawDocumentGraphicObserver>)observer {
    [_graphicObservers addObject:observer];
}

- (void)removeGraphicObserver:(id <DrawDocumentGraphicObserver>)observer {
    [_graphicObservers removeObjectIdenticalTo:observer];
}

#pragma mark - AJREditingContextDelegate

- (void)editingContext:(AJREditingContext *)editingContext didObserveEditsForKeys:(NSSet *)keys onObject:(id)object {
    DrawGraphic *graphic = AJRObjectIfKindOfClass(object, DrawGraphic);
    if (graphic != nil) {
        for (id <DrawDocumentGraphicObserver> observer in _graphicObservers) {
            [observer graphic:object didEditKeys:keys];
        }
    }
}

/*!
 Respond to the editing context tracking a change, but we're going to return `NO`, because we want to register the undos ourself.
 
 @param editingContext The editing context that tracked the change.
 @param value The new value.
 @param key The key on the obejct that changed.
 @param object The obejct that changed.
 
 @return Always returns `NO`, because we want to track the change ourself.
 */
- (BOOL)editingContext:(AJREditingContext *)editingContext shouldRegisterUndoOfValue:(id)value forKey:(NSString *)key onObject:(id)object {
    [self registerUndoWithTarget:object handler:^(AJREditableObject *target) {
        [target undoValue:value forKey:key];
    }];
    return NO;
}

@end
