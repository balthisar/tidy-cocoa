//
//  SwLibTidyTests.m
//  CocoaTests
//
//  Created by Jim Derry on 10/9/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//

#import <XCTest/XCTest.h>
@import SwLibTidy;
@import CLibTidy;

@interface ObjectiveCTests : XCTestCase

@end

@implementation ObjectiveCTests

TidyDocument *mydoc;

- (void)setUp
{
    [super setUp];

    mydoc = [[TidyDocument alloc] init];
}

- (void)tearDown
{
//    mydoc = nil;

    [super tearDown];
}

- (void)testExample
{
    NSString *myString = [NSString stringWithString:[mydoc getHello]];
    NSLog(@"===>%@\n", myString);

    TidyOptionId theId = [mydoc getOptionIdForName: @"clean" ];
    NSLog(@"%u", theId);
}

- (void)testPerformanceExample
{
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
