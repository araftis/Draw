/* AJRXMLCoder-DrawExtensions.h created by alex on Thu 04-Feb-1999 */

#import <Draw/DrawGraphic.h>

#import <AJRFoundation/AJRFoundation.h>

@interface AJRXMLCoder (DrawExtensions)

- (void)encodeDrawHandle:(DrawHandle)aHandle forKey:(NSString *)key;
- (void)decodeDrawHandleForKey:(NSString *)key setter:(void (^)(DrawHandle handle))setter;

@end
