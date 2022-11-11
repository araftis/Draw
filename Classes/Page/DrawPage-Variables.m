//
//  DrawPage-Variables.m
//  Draw
//
//  Created by AJ Raftis on 11/3/22.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

#import "DrawPage.h"

#import <Draw/Draw-Swift.h>

@implementation DrawPage (Variables)

- (void)addVariablesTo:(NSMutableArray <AJRVariable *> *)variables {
    [self.document addVariablesTo:variables];
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
    return [[DrawVariable alloc] initWithName:name type:type value:value document:self.document page:self];
}

- (void)store:(AJRStore *)store didAddVariable:(AJRVariable *)variable {
    [variable addListener:self];
    [self.document registerUndoWithTarget:self handler:^(DrawPage *target) {
        [self.variableStore removeVariable:variable];
    }];
}

- (void)store:(AJRStore *)store didRemoveVariable:(AJRVariable *)variable {
    [variable removeListener:self];
    [self.document registerUndoWithTarget:self handler:^(DrawPage *target) {
        // Theoretically, this is safe, because anything that would cause this to be a collision has been previously undone or redone.
        [target.variableStore addOrReplaceVariable:variable];
    }];
}

- (void)variable:(AJRVariable *)variable willChange:(AJRVariableChangeType)change {
    switch (change) {
        case AJRVariableChangeTypeName: {
            NSString *current = variable.name;
            [self.document registerUndoWithTarget:self handler:^(DrawPage *target) {
                variable.name = current;
            }];
            break;
        }
        case AJRVariableChangeTypeValue: {
            id current = variable.value;
            [self.document registerUndoWithTarget:self handler:^(DrawPage *target) {
                variable.value = current;
            }];
            break;
        }
        case AJRVariableChangeTypeVariableType: {
            AJRVariableType *current = variable.variableType;
            [self.document registerUndoWithTarget:self handler:^(id  _Nonnull target) {
                variable.variableType = current;
            }];
            break;
        }
    }
}

- (void)variable:(AJRVariable *)variable didChange:(AJRVariableChangeType)change {
}

@end
