/* DrawPapelFilter.m created by alex on Wed 24-Feb-1999 */

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

- (NSFileWrapper *)fileWrapperForDocument:(DrawDocument *)document error:(NSError **)error {
    NSData *data = [AJRXMLArchiver archivedDataWithRootObject:document.storage forKey:@"document"];

    AJRLogDebug(DrawDocumentLogDomain, AJRLogLevelDebug, @"%@\n", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

    NSFileWrapper *childWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:data];
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{[@"document" stringByAppendingPathExtension:self.documentFileExtension]:childWrapper}];
    
    return fileWrapper;
}

@end
