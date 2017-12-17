//
//  TidyKitTests.m
//  CocoaTests
//
//  Created by Jim Derry on 10/9/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//

#import <XCTest/XCTest.h>
@import TidyKit;
@import CLibTidy;

@interface TidyKitTests_Objective_C : XCTestCase

@end

@implementation TidyKitTests_Objective_C

//TidyDocument *mydoc;

- (void)setUp
{
    [super setUp];

//    mydoc = [[TidyDocument alloc] init];
}

- (void)tearDown
{
//    mydoc = nil;

    [super tearDown];
}

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

- (void)testPerformanceExample
{
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
