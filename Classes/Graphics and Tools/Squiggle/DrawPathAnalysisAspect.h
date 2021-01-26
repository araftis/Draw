//
//  DrawPathAnalysisAspect.h
//  Draw
//
//  Created by Alex Raftis on 11/8/11.
//  Copyright (c) 2011 Apple, Inc. All rights reserved.
//

#import <Draw/DrawAspect.h>

@class AJRPathAnalyzer;

@interface DrawPathAnalysisAspect : DrawAspect <AJRXMLCoding>

@property (nonatomic,strong) AJRPathAnalyzer *analyzer;

@end
