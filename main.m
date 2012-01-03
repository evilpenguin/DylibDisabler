//
//  main.m
//  Dylib Disabler
//
//  Created by EvilPenguin| on 1/2/11.
//  Copyright 2011 NakedProductions. All rights reserved.
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[]) {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    setreuid(0,0);
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
}
