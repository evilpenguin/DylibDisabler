//
//  RootViewController.m
//  Dylib Disabler
//
//  Created by James Emrich on 1/2/11.
//  Copyright 2011 James Emrich. All rights reserved.
//

#import <objc/runtime.h>
#import "DDRootViewController.h"
#import "DDDylibObject.h"
#include <spawn.h>
#import <dlfcn.h>
#import <sys/stat.h>
#import <unistd.h>

#define FLAG_PLATFORMIZE (1 << 1)

void platformize_me() {
    void* handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
    if (!handle) return;
    
    // Reset errors
    dlerror();
    typedef void (*fix_entitle_prt_t)(pid_t pid, uint32_t what);
    fix_entitle_prt_t ptr = (fix_entitle_prt_t)dlsym(handle, "jb_oneshot_entitle_now");
    
    const char *dlsym_error = dlerror();
    if (dlsym_error) return;
    
    ptr(getpid(), FLAG_PLATFORMIZE);
}

void patch_setuid() {
    void* handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
    if (!handle)
        return;
    
    // Reset errors
    dlerror();
    typedef void (*fix_setuid_prt_t)(pid_t pid);
    fix_setuid_prt_t ptr = (fix_setuid_prt_t)dlsym(handle, "jb_oneshot_fix_setuid_now");
    
    const char *dlsym_error = dlerror();
    if (dlsym_error)
        return;
    
    ptr(getpid());
}

#if TARGET_IPHONE_SIMULATOR
    NSString *const DDDylibDirectory = @"/Users/jamesemrich/Desktop/Projects/DylibDisabler/DynamicLibraries";
#else
    NSString *const DDDylibDirectory = @"/Library/MobileSubstrate/DynamicLibraries";
#endif

@interface UILabel()
    - (void) setDrawsUnderline:(BOOL)underline;
@end

@interface UIApplication()
    - (void) terminateWithSuccess;
@end

@interface DDRootViewController (Private)
    - (void) _apply:(id)sender;
    - (void) _applyOnBackgroundThread;
    - (void) _loadDylibs;
    - (void) _validateDylibChange;
    - (void) _updateCell:(UITableViewCell *)cell withDylibIndex:(NSIndexPath *)indexPath;
    - (void) _updateLeftLabelForCount:(NSUInteger)count;
@end

@implementation DDRootViewController

#pragma mark - == DDRootViewController ==

- (instancetype) init {
	if (self = [super init]) {
        _dylibObjectArray   = [[NSMutableArray alloc] init];
        _isIos7 = ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0);

	}
    
	return self;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return NO;
}

- (void) viewWillLayoutSubviews {
    CGRect viewFrame = self.view.frame;
    CGFloat iOS7Offset = (_isIos7 ? 15.0f : 0.0f);

    _toolBar.frame = CGRectMake(0.0f, 0.0f, viewFrame.size.width, 45.0f + iOS7Offset);
    
    CGFloat tableYOffset = (_toolBar.frame.origin.y + _toolBar.frame.size.height);
    _tableView.frame = CGRectMake(0.0f, tableYOffset, viewFrame.size.width, viewFrame.size.height - tableYOffset);
    
    [super viewWillLayoutSubviews];
}

