//
//  RootViewController.h
//  Dylib Disabler
//
//  Created by James Emrich on 1/2/11.
//  Copyright 2011 James Emrich. All rights reserved.
//

#import <UIKit/UIKit.h>

#if TARGET_IPHONE_SIMULATOR
    #define DYLIB_DIRECTORY @"/Users/EvilPro/Desktop/DylibDisabler_fake"
#else
    #define DYLIB_DIRECTORY @"/Library/MobileSubstrate/DynamicLibraries"
#endif

#define iOS7 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)


@interface DDRootViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    @private
    UIToolbar       *_toolBar;
    UIBarButtonItem *_leftBarItem;
    UITableView     *_tableView;
    NSMutableArray  *_dylibObjectArray;
}

- (instancetype) init;

@end
