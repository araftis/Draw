/*
DrawDocumentStorage.h
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

#import <AJRFoundation/AJRFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class DrawGraphic, DrawLayer, DrawPage;

@interface DrawDocumentStorage : NSObject <AJRXMLCoding>

// User Info
@property (nonatomic,readonly) NSMutableDictionary<NSString *, id> *documentInfo;
- (void)setDocumentInfo:(nullable id)value forKey:(nullable NSString *)key;
- (nullable id)documentInfoForKey:(NSString *)key;

// Print Info
@property (nonatomic,strong) NSPrintInfo *printInfo;

// Basic Attributes
@property (nonatomic,strong) NSColor *paperColor;

// Snap Lines
@property (nonatomic,strong) NSColor *markColor;
@property (nonatomic,strong) NSMutableArray<NSNumber *> *horizontalMarks;
@property (nonatomic,strong) NSMutableArray<NSNumber *> *verticalMarks;

// Grid
@property (nonatomic,strong) NSColor *gridColor;
@property (nonatomic,assign) CGFloat gridSpacing;

// Pages
@property (nonatomic,strong) NSMutableArray<DrawPage *> *pages;
@property (nonatomic,strong) DrawPage *masterPageEven;
@property (nonatomic,strong) DrawPage *masterPageOdd;
@property (nonatomic,assign) NSInteger pageNumber;
@property (nonatomic,assign) NSInteger startingPageNumber;

// Layers
@property (nonatomic,strong) NSMutableArray<DrawLayer *> *layers;
@property (nonatomic,strong) DrawLayer *layer;

// Selection
@property (nonatomic,strong) NSMutableSet<DrawGraphic *> *selection;

// Copy and Paste
@property (nonatomic,assign) NSPoint copyDelta;
@property (nonatomic,assign) NSSize copyOffset;

// Groups
@property (nullable,nonatomic,strong) DrawGraphic *group;

// State
@property (nonatomic,strong) DrawGraphic *templateGraphic;

// Book
@property (nonatomic,strong) NSString *chapterName;

// Flags
@property (nonatomic,assign) BOOL gridEnabled;
@property (nonatomic,assign) BOOL gridVisible;
@property (nonatomic,assign) BOOL marksEnabled;
@property (nonatomic,assign) BOOL marksVisible;

@end

NS_ASSUME_NONNULL_END
