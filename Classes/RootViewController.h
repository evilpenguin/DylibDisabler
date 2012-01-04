//
//  RootViewController.h
//  Dylib Disabler
//
//  Created by James Emrich on 1/2/11.
//  Copyright 2011 James Emrich. All rights reserved.
//

#import <UIKit/UIKit.h>

#if TARGET_IPHONE_SIMULATOR
    #define DYLIB_DIRECTORY @"/Users/EvilPro/Documents/Projects/Dylib Disabler/fake_dir"
#else
    #define DYLIB_DIRECTORY @"/Library/MobileSubstrate/DynamicLibraries"
#endif

#define RESPRING_KEY @"respring"
#define RESPRING_YES @"Respring-YES"
#define RESPRING_NO @"Respring-NO"

@interface RootViewController : UITableViewController {
	NSUserDefaults  *userDefaults;
	NSFileManager   *fileManager;
	NSMutableArray  *dylibArray;
}

- (id)initWithStyle:(UITableViewStyle)style;
- (void)respring;
@end
