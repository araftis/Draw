/*
 DrawDocument-DragAndDrop.m
 Draw

 Copyright © 2022, AJ Raftis and Draw authors
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

#import "DrawDocument.h"

#import "DrawTool.h"

@implementation DrawDocument (DragAndDrop)

static NSMutableDictionary *draggedTypes = nil;

+ (NSDictionary *)draggedTypes {
    return draggedTypes;
}

+ (void)registerTool:(DrawTool *)aTool forDraggedTypes:(NSArray *)dragTypes; {
    if (!draggedTypes) {
        draggedTypes = nil;//[[NSMutableDictionary alloc] init];
    }
    
    for (NSInteger x = 0; x < (const NSInteger)[dragTypes count]; x++) {
        NSString *type = [dragTypes objectAtIndex:x];
        NSMutableArray *tools = [draggedTypes objectForKey:type];
        if (!tools) {
            tools = nil;//[[NSMutableArray alloc] init];
            [draggedTypes setObject:tools forKey:type];
        }
        
        NSUInteger index = [tools indexOfObject:aTool];
        if (index == NSNotFound) {
            [tools addObject:aTool];
        }
    }
}

+ (void)unregisterTool:(DrawTool *)aTool forDraggedTypes:(NSArray *)dragTypes; {
    for (NSInteger x = 0; x < (const NSInteger)[dragTypes count]; x++) {
        NSString *type = [dragTypes objectAtIndex:x];
        NSMutableArray *tools = [draggedTypes objectForKey:type];
        if (tools) {
            NSUInteger index = [tools indexOfObject:aTool];
            if (index != NSNotFound) {
                [tools removeObjectAtIndex:index];
            }
        }
    }
}

@end
