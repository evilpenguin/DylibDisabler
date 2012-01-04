//
//  DylibDisablerAppDelegate.m
//  Dylib Disabler
//
//  Created by James Emrich on 1/2/11.
//  Copyright 2011  © James Emrich. All rights reserved.
//

#import "DylibDisablerAppDelegate.h"

@implementation DylibDisablerAppDelegate
@synthesize window;
@synthesize navigationController;
@synthesize rootView;

#pragma mark -
#pragma mark == Application Life Cycle ==

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {  
	rootView = [[RootViewController alloc] initWithStyle:UITableViewStyleGrouped];
	navigationController = [[UINavigationController alloc] initWithRootViewController:rootView];
    [navigationController.navigationBar setBarStyle:1];
    [navigationController.navigationBar setTintColor:[UIColor colorWithRed:0.49f green:0.49f blue:0.49f alpha:1.0f]]; 
    [window addSubview:navigationController.view];
    [window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[rootView respring];
}

#pragma mark -
#pragma mark == Memory management ==

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	NSLog(@"DylibDisabler: Memory Warning");
}


- (void)dealloc {
    [rootView release];
	[navigationController release];
	[window release];
	[super dealloc];
}

@end