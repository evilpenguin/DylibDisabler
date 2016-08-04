//
//  RootViewController.h
//  Dylib Disabler
//
//  Created by James Emrich on 1/2/11.
//  Copyright 2011 James Emrich. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DDRootViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    @private
    UIToolbar       *_toolBar;
    UIBarButtonItem *_leftBarItem;
    UITableView     *_tableView;
    NSMutableArray  *_dylibObjectArray;
    BOOL            _isIos7;
}

- (instancetype) init;

@end
