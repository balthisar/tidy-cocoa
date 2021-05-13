//
//  main.m
//  console-objc
//
//  Created by Jim Derry on 10/10/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//

#import <Foundation/Foundation.h>
@import TidyKit;

int main(int argc, const char * argv[]) {
    @autoreleasepool {

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

//        SwiftClass *swiftClass = [myTest getSwiftClass];

    }
    return 0;
}
