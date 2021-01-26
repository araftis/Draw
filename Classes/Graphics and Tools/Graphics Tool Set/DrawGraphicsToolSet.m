//
//  DrawGraphicsToolSet.m
//  
//
//  Created by Alex Raftis on 6/24/11.
//  Copyright 2011 Apple, Inc. All rights reserved.
//

#import "DrawGraphicsToolSet.h"

#import "DrawDocument.h"

#import <AJRInterface/AJRInterface.h>

DrawToolSetId const DrawToolSetIdGraphics = @"graphics";

@implementation DrawGraphicsToolSet

#pragma mark - DrawToolSet: Document Querries

- (NSSet *)selectionForInspectionForDocument:(DrawDocument *)document {
    return [NSSet setWithObject:[document templateGraphic]];
}

@end
