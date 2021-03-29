/*
DrawStrokeInspector.h
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

#import <Draw/DrawAspectInspector.h>

@class DrawStrokeDash, DrawThicknessControl, AJRBox, AJRObjectBroker;

@interface DrawStrokeInspector : DrawAspectInspector <NSControlTextEditingDelegate> {
   IBOutlet NSColorWell *colorWell;
   IBOutlet DrawThicknessControl *thickness;
   IBOutlet NSTextField *thicknessText;
   IBOutlet NSMatrix *strokeType;
   IBOutlet NSMatrix *joinType;
   IBOutlet NSMatrix *lineCap;
   IBOutlet AJRBox *subinspector;
   IBOutlet NSTextField *miterLimitText;
   IBOutlet NSSlider *miterLimitSlider;
   IBOutlet NSMatrix *dashes;

   IBOutlet NSWindow *newDashWindow;
   IBOutlet NSImageView *newDashPreview;
   IBOutlet NSButton *newDashOKButton;
   IBOutlet NSButton *newDashCancelButton;
   IBOutlet NSButton *newDashTextField;

   NSMutableArray *strokes;

   DrawStrokeDash *_workDash;
}

- (void)setStrokeColor:(id)sender;
- (void)setStrokeThickness:(id)sender;
- (void)selectStrokeType:(id)sender;
- (void)selectJoinType:(id)sender;
- (void)selectLineCap:(id)sender;
- (void)setStokeMiterLimit:(id)sender;
- (void)selectDash:(id)sender;
- (void)createNewDashPattern:(id)sender;

- (NSUInteger)tagForStrokeNamed:(NSString *)name;
- (Class)strokeClassForName:(NSString *)name;
- (void)setStrokeType:(NSMatrix *)aMatrix;
- (Class)strokeClass;

- (void)ok:(id)sender;
- (void)cancel:(id)sender;

@end
