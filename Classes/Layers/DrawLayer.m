/* DrawLayer.m created by alex on Tue 06-Oct-1998 */

#import "DrawLayer.h"

#import "DrawDocument.h"
#import "AJRXMLCoder-DrawExtensions.h"

@interface DrawDocument (PrivateLayer)

- (void)_resetLayerPopUpButton;
- (void)replaceNameOnLayerFromName:(NSString *)oldName toName:(NSString *)newName;

@end

@implementation DrawLayer

- (id)initWithName:(NSString *)aName document:(DrawDocument *)aDocumentView {
    if ((self = [super init])) {
        // Set should be done before setDrawView, since once we do that we'll have an undo manager.
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
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)coder {
    [coder encodeString:_name forKey:@"name"];
    [coder encodeBool:_locked forKey:@"locked"];
    [coder encodeBool:_visible forKey:@"visible"];
    [coder encodeBool:_printable forKey:@"printable"];
}

@end
