/* DrawBook.m created by alex on Wed 24-Feb-1999 */

#import "DrawBook.h"

#import "DrawDocument.h"

static NSMutableDictionary		*books = nil;

@implementation DrawBook

+ (void)initialize
{
	books = [[NSMutableDictionary alloc] init];
}

+ (id)bookWithURL:(NSURL *)URL
{
	DrawBook		*book = [books objectForKey:URL];
	
	if (book) return book;
	
	return [[self alloc] initWithURL:URL];
}

- (id)initWithURL:(NSURL *)URL
{
	DrawBook		*book;
	
	book = [books objectForKey:URL];
	if (book) {
		return book;
	}
	
	self = [super init];
	
	[self setURL:URL];
	
	chapters = [[NSMutableArray alloc] init];
	
	return self;
}

- (void)dealloc
{
	[books removeObjectForKey:_url];
}

@synthesize URL=_url;

- (void)setURL:(NSURL *)url
{
	if (_url != url) {
		// Remove the old copy
		[books removeObjectForKey:_url];
		
		_url = url;
		
		// And put us in with our new index key
		[books setObject:self forKey:_url];
	}
}

- (DrawDocument *)drawViewForChapterNamed:(NSString *)aChapterName
{
	id		chapter = [chapterIndex objectForKey:aChapterName];
	
	if ([chapter isKindOfClass:[NSDictionary class]]) {
		NSUInteger		index = [chapters indexOfObjectIdenticalTo:chapter];
        NSError         *error;
		
		chapter = [[DrawDocument alloc] initWithContentsOfURL:[[[self URL] URLByAppendingPathComponent:aChapterName] URLByAppendingPathExtension:@"papel"] ofType:@"papel" error:&error];
		[chapters replaceObjectAtIndex:index withObject:chapter];
		[chapterIndex setObject:chapter forKey:aChapterName];
		
		[chapter setBook:self];
	}
	
	return chapter;
}

- (void)addDrawView:(DrawDocument *)aView
{
	if ([chapterIndex objectForKey:[aView chapterName]]) {
		[chapters addObject:aView];
		[chapterIndex setObject:aView forKey:[aView chapterName]];
	}
}

- (void)removeDrawView:(DrawDocument *)aView
{
}

- (void)save:(id)sender
{
}

- (void)saveAs:(id)sender
{
}

- (void)close:(id)sender
{
}

@end
