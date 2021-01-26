/* DrawFileWrapper.m created by alex on Wed 24-Feb-1999 */

#import "DrawFileWrapper.h"

static NSMutableDictionary<NSURL *, DrawFileWrapper *> *wrappers = nil;

@implementation DrawFileWrapper

+ (void)initialize {
    wrappers = [[NSMutableDictionary alloc] init];
}

- (id)initWithURL:(NSURL *)url options:(NSFileWrapperReadingOptions)options error:(NSError **)error {
    DrawFileWrapper *wrapper = [wrappers objectForKey:[url URLByStandardizingPath]];

    if (wrapper) {
        return wrapper;
    }


    if ((self = [super initWithURL:url options:options error:error])) {
        [wrappers setObject:self forKey:[url URLByStandardizingPath]];
    }

    return self;
}

- (id)initRegularFileWithContents:(NSData *)contents {
    [NSException raise:NSInvalidArgumentException format:@"Draw wrappers can only be initialized with directories."];
    self = [super initRegularFileWithContents:contents];
    return nil;
}

- (BOOL)isDirectory {
    return YES;
}

- (BOOL)isRegularFile {
    return NO;
}

- (BOOL)isSymbolicLink {
    return NO;
}

- (BOOL)writeToURL:(NSURL *)url options:(NSFileWrapperWritingOptions)options originalContentsURL:(NSURL *)originalContentsURL error:(NSError *__autoreleasing  _Nullable *)outError {
    return NO;
}

@end
