
#import "NSPasteboard-DrawExtensions.h"

#import "DrawDocument.h"
#import "DrawGraphic.h"
#import "DrawPage.h"

@implementation NSPasteboard (DrawExtensions)

- (void)setDrawGraphicsAsNative:(NSArray *)graphics {
    NSMutableArray *array = [graphics mutableCopyWithZone:NSDefaultMallocZone()];
    [self setData:[NSKeyedArchiver ajr_archivedObject:array error:NULL] forType:DrawGraphicPboardType];
}

- (void)setDrawGraphicsAsPDF:(NSArray *)graphics {
    NSData *data;

    data = [[[[graphics lastObject] page] document] PDFForGraphics:graphics];

    if (data) {
        [self setData:data forType:NSPasteboardTypePDF];
    }
}

- (void)setDrawGraphics:(NSArray *)graphics forType:(NSString *)dataType {
    if ([dataType isEqualToString:DrawGraphicPboardType]) {
        [self setDrawGraphicsAsNative:graphics];
    } else if ([dataType isEqualToString:NSPasteboardTypePDF]) {
        [self setDrawGraphicsAsPDF:graphics];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"An array of draw graphics cannot be represented as %@.", dataType];
    }
}

- (NSArray *)drawGraphicsFromNative {
    NSData *data;

    data = [self dataForType:DrawGraphicPboardType];
    if (!data) return nil;

    return [NSKeyedUnarchiver ajr_unarchivedObjectWithData:data error:NULL];
}

- (NSArray *)drawGraphicsFromEPS {
    return nil;
}

- (NSArray *)drawGraphicsForType:(NSString *)dataType {
    if ([dataType isEqualToString:DrawGraphicPboardType]) {
        return [self drawGraphicsFromNative];
    } else if ([dataType isEqualToString:@"com.adobe.encapsulated-postscript"]) {
        [self drawGraphicsFromEPS];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"An array of draw graphics cannot be represented as %@.", dataType];
    }

    return nil;
}

@end
