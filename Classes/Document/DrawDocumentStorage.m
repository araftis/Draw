//
//  DrawDocumentStorage.m
//  Draw
//
//  Created by Alex Raftis on 5/30/14.
//  Copyright (c) 2014 Apple, Inc. All rights reserved.
//

#import "DrawDocumentStorage.h"

#import "DrawDocument.h"
#import "DrawLayer.h"

#import <AJRInterface/AJRInterface.h>

@implementation DrawDocumentStorage

#pragma mark - Properties

- (void)setPageNumber:(NSInteger)pageNumber {
    // Do some sanity checking
    if (pageNumber < 1 || pageNumber > _pages.count) {
        AJRLog(DrawDocumentLogDomain, AJRLogLevelWarning, @"Invalid page number: %ld, resetting to 1.", pageNumber);
        _pageNumber = 1;
    } else {
        _pageNumber = pageNumber;
    }
}

#pragma mark - NSCoding

+ (NSString *)ajr_nameForXMLArchiving {
    return @"document";
}

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    // Print Info
    [coder decodeObjectForKey:@"printInfo" setter:^(id _Nullable object) {
        self->_printInfo = object;
    }];

    // Basic Properties
    [coder decodeObjectForKey:@"paperColor" setter:^(id _Nullable object) {
        self->_paperColor = object;
    }];

    // Snap Lines
    [coder decodeObjectForKey:@"markColor" setter:^(id _Nullable object) {
        self->_markColor = object;
    }];
    [coder decodeObjectForKey:@"horizontalMarks" setter:^(id _Nullable object) {
        self->_horizontalMarks = [object mutableCopy];
    }];
    [coder decodeObjectForKey:@"verticalMarks" setter:^(id _Nullable object) {
        self->_verticalMarks = [object mutableCopy];
    }];

    // Grid
    [coder decodeObjectForKey:@"gridColor" setter:^(id _Nullable object) {
        self->_gridColor = object;
    }];
    [coder decodeDoubleForKey:@"gridSpacing" setter:^(double value) {
        self->_gridSpacing = value;
    }];

    // Pages
    [coder decodeObjectForKey:@"pages" setter:^(id _Nullable object) {
        self->_pages = object;
    }];
    [coder decodeObjectForKey:@"masterPageEven" setter:^(id _Nullable object) {
        self->_masterPageEven = object;
    }];
    [coder decodeObjectForKey:@"masterPageOdd" setter:^(id _Nullable object) {
        self->_masterPageOdd = object;
    }];
    [coder decodeIntegerForKey:@"pageNumber" setter:^(NSInteger value) {
        self->_pageNumber = value;
    }];
    [coder decodeIntegerForKey:@"startingPageNumber" setter:^(NSInteger value) {
        self->_startingPageNumber = value;
    }];

    // Layers
    [coder decodeObjectForKey:@"layers" setter:^(id _Nullable object) {
        self->_layers = object;
    }];
    [coder decodeStringForKey:@"layer" setter:^(NSString  * _Nullable object) {
        // This is a little dicey, but I'm taking the easy path. It's dicey, because we're not guaranteed that _layers will be initialized before _layer. But, worse come to worse, we won't find a layer, and the layer will be set to the first layer.
        for (DrawLayer *layer in self->_layers) {
            if ([layer.name isEqualToString:object]) {
                self->_layer = layer;
                break;
            }
        }
    }];

    // Selection
    [coder decodeObjectForKey:@"selection" setter:^(id _Nullable object) {
        self->_selection = object;
    }];

    // Copy and Paste
    [coder decodePointForKey:@"copyDelta" setter:^(CGPoint point) {
        self->_copyDelta = point;
    }];
    [coder decodeSizeForKey:@"copyOffset" setter:^(CGSize size) {
        self->_copyOffset = size;
    }];

    // Groups
    [coder decodeObjectForKey:@"group" setter:^(id _Nullable object) {
        self->_group = object;
    }];

    // State
    [coder decodeObjectForKey:@"templateGraphic" setter:^(id _Nullable object) {
        self->_templateGraphic = object;
    }];

    // Book
    [coder decodeObjectForKey:@"chapterName" setter:^(id _Nullable object) {
        self->_chapterName = object;
    }];

    // Flags
    [coder decodeBoolForKey:@"gridEnabled" setter:^(BOOL value) {
        self->_gridEnabled = value;
    }];
    [coder decodeBoolForKey:@"gridVisible" setter:^(BOOL value) {
        self->_gridVisible = value;
    }];
    [coder decodeBoolForKey:@"marksEnabled" setter:^(BOOL value) {
        self->_marksEnabled = value;
    }];
    [coder decodeBoolForKey:@"marksVisible" setter:^(BOOL value) {
        self->_marksVisible = value;
    }];
}

- (id)finalizeXMLDecodingWithError:(NSError * _Nullable __autoreleasing *)error {
    if (_layer == nil) {
        // In case a default layer wasn't loaded or found...
        _layer = [_layers firstObject];
    }
    // Make sure the page number is sane.
    if (_pageNumber < 0 || _pageNumber >= _pages.count) {
        _pageNumber = 1;
    }
    return self;
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)coder {
    // Print Info
    [coder encodeObject:_printInfo forKey:@"printInfo"];

    // Basic Attribuets
    [coder encodeObject:_paperColor forKey:@"paperColor"];

    // Snap Lines
    [coder encodeObject:_markColor forKey:@"markColor"];
    [coder encodeObject:_horizontalMarks forKey:@"horizontalMarks"];
    [coder encodeObject:_verticalMarks forKey:@"verticalMarks"];

    // Grid
    [coder encodeObject:_gridColor forKey:@"gridColor"];
    [coder encodeFloat:_gridSpacing forKey:@"gridSpacing"];

    // Layers
    // NOTE: Encode before pages. This makes sure the layers are written to the XML, keeping the pages neater.
    [coder encodeObject:_layers forKey:@"layers"];
    [coder encodeString:_layer.name forKey:@"layer"];

    // Pages
    [coder encodeObject:_pages forKey:@"pages"];
    [coder encodeObject:_masterPageEven forKey:@"masterPageEven"];
    [coder encodeObject:_masterPageOdd forKey:@"masterPageOdd"];
    [coder encodeInteger:_pageNumber forKey:@"pageNumber"];
    [coder encodeInteger:_startingPageNumber forKey:@"startingPageNumber"];

    // Selection
    [coder encodeObject:_selection forKey:@"selection"];

    // Copy and Paste
    [coder encodePoint:_copyDelta forKey:@"copyDelta"];
    [coder encodeSize:_copyOffset forKey:@"copyOffset"];

    // Groups
    [coder encodeObjectIfNotNil:_group forKey:@"group"];

    // State
    [coder encodeObject:_templateGraphic forKey:@"templateGraphic"];

    // Book
    [coder encodeString:_chapterName forKey:@"chapterName"];

    // Flags
    [coder encodeBool:_gridEnabled forKey:@"gridEnabled"];
    [coder encodeBool:_gridVisible forKey:@"gridVisible"];
    [coder encodeBool:_marksEnabled forKey:@"marksEnabled"];
    [coder encodeBool:_marksVisible forKey:@"marksVisible"];
}

@end
