/*
DrawToolAction.m
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