- (void) viewDidLoad {
    UIBarButtonItem *flexItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, (_isIos7 ? 20.0f : 15.0f), 110.0f, 20.0f)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = @"Dylib Disabler";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont fontWithName:@"Futura-Medium" size:17.0f];
    titleLabel.bounds = CGRectOffset(titleLabel.bounds, 10.0f, 10.0f);
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 10.0f, 110.0f, 50.0f)];
    view.backgroundColor = [UIColor clearColor];
    [view addSubview:titleLabel];
    [titleLabel release];
    
    UIBarButtonItem *title = [[[UIBarButtonItem alloc] initWithCustomView:view] autorelease];
    [view release];

    _leftBarItem = [[UIBarButtonItem alloc] initWithTitle:@"Apply" style:UIBarButtonItemStylePlain target:self action:@selector(_apply:)];
    _leftBarItem.enabled = NO;
    [_leftBarItem setBackgroundImage:[[UIImage new] autorelease] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [self _updateLeftLabelForCount:0];

    _toolBar = [[UIToolbar alloc] initWithFrame:CGRectZero];
    _toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _toolBar.barStyle = UIBarStyleBlack;
    _toolBar.items = @[flexItem, title, flexItem, _leftBarItem];
    _toolBar.backgroundColor = [UIColor colorWithRed:85.0f/255.0f green:103.0f/255.0f blue:71.0f/255.0f alpha:1.0f];
    [_toolBar setBackgroundImage:[[UIImage new] autorelease] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [self.view addSubview:_toolBar];

    CGFloat tableYOffset = (_toolBar.frame.origin.y + _toolBar.frame.size.height);
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.backgroundView = nil;
    _tableView.backgroundColor = [UIColor whiteColor];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [[[UIView alloc] init] autorelease];
    _tableView.separatorColor = [UIColor clearColor];
    [self.view addSubview:_tableView];
    
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated {
    [self performSelectorInBackground:@selector(_loadDylibs) withObject:nil];
    [super viewWillAppear:animated];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark -
#pragma mark == Private Methods ==

- (void) _apply:(id)sender {
    _leftBarItem.enabled = NO;
    
    [self performSelectorInBackground:@selector(_applyOnBackgroundThread) withObject:nil];
}

- (void) _applyOnBackgroundThread {
    @autoreleasepool {
        patch_setuid();
        platformize_me();
        setuid(0);
        if((chdir("/")) < 0) {
            exit(EXIT_FAILURE);
        }
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        for (DDDylibObject *dylibObject in _dylibObjectArray) {
            if (dylibObject.changeType == DDDylibChangeDelete) {
                NSError *dylibError = nil;
                [fileManager removeItemAtPath:dylibObject.path error:&dylibError];
                if (dylibError != nil) NSLog(@"DylibDisabler Dylib Deletion Error: %@", dylibError.description);
                
                NSError *plistError = nil;
                [fileManager removeItemAtPath:dylibObject.plistPath error:&plistError];
                if (plistError != nil) NSLog(@"DylibDisabler Plist Deletion Error: %@", dylibError.description);
            }
            else if (dylibObject.changeType == DDDylibChangeDisable) {
                NSError *error = nil;
                [fileManager moveItemAtPath:dylibObject.path
                                     toPath:[NSString stringWithFormat:@"%@/%@.disabled", DDDylibDirectory, dylibObject.name]
                                      error:&error];
                if (error != nil) NSLog(@"DylibDisabler Disable Error: %@", error.description);
            }
            else if (dylibObject.changeType == DDDylibChangeEnable) {
                NSError *error = nil;
                [fileManager moveItemAtPath:dylibObject.path
                                     toPath:[NSString stringWithFormat:@"%@/%@.dylib", DDDylibDirectory, dylibObject.name]
                                      error:&error];
                if (error != nil) NSLog(@"DylibDisabler Enable Error: %@", error.description);
            }
            
            dylibObject.changeType = DDDylibChangeNone;
        }
        
        #if TARGET_IPHONE_SIMULATOR
            [[UIApplication sharedApplication] terminateWithSuccess];
        #else
            pid_t pid;
            int status;
            const char* args[] = {"killall", "SpringBoard", NULL};
            posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
            waitpid(pid, &status, WEXITED);
        #endif
    }
}

- (void) _loadDylibs {
    @autoreleasepool {
        NSLog(@"DylibDisabler: Loading Dylibs");
        
        NSError *dylibError = nil;
        NSArray *dylibContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:DDDylibDirectory error:&dylibError];
        if (dylibContents == nil && dylibError != nil) {
            NSLog(@"DylibDisabler: Content Reading Erroing: %@", dylibError);
        }
        else {
            [_dylibObjectArray removeAllObjects];
            
            for (NSString *dylibName in dylibContents) {
                if ([dylibName rangeOfString:@".dylib"].location != NSNotFound || [dylibName rangeOfString:@".disabled"].location != NSNotFound) {
                    DDDylibObject *dylib = [[DDDylibObject alloc] init];
                    [dylib setStatusTypeFromString:dylibName];
                    
                    NSRange dylibRandge = [dylibName rangeOfString:@"."];
                    if (dylibRandge.location != NSNotFound) {
                        dylib.name = [dylibName substringWithRange:NSMakeRange(0, dylibRandge.location)];
                    }

                    dylib.path = [NSString stringWithFormat:@"%@/%@", DDDylibDirectory, dylibName];
                    dylib.plistPath = [NSString stringWithFormat:@"%@/%@.plist", DDDylibDirectory, dylib.name];
                    [_dylibObjectArray addObject:dylib];
                    [dylib release];
                }
            }
            
            [_dylibObjectArray sortUsingComparator:^NSComparisonResult(DDDylibObject *obj1, DDDylibObject *obj2) {
                return [obj1.name compare:obj2.name];
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_tableView reloadData];
            });
        }
    }
}

- (void) _validateDylibChange {
    @autoreleasepool {
        NSUInteger count = 0;
        for (DDDylibObject *dylibObject in _dylibObjectArray) {
            if (~dylibObject.changeType != 0x00) {
                count++;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _leftBarItem.title = [NSString stringWithFormat:@"Apply%@", (count > 0 ? [NSString stringWithFormat:@" (%lu)", (unsigned long)count] : @"")];
            _leftBarItem.enabled = count > 0;
            [self _updateLeftLabelForCount:count];
        });
    }
}

- (void) _updateCell:(UITableViewCell *)cell withDylibIndex:(NSIndexPath *)indexPath  {
    if (cell != nil) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.font = [UIFont fontWithName:@"Futura-Medium" size:15.0f];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.font = [UIFont fontWithName:@"Futura-Medium" size:10.0f];

        if (indexPath.row < _dylibObjectArray.count) {
            DDDylibObject *dylibObject = [_dylibObjectArray objectAtIndex:indexPath.row];
            if (dylibObject != nil) {
                cell.textLabel.text = dylibObject.name;
                
                switch (dylibObject.changeType) {
                    case DDDylibChangeNone: {
                        switch (dylibObject.statusType) {
                            case DDDylibStatusDisabled: {
                                cell.backgroundColor = [UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:128.0f/255.0f alpha:1.0f];
                                cell.textLabel.textColor = [UIColor blackColor];
                                cell.detailTextLabel.text = @"Disabled";
                                cell.detailTextLabel.textColor = [UIColor blackColor];
                                [cell.detailTextLabel setDrawsUnderline:NO];
                                
                                break;
                            }
                            case DDDylibStatusEnabled: {
                                cell.backgroundColor = [UIColor colorWithRed:185.0f/255.0f green:255.0f/255.0f blue:128.0f/255.0f alpha:1.0f];
                                cell.textLabel.textColor = [UIColor blackColor];
                                cell.detailTextLabel.text = @"Enabled";
                                cell.detailTextLabel.textColor = [UIColor blackColor];
                                [cell.detailTextLabel setDrawsUnderline:NO];
                                
                                break;
                            }
                            default:
                                break;
                        }

                        break;
                    }
                    case DDDylibChangeDelete: {
                        cell.backgroundColor = [UIColor colorWithRed:255.0f/255.0f green:128.0f/255.0f blue:128.0f/255.0f alpha:1.0f];
                        cell.textLabel.textColor = [UIColor whiteColor];
                        cell.detailTextLabel.text = @"Deleting";
                        cell.detailTextLabel.textColor = [UIColor whiteColor];
                        [cell.detailTextLabel setDrawsUnderline:YES];
                        break;
                    }
                    case DDDylibChangeDisable: {
                        cell.backgroundColor = [UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:128.0f/255.0f alpha:1.0f];
                        cell.textLabel.textColor = [UIColor blackColor];
                        cell.detailTextLabel.text = @"Disabling";
                        cell.detailTextLabel.textColor = [UIColor blackColor];
                        [cell.detailTextLabel setDrawsUnderline:YES];
                        break;
                    }
                    case DDDylibChangeEnable: {
                        cell.backgroundColor = [UIColor colorWithRed:185.0f/255.0f green:255.0f/255.0f blue:128.0f/255.0f alpha:1.0f];
                        cell.textLabel.textColor = [UIColor blackColor];
                        cell.detailTextLabel.text = @"Enabling";
                        cell.detailTextLabel.textColor = [UIColor blackColor];
                        [cell.detailTextLabel setDrawsUnderline:YES];
                        break;
                    }
                    default:
                        break;
                }
                
                
            }
        }
    }
}

