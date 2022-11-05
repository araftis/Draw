/*
 DrawDocumentStorage.h
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

#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class DrawGraphic, DrawLayer, DrawPage, AJRPaper, DrawMeasurementUnit;

@interface DrawDocumentStorage : NSObject <AJRXMLCoding>

// MARK: - User Info
@property (nonatomic,readonly) NSMutableDictionary<NSString *, id> *documentInfo;
- (void)setDocumentInfo:(nullable id)value forKey:(nullable NSString *)key;
- (nullable id)documentInfoForKey:(NSString *)key;

// MARK: - Print Info
@property (nonatomic,strong) NSPrintInfo *printInfo;
// This is necessary, because by default, the printInfo / PMPrintSession won't allow you to use a "generic" printer if an actual printer is available, but we want our use to be able to store a "generic" printer in their document.
@property (nonatomic,strong) NSPrinter *printer;
@property (nonatomic,strong) AJRPaper *paper;
@property (nonatomic,strong) DrawMeasurementUnit *unitOfMeasure;
@property (nonatomic,assign) AJRInset margins;

// MARK: - Basic Attributes
@property (nonatomic,strong) NSColor *paperColor;

// MARK: - Snap Lines
@property (nonatomic,strong) NSColor *markColor;
@property (nonatomic,strong) NSMutableArray<NSNumber *> *horizontalMarks;
@property (nonatomic,strong) NSMutableArray<NSNumber *> *verticalMarks;

// MARK: - Grid
@property (nonatomic,strong) NSColor *gridColor;
@property (nonatomic,assign) CGFloat gridSpacing;

// MARK: - Pages
@property (nonatomic,strong) NSMutableArray<DrawPage *> *pages;
@property (nonatomic,strong) DrawPage *masterPageEven;
@property (nonatomic,strong) DrawPage *masterPageOdd;
@property (nonatomic,assign) NSInteger pageNumber;
@property (nonatomic,assign) NSInteger startingPageNumber;

// MARK: - Layers
@property (nonatomic,strong) NSMutableArray<DrawLayer *> *layers;
@property (nonatomic,strong) DrawLayer *layer;

// MARK: - Selection
@property (nonatomic,strong) NSMutableSet<DrawGraphic *> *selection;

// MARK: - Copy and Paste
@property (nonatomic,assign) NSPoint copyDelta;
@property (nonatomic,assign) NSSize copyOffset;

// MARK: - Groups
@property (nullable,nonatomic,strong) DrawGraphic *group;

// MARK: - State
@property (nonatomic,strong) DrawGraphic *templateGraphic;

// MARK: - Book
@property (nonatomic,strong) NSString *chapterName;

// MARK: - Flags
@property (nonatomic,assign) BOOL gridEnabled;
@property (nonatomic,assign) BOOL gridVisible;
@property (nonatomic,assign) BOOL marksEnabled;
@property (nonatomic,assign) BOOL marksVisible;

// MARK: - Variables
@property (nonatomic,strong) AJRStore *variableStore;

@end

NS_ASSUME_NONNULL_END
