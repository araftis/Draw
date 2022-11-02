/*
 DrawPapelFilter.m
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

#import "DrawPapelFilter.h"

#import "DrawDocumentP.h"
#import "DrawDocumentStorage.h"

#import <AJRFoundation/AJRFoundation.h>

@implementation DrawPapelFilter

- (NSString *)documentFileExtension {
    return @"papel";
}

- (BOOL)readDocument:(DrawDocument *)document fromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError *__autoreleasing  _Nullable *)error {
    NSError *localError = nil;
    NSFileWrapper *storageWrapper = nil;
    BOOL success = NO;

    NSString *documentFileName = [@"document" stringByAppendingPathExtension:self.documentFileExtension];
    storageWrapper = fileWrapper.fileWrappers[documentFileName];
    if (storageWrapper == nil) {
        localError = [NSError errorWithDomain:DrawDocumentErrorDomain format:@"File package is corrupt. It does not contain a file named “%@”.", documentFileName];
    } else {
        DrawDocumentStorage *storage = [AJRXMLUnarchiver unarchivedObjectWithData:storageWrapper.regularFileContents topLevelClass:[[document class] storageClass] error:&localError];

        if (storage != nil) {
            success = YES;
            [document setStorage:storage];
        }
    }

    return AJRAssertOrPropagateError(success, error, localError);
}

- (NSFileWrapper *)updateFileWrapper:(nullable NSFileWrapper *)fileWrapper forDocument:(DrawDocument *)document error:(NSError **)error {
    NSFileWrapper *newFileWrapper = fileWrapper;
    NSError *localError = nil;
    NSData *data = [AJRXMLArchiver archivedDataWithRootObject:document.storage forKey:@"document"];

    AJRLogDebug(DrawDocumentLogDomain, AJRLogLevelDebug, @"%@\n", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

    NSString *childName = [@"document" stringByAppendingPathExtension:self.documentFileExtension];
    if (newFileWrapper == nil) {
        newFileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}];
    }
    [newFileWrapper replaceOrAddRegularFileWithContents:data preferredFilename:childName];
    
    return AJRAssertOrPropagateError(newFileWrapper, error, localError);
}

@end