- (void) _updateLeftLabelForCount:(NSUInteger)count {
    UIColor *color = (count > 0 ? [UIColor whiteColor] : [UIColor lightGrayColor]);
    [_leftBarItem setTitleTextAttributes:@{(_isIos7 ? NSForegroundColorAttributeName : UITextAttributeTextColor) : color,
                                           (_isIos7 ? NSFontAttributeName : UITextAttributeFont) : [UIFont fontWithName:@"Futura-Medium" size:(_isIos7 ? 12.0f : 15.0f)]}
                                forState:UIControlStateNormal];
}

#pragma mark -
#pragma mark == UITableViewController Delegates/DataSource ==

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	return 50.0f;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dylibObjectArray.count;
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self _updateCell:cell withDylibIndex:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {    
    static NSString *cellIdentifier = @"DylibCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier] autorelease];

    return cell;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (indexPath.row < _dylibObjectArray.count) {
            DDDylibObject *dylibObject = [_dylibObjectArray objectAtIndex:indexPath.row];
            if (dylibObject != nil) {
                dylibObject.changeType = DDDylibChangeDelete;
            }
            
            [self _updateCell:[_tableView cellForRowAtIndexPath:indexPath] withDylibIndex:indexPath];
            [self performSelectorInBackground:@selector(_validateDylibChange) withObject:nil];
        }
	}
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < _dylibObjectArray.count) {
        DDDylibObject *dylibObject = [_dylibObjectArray objectAtIndex:indexPath.row];
        if (dylibObject != nil) {
            switch (dylibObject.statusType) {
                case DDDylibStatusDisabled: {
                    dylibObject.changeType = (dylibObject.changeType == DDDylibChangeNone ? DDDylibChangeEnable : DDDylibChangeNone);

                    break;
                }
                case DDDylibStatusEnabled: {
                    dylibObject.changeType = (dylibObject.changeType == DDDylibChangeDisable || dylibObject.changeType == DDDylibChangeDelete ? DDDylibChangeNone : DDDylibChangeDisable);
                    break;
                }
                default:
                    break;
            }
        }
        
        [self _updateCell:[_tableView cellForRowAtIndexPath:indexPath] withDylibIndex:indexPath];
        [self performSelectorInBackground:@selector(_validateDylibChange) withObject:nil];
    }
}

#pragma mark -
#pragma mark == Memory ==

- (void) dealloc {
    [_leftBarItem release];
    [_toolBar release];
    
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
    [_tableView release];
    
    [_dylibObjectArray removeAllObjects];
	[_dylibObjectArray release];
    
	[super dealloc];
}

@end