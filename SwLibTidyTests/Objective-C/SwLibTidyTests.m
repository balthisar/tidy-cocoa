//
//  CocoaTests.m
//  CocoaTests
//
//  Created by Jim Derry on 10/9/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//

#import <XCTest/XCTest.h>
@import SwLibTidy;

@interface CocoaTests : XCTestCase

@end

@implementation CocoaTests

TidyEngine *mydoc;

- (void)setUp
{
    [super setUp];

    mydoc = [[TidyEngine alloc] init];
}

- (void)tearDown
{
    mydoc = nil;

    [super tearDown];
}

- (void)testExample
{
    NSString *myString = [NSString stringWithString:[mydoc getHello]];
    NSLog(@"===>%@\n", myString);

    MyTidyOptionId theId = [mydoc getOptionIdForName: @"clean" ];
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
