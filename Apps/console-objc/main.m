//
//  main.m
//  console-objc
//
//  Created by Jim Derry on 10/10/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//

#import <Foundation/Foundation.h>
@import SwLibTidy;
@import CLibTidyEnum;


int main(int argc, const char * argv[]) {
    @autoreleasepool {

//        TidyDocument *doc = [[TidyDocument alloc] init];
//
//
//        NSString *myString = [doc getHello];
//        NSLog(@"\n%@\n", myString);
//
//        TidyOptionId id = [doc getOptionIdForName: @"clean"];
//        NSLog(@"\n%u\n", id);

        TestClass *myTest = [[TestClass alloc] init];
        NSString *myString = myTest.hello;
        NSLog( @"\n%@\n", myString );
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

    }
    return 0;
}
