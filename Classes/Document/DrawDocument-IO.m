
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
        fileWrapper = [filter fileWrapperForDocument:self error:&localError];
    }

    return AJRAssertOrPropagateError(fileWrapper, error, localError);
}

- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError *__autoreleasing  _Nullable *)outError {
    AJRLog(DrawDocumentLogDomain, AJRLogLevelDebug, @"Writing to %@", url.path);
    return [super writeToURL:url ofType:typeName forSaveOperation:NSSaveOperation originalContentsURL:absoluteOriginalContentsURL error:outError];
}

#pragma mark - AJRXMLCoding

- (void)encodeWithXMLCoder:(AJRXMLCoder *)coder {
    AJRAssert(NO, @"Don't pass DrawDocument to XML Encoding. Only pass it's storage.");
}

@end
