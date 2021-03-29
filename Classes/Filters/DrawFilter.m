
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

- (nullable NSFileWrapper *)fileWrapperForDocument:(DrawDocument *)document error:(NSError **)error {
    NSError *localError = [NSError errorWithDomain:DrawDocumentErrorDomain format:@"%C cannot write files.", self];
    AJRSetOutParameter(error, localError);
    return nil;
}

@end
