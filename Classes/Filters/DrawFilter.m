/*
 DrawFilter.m
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

#import "DrawFilter.h"

#import "DrawDocument.h"
#import "DrawLogging.h"

@implementation DrawFilter

static NSMutableDictionary<NSString *, DrawFilter *> *_readFilters = nil;
static NSMutableDictionary<NSString *, DrawFilter *> *_writeFilters = nil;

#pragma mark - Initialization

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _readFilters = [[NSMutableDictionary alloc] init];
        _writeFilters = [[NSMutableDictionary alloc] init];
    });
}

#pragma mark - Factory

+ (void)registerFilter:(Class)filterClass properties:(NSDictionary<NSString *, id> *)properties {
    @autoreleasepool {
        AJRLog(DrawPlugInLogDomain, AJRLogLevelDebug, @"Filter: %C", filterClass);

        DrawFilter *filter = [[filterClass alloc] init];
        DrawFilter *existingFilter;

        for (NSString *type in [properties[@"readableTypes"] valueForKeyPath:@"type"]) {
            existingFilter = [_readFilters objectForKey:type];
            if (existingFilter) {
                [NSException raise:NSInternalInconsistencyException format:@"The filter type %@ has already been registered by the input filter %@, loaded from bundle %@.", type, [filter class], [[NSBundle bundleForClass:[filter class]] bundlePath]];
            }
            [_readFilters setObject:filter forKey:type];
        }
        for (NSString *type in [properties[@"writableTypes"] valueForKeyPath:@"type"]) {
            existingFilter = [_writeFilters objectForKey:type];
            if (existingFilter) {
                [NSException raise:NSInternalInconsistencyException format:@"The filter type %@ has already been registered by the input filter %@, loaded from bundle %@.", type, [filter class], [[NSBundle bundleForClass:[filter class]] bundlePath]];
            }
            [_writeFilters setObject:filter forKey:type];
        }
    }
}

+ (DrawFilter *)readFilterForType:(NSString *)type {
    return [_readFilters objectForKey:type];
}

+ (DrawFilter *)writeFilterForType:(NSString *)type {
    return [_writeFilters objectForKey:type];
}

+ (NSArray<NSString *> *)readableFilterTypes {
    return [_readFilters allKeys];
}

+ (NSArray<NSString *> *)writableFilterTypes {
    return [_writeFilters allKeys];
}

#pragma mark - Information

- (NSArray<NSString *> *)readableTypes {
    return [[[[AJRPlugInManager sharedPlugInManager] extensionPointForName:@"draw-filter"] valueForProperty:@"readableTypes" onExtensionForClass:[self class]] valueForKeyPath:@"type"];
}

- (NSArray<NSString *> *)writableTypes {
    return [[[[AJRPlugInManager sharedPlugInManager] extensionPointForName:@"draw-filter"] valueForProperty:@"writableTypes" onExtensionForClass:[self class]] valueForKeyPath:@"type"];
}

#pragma mark - I/O

- (BOOL)readDocument:(DrawDocument *)document fromFileWrapper:(NSFileWrapper *)fileWrapper error:(NSError **)error {
    NSError *localError = [NSError errorWithDomain:DrawDocumentErrorDomain format:@"%C cannot read files.", self];
    AJRSetOutParameter(error, localError);
    return NO;
}

- (nullable NSFileWrapper *)updateFileWrapper:(nullable NSFileWrapper *)fileWrapper forDocument:(DrawDocument *)document error:(NSError **)error {
    NSError *localError = [NSError errorWithDomain:DrawDocumentErrorDomain format:@"%C cannot write files.", self];
    AJRSetOutParameter(error, localError);
    return nil;
}

@end
