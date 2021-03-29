
#import <Draw/DrawFilter.h>

NS_ASSUME_NONNULL_BEGIN

@interface DrawPapelFilter : DrawFilter

/*! The file extension appended to the archived document storage in the return file wrapper. */
@property (nonatomic,readonly) NSString *documentFileExtension;

@end

NS_ASSUME_NONNULL_END
