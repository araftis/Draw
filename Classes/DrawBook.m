/*
DrawBook.m
Draw

Copyright © 2021, AJ Raftis and AJRFoundation authors
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
