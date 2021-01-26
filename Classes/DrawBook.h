/* DrawBook.h created by alex on Wed 24-Feb-1999 */

#import <AppKit/AppKit.h>

@class DrawDocument;

@interface DrawBook : NSObject
{
   NSURL				*_url;
   NSMutableArray		*chapters;
   NSMutableDictionary	*chapterIndex;
}

+ (id)bookWithURL:(NSURL *)url;
- (id)initWithURL:(NSURL *)url;

@property (nonatomic,strong) NSURL *URL;

- (DrawDocument *)drawViewForChapterNamed:(NSString *)aChapterName;

- (void)addDrawView:(DrawDocument *)aView;
- (void)removeDrawView:(DrawDocument *)aView;

- (void)save:(id)sender;
- (void)saveAs:(id)sender;
- (void)close:(id)sender;

@end
