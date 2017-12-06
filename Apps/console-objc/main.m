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

        TidyDocument *doc = [[TidyDocument alloc] init];


        NSString *myString = [doc getHello];
        NSLog(@"\n%@\n", myString);

        TidyOptionId id = [doc getOptionIdForName: @"clean"];
        NSLog(@"\n%u\n", id);


    }
    return 0;
}
