/*
 DrawViewController.h
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

#import <Cocoa/Cocoa.h>

@class DrawDocument, DrawLayerViewController, DrawInspectorGroupsController;

NS_ASSUME_NONNULL_BEGIN

@interface DrawViewController : NSViewController

@property (nullable,nonatomic,readonly) DrawDocument *document;
@property (nullable,nonatomic,readonly) DrawLayerViewController *layerViewController;
@property (nullable,nonatomic,readonly) DrawInspectorGroupsController *inspectorGroupsViewController;

#pragma mark - Live Cycle

/** Once this is called as the document gets loaded into memory. When this is called, self.document is guaranteed to return a non-nil value. */
- (void)documentDidLoad:(DrawDocument *)document;
/** Sent just prior to the document closing. This gives you a chance to stop observing things on the document. At this point, self.document may or may not be valid. This is necessary, because observations often create retain cycles with the document, so breaking those observations in an override of this method will allow the document to be released. */
- (void)documentWillClose:(DrawDocument *)document;

@end

NS_ASSUME_NONNULL_END
