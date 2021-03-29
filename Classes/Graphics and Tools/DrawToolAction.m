
#import "DrawToolAction.h"

#import "DrawTool.h"

#import <AJRFoundation/AJRFoundation.h>

@implementation DrawToolAction

#pragma mark - Creation

+ (id)toolActionWithTool:(DrawTool *)tool title:(NSString *)title icon:(NSImage *)icon cursor:(NSCursor *)cursor tag:(NSInteger)tag {
    return [[self alloc] initWithTool:tool title:title icon:icon cursor:cursor tag:tag graphicClass:Nil];
}

+ (id)toolActionWithTool:(DrawTool *)tool title:(NSString *)title icon:(NSImage *)icon cursor:(NSCursor *)cursor tag:(NSInteger)tag graphicClass:(nullable Class)graphicClass {
    return [[self alloc] initWithTool:tool title:title icon:icon cursor:cursor tag:tag graphicClass:graphicClass];
}

- (id)initWithTool:(DrawTool *)tool title:(NSString *)title icon:(NSImage *)icon cursor:(NSCursor *)cursor tag:(NSInteger)tag {
    return [self initWithTool:tool title:title icon:icon cursor:cursor tag:tag graphicClass:Nil];
}

- (id)initWithTool:(DrawTool *)tool title:(NSString *)title icon:(NSImage *)icon cursor:(NSCursor *)cursor tag:(NSInteger)tag graphicClass:(nullable Class)graphicClass {
    if ((self = [super init])) {
        self.title = title;
        self.tool = tool;
        self.icon = icon;
        if (cursor == nil) {
            cursor = [NSCursor crosshairCursor];
        }
        self.cursor = cursor;
        self.tag = tag;
        self.graphicClass = graphicClass;
    }
    return self;
}

#pragma mark - NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p: %@>", NSStringFromClass([self class]), self, _title];
}

- (Class)graphicClass {
    AJRPrintf(@"Returning: %C\n", _graphicClass);\
    return _graphicClass;
}

@end
