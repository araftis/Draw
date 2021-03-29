/*
DrawAspectInspector.m
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

#import "DrawAspectInspector.h"

#import "DrawAspect.h"
#import "DrawDocument.h"

@implementation DrawAspectInspector

- (DrawAspectPriority)inspectedPriority
{
	DrawAbstract(DrawAspectPriorityBackground);
}

- (Class)inspectedType
{
	DrawAbstract(Nil);
}

- (id)inspectedObjectForSelectedObject:(id)object withCreationCallback:(DrawAspectCreationCallback)creationCallback
{
	Class	aspectType = [self inspectedType];
	id		inspectedObject = object;
	
	if (aspectType) {
		if ([object isKindOfClass:[DrawGraphic class]]) {
			inspectedObject = [object firstAspectOfType:aspectType withPriority:[self inspectedPriority]];
			if (inspectedObject == nil && creationCallback) {
				inspectedObject = creationCallback(object, [self inspectedPriority]);
				[(DrawGraphic *)object addAspect:inspectedObject withPriority:[self inspectedPriority]];
			}
		} else if ([object isKindOfClass:[DrawAspect class]] && [object isKindOfClass:aspectType]) {
			inspectedObject = object;
		}
	}
	
	return inspectedObject;
}

- (NSArray *)inspectedObjectsWithCreationCallback:(DrawAspectCreationCallback)creationCallback
{
	NSMutableArray	*objects = [NSMutableArray array];
	NSArray			*selection = [self selection];
	
	if ([selection count]) {
		// We have a selection, so return those aspects.
		for (id object in selection) {
			id	inspectedObject = [self inspectedObjectForSelectedObject:object withCreationCallback:creationCallback];
			if (inspectedObject) {
				[objects addObject:inspectedObject];
			}
		}
	} else {
		// We don't have a selection, so return the "template" graphic, who's aspects are used when creating new objects.
		id	inspectedObject = [self inspectedObjectForSelectedObject:[[self document] templateGraphic] withCreationCallback:creationCallback];
		if (inspectedObject) {
			[objects addObject:inspectedObject];
		}
	}
	
	return objects;
}

- (void)setInspectedValue:(id)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback
{
	[super setInspectedValue:value forKeyPath:keyPath creationCallback:creationCallback];
	[self setTemplateValue:value forKeyPath:keyPath creationCallback:creationCallback];
}

- (void)setTemplateValue:(id)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback
{
	[[self inspectedObjectForSelectedObject:[[self document] templateGraphic] withCreationCallback:creationCallback] setValue:value forKeyPath:keyPath];
}

- (void)setTemplateFloat:(CGFloat)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback
{
	[self setTemplateValue:[NSNumber numberWithFloat:value] forKeyPath:keyPath creationCallback:creationCallback];
}

- (void)setTemplateDouble:(double)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback
{
	[self setTemplateValue:[NSNumber numberWithDouble:value] forKeyPath:keyPath creationCallback:creationCallback];
}

- (void)setTemplateInteger:(NSInteger)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback
{
	[self setTemplateValue:[NSNumber numberWithInteger:value] forKeyPath:keyPath creationCallback:creationCallback];
}

- (void)setTemplateBool:(BOOL)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback
{
	[self setTemplateValue:[NSNumber numberWithBool:value] forKeyPath:keyPath creationCallback:creationCallback];
}

- (void)removeInspectedAspectFromSelection
{
	DrawAspect	*inspectedObject;

	for (id selectedObject in [self selection]) {
		inspectedObject = [self inspectedObjectForSelectedObject:selectedObject withCreationCallback:NULL];
		[[inspectedObject graphic] removeAspect:inspectedObject];
	}

	inspectedObject = [self inspectedObjectForSelectedObject:[[self document] templateGraphic] withCreationCallback:NULL];
	[[inspectedObject graphic] removeAspect:inspectedObject];
}

@end
