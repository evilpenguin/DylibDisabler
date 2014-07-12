//
//  DylibDisablerAppDelegate.h
//  Dylib Disabler
//
//  Created by James Emrich on 1/2/11.
//  Copyright 2011 James Emrich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DDRootViewController.h"

@interface DDAppDelegate : UIResponder <UIApplicationDelegate> {

}
@property (nonatomic, retain) UIWindow					*window;
@property (nonatomic, readonly) DDRootViewController    *rootView;

@end

