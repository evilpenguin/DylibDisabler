//
//  main.m
//  Dylib Disabler
//
//  Created by EvilPenguin| on 1/2/11.
//  Copyright 2011 NakedProductions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DDAppDelegate.h"

int main(int argc, char *argv[]) {
    @autoreleasepool {
        int setuid = setreuid(0, 0);
        if (setuid == 0) NSLog(@"DD is running as root...");
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass(DDAppDelegate.class));
    }
}
