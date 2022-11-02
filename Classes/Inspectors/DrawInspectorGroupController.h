/*
 DrawInspectorGroupController.h
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
//
//  DrawInspectorGroupController.h
//  Draw
//
//  Created by Alex Raftis on 10/9/11.
//  Copyright (c) 2011 Apple, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DrawDocument, DrawInspectorController, DrawInspectorGroup;

#pragma mark Inspector Groups

extern NSString * const DrawInspectorGroupDocument;
extern NSString * const DrawInspectorGroupLeft;
extern NSString * const DrawInspectorGroupRight;
extern NSString * const DrawInspectorGroupStyles;

@interface DrawInspectorGroupController : NSObject

#pragma mark - Factory

+ (void)registerControllerClass:(Class)class forName:(NSString *)name;
+ (Class)controllerClassForName:(NSString *)name;

+ (void)registerControllerClass:(Class)class inGroup:(NSString *)name;
+ (NSSet *)controllerClassesInGroup:(NSString *)name;

+ (void)registerInspectorClass:(Class)inspectorClass forName:(NSString *)name;
+ (NSSet *)inspectorClassesForClass:(Class)class forName:(NSString *)name;

#pragma mark - Creation

- (id)initWithDocument:(DrawDocument *)document;

#pragma mark Properties

@property (nonatomic,weak) DrawDocument *document;

#pragma mark - Inspectors

- (DrawInspectorController *)inspectorControllerForName:(NSString *)name;
- (DrawInspectorGroup *)inspectorGroupForName:(NSString *)name;

#pragma mark - Selection Change

- (void)updateInspectors;

@end
