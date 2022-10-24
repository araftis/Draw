/*
 DrawFillInspector.m
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

#import "DrawFillInspector.h"

#import "DrawGraphic.h"
#import <Draw/Draw-Swift.h>

#import <AJRInterface/AJRInterface.h>
#import <AJRFoundation/AJRFoundation.h>

NSString *DrawFillKey = @"DrawFillKey";

// TODO: Remove this class! It should no longer be used, since we now use declarative inspectors.

@implementation DrawFillInspector

+ (void)initialize {
    [[NSUserDefaults standardUserDefaults] registerDefaults:
         [NSDictionary dictionaryWithObjectsAndKeys:
              // The Compose Defaults
          @"Standard", DrawFillKey,
          nil
         ]
    ];
}

- (id)init {
    if ((self = [super init])) {
        fills = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSString *)title {
    return @"Fill";
}

- (void)addFill:(Class)aClass {
    AJRPrintf(@"Fill: %@\n", aClass);
    [fills addObject:aClass];
}

- (Class)inspectedClass {
    return [DrawFill class];
}

- (DrawAspectPriority)aspectPriority {
    return DrawAspectPriorityBeforeChildren;
}

- (DrawAspect *)aspectWithGraphic:(DrawGraphic *)graphic {
    return [[[self fillClass] alloc] initWithGraphic:graphic];
}

- (void)update {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSSet *colors = [self inspectedValuesForKeyPath:@"color"];

    if ([colors count] == 1) {
        [fillColorWell setColor:[colors anyObject]];

        [defaults setColor:[colors anyObject] forKey:@"fillColor"];
    } else if ([colors count] > 1) {
    } else {
        NSUInteger tag = [self tagForFillNamed:[defaults stringForKey:DrawFillKey]];

        if (tag == NSNotFound) {
            tag = [self tagForFillNamed:@"Standard"];
            [defaults setObject:@"Standard" forKey:DrawFillKey];
        }

        [fillColorWell setColor:[defaults colorForKey:@"fillColor"]];
        [[fillTypeMatrix cellAtRow:0 column:0] selectItemWithTag:tag];
    }
}

- (void)setFillColor:(id)sender {
    [[NSUserDefaults standardUserDefaults] setColor:[sender color] forKey:@"fillColor"];
    [self setInspectedValue:[sender color] forKeyPath:@"color" creationCallback:NULL];
}

- (void)selectFillType:(id)sender {
}

- (NSUInteger)tagForFillNamed:(NSString *)name {
    NSInteger x;

    for (x = 0; x < (const NSInteger)[fills count]; x++) {
        if ([[(Class)[fills objectAtIndex:x] name] isEqualToString:name]) return x;
    }

    return NSNotFound;
}

- (Class)fillClassForName:(NSString *)name {
    NSInteger x;

    for (x = 0; x < (const NSInteger)[fills count]; x++) {
        if ([[(Class)[fills objectAtIndex:x] name] isEqualToString:name]) return [fills objectAtIndex:x];
    }

    return Nil;
}

- (void)setFillTypeMatrix:(NSMatrix *)aMatrix {
//   AJRToolCell *cell;
//   NSMutableArray *images = [[NSMutableArray alloc] init];
//   NSInteger x;
//
//   [aMatrix setCellClass:[AJRToolCell class]];
//
//   for (x = 0; x < (const NSInteger)[fills count]; x++) {
//      [images addObject:[[fills objectAtIndex:x] image]];
//   }
//
//   cell = [[AJRToolCell alloc] initWithImageArray:images];
//   [cell setTriggerOnMouseDown:YES];
//   [cell setPopDirection:AJRPopVertical];
//   [cell setHighlightsBy:NSNoCellMask];
//   [cell setShowsStateBy:NSNoCellMask];
//
//   [aMatrix putCell:cell atRow:0 column:0];
//
//   [images release];
//
//   fillTypeMatrix = aMatrix;
}

- (Class)fillClass {
    Class class = [self fillClassForName:[[NSUserDefaults standardUserDefaults] stringForKey:DrawFillKey]];

    if (!class) {
        class = [self fillClassForName:@"Standard"];
    }

    return class;
}

@end
