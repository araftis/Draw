
#import <AJRFoundation/AJRFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class DrawGraphic, DrawLayer, DrawPage;

@interface DrawDocumentStorage : NSObject <AJRXMLCoding>

// User Info
@property (nonatomic,readonly) NSMutableDictionary<NSString *, id> *documentInfo;
- (void)setDocumentInfo:(nullable id)value forKey:(nullable NSString *)key;
- (nullable id)documentInfoForKey:(NSString *)key;

// Print Info
@property (nonatomic,strong) NSPrintInfo *printInfo;

// Basic Attributes
@property (nonatomic,strong) NSColor *paperColor;

// Snap Lines
@property (nonatomic,strong) NSColor *markColor;
@property (nonatomic,strong) NSMutableArray<NSNumber *> *horizontalMarks;
@property (nonatomic,strong) NSMutableArray<NSNumber *> *verticalMarks;

// Grid
@property (nonatomic,strong) NSColor *gridColor;
@property (nonatomic,assign) CGFloat gridSpacing;

// Pages
@property (nonatomic,strong) NSMutableArray<DrawPage *> *pages;
@property (nonatomic,strong) DrawPage *masterPageEven;
@property (nonatomic,strong) DrawPage *masterPageOdd;
@property (nonatomic,assign) NSInteger pageNumber;
@property (nonatomic,assign) NSInteger startingPageNumber;

// Layers
@property (nonatomic,strong) NSMutableArray<DrawLayer *> *layers;
@property (nonatomic,strong) DrawLayer *layer;

// Selection
@property (nonatomic,strong) NSMutableSet<DrawGraphic *> *selection;

// Copy and Paste
@property (nonatomic,assign) NSPoint copyDelta;
@property (nonatomic,assign) NSSize copyOffset;

// Groups
@property (nullable,nonatomic,strong) DrawGraphic *group;

// State
@property (nonatomic,strong) DrawGraphic *templateGraphic;

// Book
@property (nonatomic,strong) NSString *chapterName;

// Flags
@property (nonatomic,assign) BOOL gridEnabled;
@property (nonatomic,assign) BOOL gridVisible;
@property (nonatomic,assign) BOOL marksEnabled;
@property (nonatomic,assign) BOOL marksVisible;

@end

NS_ASSUME_NONNULL_END
