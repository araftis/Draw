/*
 DrawDocument-Variables.m
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
#import <Draw/Draw-Swift.h>

@implementation DrawDocument (Variables)

- (void)addVariablesTo:(NSMutableArray <AJRVariable *> *)variables {
    for (NSString *name in self.variableStore.orderedNames) {
        AJRVariable *variable = AJRObjectIfKindOfClass(self.variableStore[name], AJRVariable);
        if (variable != nil && ![variables containsVariable:variable]) {
            [variables addObject:variable];
        }
    }
}

- (NSMutableArray <AJRVariable *> *)variables {
    NSMutableArray <AJRVariable *> *variables = [NSMutableArray array];
    [self addVariablesTo:variables];
    return variables;
}

- (AJRVariable *)createVariableWithName:(NSString *)name type:(AJRVariableType *)type value:(id)value inStore:(AJRStore *)store {
    return [[DrawVariable alloc] initWithName:name type:type value:value document:self];
}

- (void)store:(AJRStore *)store didAddVariable:(AJRVariable *)variable {
    [variable addListener:self];
    [self registerUndoWithTarget:self handler:^(id  _Nonnull target) {
        [self.variableStore removeVariable:variable];
    }];
}

- (void)store:(AJRStore *)store didRemoveVariable:(AJRVariable *)variable {
    [variable removeListener:self];
    [self registerUndoWithTarget:self handler:^(id  _Nonnull target) {
        // Theoretically, this is safe, because anything that would cause this to be a collision has been previously undone or redone.
        [self.variableStore addOrReplaceVariable:variable];
    }];
}

- (void)variable:(AJRVariable *)variable willChange:(AJRVariableChangeType)change {
    switch (change) {
        case AJRVariableChangeTypeName: {
            NSString *current = variable.name;
            [self registerUndoWithTarget:self handler:^(id  _Nonnull target) {
                variable.name = current;
            }];
            break;
        }
        case AJRVariableChangeTypeValue: {
            id current = variable.value;
            [self registerUndoWithTarget:self handler:^(id  _Nonnull target) {
                variable.value = current;
            }];
            break;
        }
        case AJRVariableChangeTypeVariableType: {
            AJRVariableType *current = variable.variableType;
            [self registerUndoWithTarget:self handler:^(id  _Nonnull target) {
                variable.variableType = current;
            }];
            break;
        }
    }
}

- (void)variable:(AJRVariable *)variable didChange:(AJRVariableChangeType)change {
}

@end
