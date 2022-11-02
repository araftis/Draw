/*
 DrawDocumentInspector.h
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
/* DrawDocumentInspector.h created by alex on Fri 16-Oct-1998 */

#import "DrawInspectorModule.h"

@interface DrawDocumentInspector : DrawInspectorModule
{
   IBOutlet NSColorWell		*paperColorWell;

   IBOutlet NSButton			*marksActiveCheck;
   IBOutlet NSButton			*marksVisibleCheck;
   IBOutlet NSColorWell		*marksColorWell;

   IBOutlet NSFormCell		*leftMarginCell;
   IBOutlet NSFormCell		*rightMarginCell;
   IBOutlet NSFormCell		*topMarginCell;
   IBOutlet NSFormCell		*bottomMarginCell;

   IBOutlet NSButton			*gridActiveCheck;
   IBOutlet NSButton			*gridVisibleCheck;
   IBOutlet NSColorWell		*gridColorWell;
   IBOutlet NSTextField		*gridSpacingText;
   
   IBOutlet NSPopUpButton	*unitsOfMeasureButton;
}

- (void)setPaperColor:(NSColorWell *)sender;

- (void)setMarkColor:(NSColorWell *)sender;
- (void)setMarkVisible:(NSButton *)sender;
- (void)setMarkActive:(NSButton *)sender;

- (void)setGridColor:(NSColorWell *)sender;
- (void)setGridActive:(NSButton *)sender;
- (void)setGridVisible:(NSButton *)sender;
- (void)setGridSpacing:(NSTextField *)sender;
- (void)doubleGridSize:(NSButton *)sender;
- (void)halveGridSize:(NSButton *)sender;

- (void)setLeftMargin:(NSFormCell *)sender;
- (void)setRightMargin:(NSFormCell *)sender;
- (void)setBottomMargin:(NSFormCell *)sender;
- (void)setTopMargin:(NSFormCell *)sender;

- (void)setUnitsOfMeasure:(NSPopUpButton *)sender;

@end
