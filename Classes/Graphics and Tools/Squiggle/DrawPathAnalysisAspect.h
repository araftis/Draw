
#import <Draw/DrawAspect.h>

@class AJRPathAnalyzer;

@interface DrawPathAnalysisAspect : DrawAspect <AJRXMLCoding>

@property (nonatomic,strong) AJRPathAnalyzer *analyzer;

@end
