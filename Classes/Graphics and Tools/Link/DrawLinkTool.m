
#import "DrawLinkTool.h"

#import "DrawDocument.h"
#import "DrawEvent.h"
#import "DrawGraphicsToolSet.h"
#import "DrawLink.h"
#import "DrawLinkCap.h"
#import "DrawLogging.h"
#import "DrawPage.h"
#import "DrawToolAction.h"

#import <AJRFoundation/AJRLogging.h>
#import <AJRInterface/AJRInterface.h>

NSString * const DrawLinkToolIdentifier = @"linkTool";

static NSMutableArray<Class> *_linkCaps = nil;

@interface DrawLinkTool ()

@property (nonatomic,assign) DrawHandle handle;

@end

@implementation DrawLinkTool

#pragma mark - Link Cap Factory

+ (void)initialize {
    _linkCaps = [[NSMutableArray alloc] init];
}

+ (NSArray *)linkCaps {
    return _linkCaps;
}

+ (void)registerLinkCap:(Class)class properties:(NSDictionary *)properties {
    AJRLog(DrawPlugInLogDomain, AJRLogLevelDebug, @"Link Cap: %@\n", class);
    [_linkCaps addObject:class];
    [_linkCaps sortUsingSelector:@selector(compare:)];
}

+ (NSUInteger)indexForLinkCapClass:(Class)aLinkCapClass {
    if (aLinkCapClass == Nil) {
        return 0;
    }

    for (NSInteger x = 0; x < (const NSInteger)[_linkCaps count]; x++) {
        if ([_linkCaps objectAtIndex:x] == aLinkCapClass) return x + 1;
    }

    return NSNotFound;
}

+ (NSUInteger)indexForLinkCap:(DrawLinkCap *)aLinkCap {
    return [self indexForLinkCapClass:[aLinkCap class]];
}

+ (NSUInteger)indexForLinkCapNamed:(NSString *)aName {
    return [self indexForLinkCapClass:NSClassFromString(aName)];
}

+ (Class)linkCapClassAtIndex:(NSUInteger)index {
    if (index) {
        return [_linkCaps objectAtIndex:index - 1];
    }

    return Nil;
}

#pragma mark - Creation

- (id)initWithToolSet:(DrawToolSet *)toolSet {
    if ((self = [super initWithToolSet:toolSet])) {
        [DrawSelectionTool registerObject:self forDragWithModifierMask:NSEventModifierFlagOption];
    }
    return self;
}

- (NSCursor *)cursor {
    static NSCursor *cursor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"cursorLink"] hotSpot:(NSPoint){7.0, 7.0}];
    });

    return cursor;
}

- (void)_trackFromEvent:(DrawEvent *)event {
    if ([self.graphic trackMouse:event fromHandle:_handle]) {
        [[event document] setCurrentTool:self];
    }
}

- (BOOL)dragSelection:(NSArray *)selection withLastHitGraphic:(DrawGraphic *)graphic fromEvent:(DrawEvent *)event {
    DrawPage *page = [graphic page];

    if (self.graphic) {
        self.graphic = nil;
    }
    self.graphic = [(DrawLink *)[DrawLink alloc] initWithSource:graphic];
    [(DrawLink *)self.graphic setSourceHandle:[graphic pathHandleForPoint:[event locationOnPage]]];
    [(DrawLink *)self.graphic setEditing:YES];
    [(DrawLink *)self.graphic setCreating:YES];

    [page addGraphic:self.graphic select:YES byExtendingSelection:NO];

    _handle = DrawHandleMake(DrawHandleTypeIndexed, 1, 0);
    [self _trackFromEvent:event];

    return YES;
}

- (void)toolDidActivateForDocument:(DrawDocument *)document {
    [super toolDidActivateForDocument:document];
    if (self.graphic) {
        [(DrawPen *)self.graphic setCreating:NO];
        self.graphic = nil;
    }
}

- (BOOL)mouseDown:(DrawEvent *)event {
    if (![self waitForMouseDrag:event]) return NO;
    if ([event layerIsLockedOrNotVisible]) return NO;

    if (self.graphic) {
        if ([self.graphic page] == [event page]) {
            NSPoint point = [[event document] snapPointToGrid:[event locationOnPage]];

            [(DrawPen *)self.graphic appendLineToPoint:point];
            _handle.elementIndex++;

            [self _trackFromEvent:event];
        } else {
            [(DrawPen *)self.graphic setCreating:NO];
            self.graphic = nil;
        }
    } else {
        NSArray<DrawGraphic *> *graphics = [[event page] graphicsHitByPoint:[event locationOnPage]];
        if ([graphics count]) {
            [self dragSelection:graphics withLastHitGraphic:[graphics objectAtIndex:0] fromEvent:event];
        }
    }

    return YES;
}

@end
