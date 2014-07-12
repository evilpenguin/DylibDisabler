//
//  DylibDisablerAppDelegate.m
//  Dylib Disabler
//
//  Created by James Emrich on 1/2/11.
//  Copyright 2011  © James Emrich. All rights reserved.
//

#import "DDAppDelegate.h"

@implementation DDAppDelegate
@synthesize window = _window;
@synthesize rootView = _rootView;

#pragma mark - == DDAppDelegate ==

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {  
	_rootView = [[DDRootViewController alloc] init];

    _window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    _window.rootViewController = _rootView;
    [_window makeKeyAndVisible];

    return YES;
    
}

#pragma mark - == Memory ==

- (void)dealloc {
    [_rootView release];
    [_window release];

	[super dealloc];
}

@end