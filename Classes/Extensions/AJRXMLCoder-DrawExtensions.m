
#import "AJRXMLCoder-DrawExtensions.h"

@implementation AJRXMLCoder (DrawExtensions)

- (void)encodeDrawHandle:(DrawHandle)handle forKey:(NSString *)key {
    if (handle.type == DrawHandleTypeMissed) {
        [self encodeString:@"Missed" forKey:key];
    } else if (handle.type == DrawHandleTypeIndexed) {
        if (handle.subindex == 0) {
            [self encodeString:AJRFormat(@"%ld", (long)handle.elementIndex) forKey:key];
        } else {
            [self encodeString:AJRFormat(@"%ld:%ld", (long)handle.elementIndex, (long)handle.subindex) forKey:key];
        }
    } else {
        [self encodeString:DrawStringFromDrawHandleType(handle.type) forKey:key];
    }
}

- (void)decodeDrawHandleForKey:(NSString *)key setter:(void (^)(DrawHandle handle))setter {
    [self decodeStringForKey:key setter:^(NSString * _Nonnull string) {
        if ([string caseInsensitiveCompare:@"Missed"] == NSOrderedSame) {
            setter(DrawHandleMake(DrawHandleTypeMissed, 0, 0));
        } else {
            DrawHandleType type = DrawHandleTypeFromString(string);
            if (type == DrawHandleTypeMissed) {
                // This occurs when the string is otherwise not interpreted. When this happens, we'll assume we got an index
                NSScanner *scanner = [NSScanner scannerWithString:string];
                NSInteger index = 0, subindex = 0;
                if ([scanner scanInteger:&index]) {
                    if ([scanner scanString:@":" intoString:NULL]) {
                        [scanner scanInteger:&subindex];
                    }
                }
                setter(DrawHandleMake(DrawHandleTypeIndexed, index, subindex));
            } else {
                // We got a valid value, so we're going to go with that.
                setter(DrawHandleMake(type, 0, 0));
            }
        }
    }];
}

@end
