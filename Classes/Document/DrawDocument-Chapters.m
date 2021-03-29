
#import "DrawDocument.h"

#import "DrawBook.h"
#import "DrawDocumentStorage.h"

@implementation DrawDocument (Chapters)

- (void)setBook:(DrawBook *)aBook {
    _book = aBook;
}

- (DrawBook *)book {
   return _book;
}

- (void)setChapterName:(NSString *)aName {
   if (_storage.chapterName != aName) {
      [self registerUndoWithTarget:self selector:@selector(setChapterName:) object:_storage.chapterName];
      _storage.chapterName = aName;
   }
}

- (NSString *)chapterName {
   return _storage.chapterName;
}

@end
