/*
 DrawInspector.h
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

#import <Foundation/Foundation.h>

#import <Draw/DrawGraphic.h>

@class DrawInspectorController;

typedef DrawAspect * (^DrawAspectCreationCallback)(DrawGraphic *graphic, DrawAspectPriority priority);

@interface DrawInspector : NSViewController
{
    __unsafe_unretained DrawInspectorController *_inspectorController;
    NSArrayController *_selectionController;
}

#pragma mark - Factory Clients

+ (NSSet *)inspectedClasses;
+ (CGFloat)priority;
+ (NSString *)identifier;
+ (NSString *)name;

#pragma mark - Creation

- (id)initWithInspectorController:(DrawInspectorController *)inspectorController;

#pragma mark - Properties

@property (nonatomic,assign) DrawInspectorController *inspectorController;
@property (nonatomic,readonly) NSArrayController *selectionController;
@property (nonatomic,readonly) DrawDocument *document;
@property (nonatomic,readonly) NSPrintInfo *printInfo;

#pragma mark - Inspection

- (Class)inspectedType;

/*!
 Called when the selection changes. You don't necessarily have to override this method, but you may do so if you do not wish to use Cocoa Bindings to update your display. 
 */
- (void)update;

- (void)startObservingSelection;
- (void)stopObservingSelection;

#pragma mark - Selection

- (NSArray *)selection;

/*!
 By default, this method returns selection, but subclasses can, and should override this property to return the array of objects they're actually interested in.
 
 @param creationCallback If provided, this block can be used to create a new aspect.
 */
- (NSArray *)inspectedObjectsWithCreationCallback:(DrawAspectCreationCallback)creationCallback;

/*!
 Provided the object from the inspector controller's selection, this returns the actual object inspected. For example, a graphic inspector would just return object, while an aspect inspector, such as the stroke inspector, would return the graphic's first stroke aspect.
 
 Note that object can be of any type that the inspector claims to inspect. This is important because something like an aspect inspector could be provided a DrawAspect or a DrawGraphic.
 
 @param object The object in the selection. It could be of any type the inspector claims to inspect.
 @param creationCallback If not NULL, then the callback will be called if the desired inspected value must be created.
 
 @return The actual value inspected by the inspector.
 */
- (id)inspectedObjectForSelectedObject:(id)object withCreationCallback:(DrawAspectCreationCallback)creationCallback;

#pragma mark - Utilities

- (NSSet *)inspectedValuesForKeyPath:(NSString *)keyPath;

- (void)setInspectedValue:(id)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback;
- (void)setInspectedFloat:(CGFloat)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback;
- (void)setInspectedDouble:(double)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback;
- (void)setInspectedInteger:(NSInteger)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback;
- (void)setInspectedBool:(BOOL)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback;

@end
