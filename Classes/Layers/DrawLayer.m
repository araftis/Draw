/*
DrawLayer.m
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

#import "DrawLayer.h"

#import "DrawDocument.h"
#import <Draw/Draw-Swift.h>
#import "AJRXMLCoder-DrawExtensions.h"

@interface DrawDocument (PrivateLayer)

- (void)_resetLayerPopUpButton;
- (void)replaceNameOnLayerFromName:(NSString *)oldName toName:(NSString *)newName;

@end

@implementation DrawLayer

- (id)initWithName:(NSString *)aName document:(DrawDocument *)aDocumentView {
    if ((self = [super init])) {
        // Set should be done before setDrawView, since once we do that we'll have an undo manager.
        _variableStore = [[AJRStore alloc] init];
        [self setName:aName];
        [self setVisible:YES];
        [self setPrintable:YES];
        [self setLocked:NO];
        [self setDocument:aDocumentView];
    }
    return self;
}

#pragma mark - Properties

- (void)setName:(NSString *)aName {
    if (_name != aName && ![_name isEqualToString:aName]) {
        [[_document prepareWithInvocationTarget:_document] replaceNameOnLayerFromName:aName toName:_name];
        _name = aName;
        [_document _resetLayerPopUpButton];
    }
}

- (void)setLocked:(BOOL)flag {
    if (_locked != flag) {
        [[_document prepareWithInvocationTarget:self] restoreFromSnapshot:self.snapshot];
        _locked = flag;
        [_document setPagesNeedDisplay:YES];
    }
}

- (void)setVisible:(BOOL)flag {
    if (_visible != flag) {
        [[_document prepareWithInvocationTarget:self] restoreFromSnapshot:self.snapshot];
        _visible = flag;
        [_document setPagesNeedDisplay:YES];
    }
}

- (void)setPrintable:(BOOL)flag {
    if (_printable != flag) {
        [[_document prepareWithInvocationTarget:self] restoreFromSnapshot:self.snapshot];
        _printable = flag;
        [_document setPagesNeedDisplay:YES];
    }
}

- (void)setDocument:(DrawDocument *)document {
    // Make sure our variables points to our document.
    [_variableStore enumerate:^(NSString *name, id <AJREvaluation> value, BOOL *stop) {
        DrawVariable *variable = AJRObjectIfKindOfClass(value, DrawVariable);
        if (variable != nil) {
            variable.document = document;
            variable.layer = self;
        }
    }];
}

#pragma mark - Snapshotting

- (NSDictionary *)snapshot {
    return @{@"name":_name, @"locked":@(_locked), @"visible":@(_visible), @"printable":@(_printable)};
}

- (void)restoreFromSnapshot:(NSDictionary *)snapshot {
    [self setName:snapshot[@"name"]];
    [self setVisible:[snapshot[@"visible"] boolValue]];
    [self setPrintable:[snapshot[@"printable"] boolValue]];
    [self setLocked:[snapshot[@"locked"] boolValue]];
}

#pragma mark - AJRXMLCoding

+ (NSString *)ajr_nameForXMLArchiving {
    return @"layer";
}

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [coder decodeObjectForKey:@"name" setter:^(id  _Nullable object) {
        self->_name = object;
    }];
    [coder decodeBoolForKey:@"locked" setter:^(BOOL value) {
        self->_locked = value;
    }];
    [coder decodeBoolForKey:@"visible" setter:^(BOOL value) {
        self->_visible = value;
    }];
    [coder decodeBoolForKey:@"printable" setter:^(BOOL value) {
        self->_printable = value;
    }];
    [coder decodeObjectForKey:@"variableStore" setter:^(id object) {
        if (object == nil) {
            self->_variableStore = [[AJRStore alloc] init];
        } else {
            self->_variableStore = object;
        }
    }];
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)coder {
    [coder encodeString:_name forKey:@"name"];
    [coder encodeBool:_locked forKey:@"locked"];
    [coder encodeBool:_visible forKey:@"visible"];
    [coder encodeBool:_printable forKey:@"printable"];
    if (_variableStore.count > 0) {
        // Let's only encode this if it matters, since it usually won't.
        [coder encodeObject:_variableStore forKey:@"variableStore"];
    }
}

@end
