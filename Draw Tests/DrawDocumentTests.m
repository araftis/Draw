
#import <XCTest/XCTest.h>

#import <AppKit/AppKit.h>
#import <AJRFoundation/AJRFoundation.h>
#import <AJRInterface/AJRInterface.h>

#import "DrawDocument.h"

@interface DrawDocumentTests : XCTestCase

@end

@implementation DrawDocumentTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testDocumentWriting {
	NSError *localError = nil;
	DrawDocument *document = [[DrawDocument alloc] initWithType:@"com.ajr.papel" error:&localError];
	
	[document addHorizontalGuideAtLocation:306.0];
	[document addVerticalGuideAtLocation:396.0];
	[document writeToURL:[NSURL fileURLWithPath:@"/tmp/Test.papel"] ofType:@"com.ajr.papel" error:&localError];
}

@end
