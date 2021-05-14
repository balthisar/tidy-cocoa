/**
 *  TidyKitTests.m
 *   Part of the SwLibTidy wrapper library for tidy-html5 ("CLibTidy").
 *   See https://github.com/htacg/tidy-html5
 *
 *   Copyright © 2017-2021 by HTACG. All rights reserved.
 *   Created by Jim Derry 2017; copyright assigned to HTACG. Permission to use
 *   this source code per the W3C Software Notice and License:
 *   https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231
 *
 *   Purpose
 *     Provide test cases for the SwLibTidy, which also effectively tests 100%
 *     of the HTML Tidy public API.
 */

#import <XCTest/XCTest.h>
@import TidyKit;
//@import CLibTidy;


//*****************************************************************************
// MARK: - INTERFACE
//*****************************************************************************

/**
 *  Test cases for SwLibTidy.
 */
@interface TidyKitTests_Objective_C : XCTestCase

@end


//*****************************************************************************
// MARK: - IMPLEMENTATION
//*****************************************************************************

@implementation TidyKitTests_Objective_C

/**
 *  setUp at the beginning of every test.
 */
- (void)setUp
{
    [super setUp];
}

/**
 *  Teardown at the end of every test.
 */
- (void)tearDown
{
//    mydoc = nil;

    [super tearDown];
}


/**
 *  Here we will test that `TidyDocumentTidyingProtocol` function in instances of
 *  `TidyDocument` work as intended.
 */
- (void)testTidyDocumentTidying
{
    TidyDocument *tidyDoc = [[TidyDocument alloc] init];
    
    XCTAssert([tidyDoc.tidyText isEqualToString:@"tidyText"], @"tidyText is NOT equal to tidyText!");
}


/**
 *  Test
 */
- (void)testExample
{
	NSString *someString = nil;


	TestClass *myTest = [[TestClass alloc] init];
	someString = [myTest hello];
	NSLog( @"\n%@\n", someString );
	[myTest sayGoodbye];

	if ([TestClass conformsToProtocol:@protocol(TestHelloProtocol)] ) {
		NSLog( @"\n%@\n", @"Conforms to TestHelloProtocol" );
	};

	if ([TestClass conformsToProtocol:@protocol(TestGoodbyeProtocol)] ) {
		NSLog( @"\n%@\n", @"Conforms to TestGoodbyeProtocol" );
	};

	if ([TestClass conformsToProtocol:@protocol(TestProtocol)] ) {
		NSLog( @"\n%@\n", @"Conforms to TestProtocol" );
	};

//	SwiftClass *swiftClass = [myTest getSwiftClass];

}

@end
