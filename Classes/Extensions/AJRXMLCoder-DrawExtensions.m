/*
 AJRXMLCoder-DrawExtensions.m
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
