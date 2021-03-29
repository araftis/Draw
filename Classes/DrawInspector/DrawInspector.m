/*
DrawInspector.m
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
/* DrawInspector.m created by alex on Sun 11-Oct-1998 */

#import "DrawInspector.h"

#import "DrawInspectorModule.h"
#import "DrawDocument.h"

#import <ASFoundation/ASFoundation.h>
#import <ASInterface/ASInterface.h>

static DrawInspector *SELF = nil;

NSString *DrawInspectorOrderKey = @"DrawInspectorOrderKey";

@implementation DrawInspector

+ (id)allocWithZone:(NSZone *)zone
{
    if (!SELF) SELF = [super allocWithZone:zone];
    return SELF;
}

- (id)init
{
    if (!window) {
        [super init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(drawViewDidChangeSelection:) name:DrawViewDidChangeSelectionNotification object:nil];
    }
    
    return self;
}

+ (id)sharedInstance
{
    return [[self alloc] init];
}

- (Class)inspectorClass
{
    return [DrawInspectorModule class];
}

- (void)showDrawInspectorPanel:(id)sender
{
    [inspector update];
    [window makeKeyAndOrderFront:sender];
}

- (void)drawViewDidChangeSelection:(NSNotification *)notification
{
#warning Implement
//    if ([notification object] == [[DrawController sharedInstance] currentView]) {
//        [inspector update];
//    }
}

@end


@implementation NSResponder (DrawInspectorControll)

- (void)showDrawInspectorPanel:(id)sender
{
    [[DrawInspector sharedInstance] showDrawInspectorPanel:sender];
}

@end
