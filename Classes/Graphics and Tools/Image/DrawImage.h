
#import <Draw/DrawAspect.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const DrawImageAspectKey;

extern NSString * const DrawPreferencesImageAlignmentKey;
extern NSString * const DrawPreferencesImageScalingKey;

@interface DrawImage : DrawAspect <AJRXMLCoding>

@property (nonatomic,strong) NSImage *image;
@property (nonatomic,assign) NSImageAlignment imageAlignment;
@property (nonatomic,assign) NSImageScaling imageScaling;
@property (nonatomic,strong) NSString *filename;
@property (nonatomic,readonly) NSDate *modificationDate;
@property (nonatomic,readonly) NSSize naturalSize;

- (void)updateImage;

@end

NS_ASSUME_NONNULL_END
