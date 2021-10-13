/*
DrawDocument-IO.m
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

#import "DrawDocument.h"

#import "DrawDocumentStorage.h"
#import "DrawBook.h"
#import "DrawGraphic.h"
#import "DrawFilter.h"
#import "DrawViewRulerAccessory.h"
#import "AJRXMLCoder-DrawExtensions.h"

#import <AJRFoundation/AJRFoundation.h>

NSString * const DrawOpenPanelPathKey = @"DrawOpenPanelPathKey";
NSString * const DrawSavePanelPathKey = @"DrawSavePanelPathKey";
NSString * const DrawViewDidChangeURLNotification = @"DrawViewDidChangeURLNotification";
NSString * const DrawViewOldURLKey = @"DrawViewOldURLKey";
NSString * const DrawViewNewURLKey = @"DrawViewNewURLKey";

@implementation DrawDocument (IO)

- (NSArray *)readableTypes {
    return [DrawFilter readableFilterTypes];
}

- (NSArray *)writableTypes {
    return [DrawFilter writableFilterTypes];
}

- (void)setFileURL:(NSURL *)url {
    if (![url isEqualToURL:[self fileURL]]) {
        NSURL *oldFileURL = [self fileURL];
        
        [super setFileURL:url];
        
        if (oldFileURL) {
            [[NSNotificationCenter defaultCenter] postNotificationName:DrawViewDidChangeURLNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:oldFileURL, DrawViewOldURLKey, [self fileURL], DrawViewNewURLKey, nil]];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:DrawViewDidChangeURLNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[self fileURL], DrawViewNewURLKey, nil]];
        }
    }
}

#pragma mark - NSDocument

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError **)outError {
    // This is a bit of a "workaround". It seems that in general, but often for us, after we write
    // a new file wrapper out, the document sees the on disk version as having changed, which then
    // leads us to re-reading the on contents disk. In some ways that's not harmful, but if can
    // interrupt certain editing operations, which is annoying.
    if (![_fileWrapper contentsAreSameAs:fileWrapper]) {
        DrawFilter *filter = [DrawFilter readFilterForType:typeName];
        if (!filter) {
            if (outError) {
                *outError = [NSError errorWithDomain:DrawDocumentErrorDomain code:-1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"There is no registered input filter for the file type '%@'.", typeName], NSLocalizedDescriptionKey, nil]];
            }
            return NO;
        }

        [DrawGraphic disableNotifications];
        [[self undoManager] disableUndoRegistration];

        if (![filter readDocument:self fromFileWrapper:fileWrapper error:outError]) {
            return NO;
        }
        
        [[self undoManager] enableUndoRegistration];
        [DrawGraphic enableNotifications];
    }

    // Whether we've read a new wrapper, or whether we're just referencing a new wrapper, go a
    // ahead and save the new wrapper. In the latter case, this'll make sure we have all the current,
    // up-to-date modification times.
    _fileWrapper = fileWrapper;

    return YES;
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
    AJRLog(DrawDocumentLogDomain, AJRLogLevelDebug, @"Reading from %@", url.path);
    return [super readFromURL:url ofType:typeName error:outError];
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError * _Nullable *)error {
    NSError *localError = nil;
    DrawFilter *filter = nil;
    NSFileWrapper *fileWrapper = nil;
    
    filter = [DrawFilter writeFilterForType:typeName];
    if (filter == nil) {
        localError = [NSError errorWithDomain:DrawDocumentErrorDomain format:@"There is not registered output filter for the file type '%@'.", typeName];
    } else {
        fileWrapper = [filter updateFileWrapper:_fileWrapper forDocument:self error:&localError];
        if (fileWrapper != _fileWrapper) {
            _fileWrapper = fileWrapper;
        }
    }

    return AJRAssertOrPropagateError(fileWrapper, error, localError);
}

//- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError *__autoreleasing  _Nullable *)outError {
//    AJRLog(DrawDocumentLogDomain, AJRLogLevelDebug, @"Writing to %@", url.path);
//    return [super writeToURL:url ofType:typeName forSaveOperation:NSSaveOperation originalContentsURL:absoluteOriginalContentsURL error:outError];
//}

#pragma mark - AJRXMLCoding

- (void)encodeWithXMLCoder:(AJRXMLCoder *)coder {
    AJRAssert(NO, @"Don't pass DrawDocument to XML Encoding. Only pass it's storage.");
}

@end
