//
//  RootViewController.m
//  Dylib Disabler
//
//  Created by EvilPenguin| on 1/2/11.
//  Copyright 2011 NakedProductions. All rights reserved.
//

#import "RootViewController.h"

@interface RootViewController (Private)
	- (void) createControls;
	- (void) loadDylibs;
    - (void) updateCell:(UITableViewCell *)cell atIndex:(NSIndexPath *)indexPath;
@end


@implementation RootViewController

#pragma mark -
#pragma mark == RootViewController lifecycle ==

- (id)initWithStyle:(UITableViewStyle)style {
	if (self = [super initWithStyle:style]) {
		self.title = @"DylibDisabler";
		[self.tableView setAllowsSelectionDuringEditing:YES];
		[self createControls];
        [self loadDylibs];
	}
	return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return NO;
}

#pragma mark -
#pragma mark == Public Methods ==

- (void)respring {
	NSLog(@"Dylib Disabler: Respring function");
	NSString *respringString = [userDefaults objectForKey:RESPRING_KEY];
	if ([respringString isEqualToString:RESPRING_YES]) system("killall -9 SpringBoard");
}

#pragma mark -
#pragma mark == Private Methods ==

- (void) createControls {
	fileManager = [NSFileManager defaultManager];
	dylibArray = [[NSMutableArray alloc] init]; 
	userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:RESPRING_NO forKey:RESPRING_KEY];
	[userDefaults synchronize];
}

- (void) loadDylibs {
	NSLog(@"Dylib Disabler: Loading Dylibs");
	NSError *dylibError = nil;
	NSArray *dylibContents = [fileManager contentsOfDirectoryAtPath:DYLIB_DIRECTORY error:&dylibError];
	if (dylibError) NSLog(@"Dylib Disabler: Content Reading Erroing->%@", dylibError); 
	else { 
		for (NSString *dylibName in dylibContents) {
			if ([dylibName hasSuffix:@".dylib"] || [dylibName hasSuffix:@".disabled"]) [dylibArray addObject:dylibName]; 
		}
		[dylibArray sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        [self.tableView reloadData];
	}
}

- (void) updateCell:(UITableViewCell *)cell atIndex:(NSIndexPath *)indexPath {
    if (indexPath.row < [dylibArray count]) {
        NSRange dylibRandge = [[dylibArray objectAtIndex:indexPath.row] rangeOfString:@"."];
        NSString *dylibName = [[dylibArray objectAtIndex:indexPath.row] substringWithRange:NSMakeRange(0, dylibRandge.location)];
        cell.textLabel.text = dylibName;
        cell.textLabel.textColor = ([[dylibArray objectAtIndex:indexPath.row] hasSuffix:@".dylib"] ? [UIColor blackColor] : [UIColor whiteColor]);
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.textColor = ([[dylibArray objectAtIndex:indexPath.row] hasSuffix:@".dylib"] ? [UIColor blackColor] : [UIColor whiteColor]);
        cell.detailTextLabel.text = ([[dylibArray objectAtIndex:indexPath.row] hasSuffix:@".dylib"] ? @"Enabled" : @"Disabled");
        cell.detailTextLabel.font = [UIFont systemFontOfSize:10.0f];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.backgroundColor = ([[dylibArray objectAtIndex:indexPath.row] hasSuffix:@".dylib"] ? [UIColor whiteColor] : [UIColor redColor]);
    }
}

#pragma mark -
#pragma mark ==  UITableViewController ==

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	return 50.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [dylibArray count];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"DylibDisabler © EvilPenguin";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {    
    static NSString *cellID = @"Dylib Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    cell.textLabel.text = @"";
    [self updateCell:cell atIndex:indexPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (indexPath.row < [dylibArray count]) {
            NSRange dylibRandge = [[dylibArray objectAtIndex:indexPath.row] rangeOfString:@"."];
            NSString *dylibName = [[dylibArray objectAtIndex:indexPath.row] substringWithRange:NSMakeRange(0, dylibRandge.location)];
            
            NSString *dylibPath = [NSString stringWithFormat:@"%@/%@", DYLIB_DIRECTORY, [dylibArray objectAtIndex:indexPath.row]];
            NSString *plistPath = [NSString stringWithFormat:@"%@/%@.plist", DYLIB_DIRECTORY, dylibName];
            NSLog(@"Dylib path: %@ \n Dylib Plist path: %@", dylibPath, plistPath);
            
            NSError *dylibError = nil;
            [fileManager removeItemAtPath:dylibPath error:&dylibError];
            if (dylibError != nil) NSLog(@"DylibDisabler Dylib Deletion Error: %@", dylibError.description);
            
            NSError *plistError = nil;
            [fileManager removeItemAtPath:plistPath error:&plistError];
            if (plistError != nil) NSLog(@"DylibDisabler Plist Deletion Error: %@", dylibError.description);
            
            
            [userDefaults setObject:RESPRING_YES forKey:RESPRING_KEY];
            [userDefaults synchronize];
            
            [dylibArray removeObjectAtIndex:indexPath.row];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView reloadData];
        }
	}
}

#pragma mark -
#pragma mark == UITableViewController Delegates ==

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < [dylibArray count]) {
        NSRange dylibRandge = [[dylibArray objectAtIndex:indexPath.row] rangeOfString:@"."];
        NSString *dylibName = [[dylibArray objectAtIndex:indexPath.row] substringWithRange:NSMakeRange(0, dylibRandge.location)];
        NSString *newDylibName = [NSString stringWithFormat:@"%@.%@", dylibName, ([[dylibArray objectAtIndex:indexPath.row] hasSuffix:@".disabled"] ? @"dylib" : @"disabled")];
        
        NSError *error = nil;
        [fileManager moveItemAtPath:[NSString stringWithFormat:@"%@/%@", DYLIB_DIRECTORY, [dylibArray objectAtIndex:indexPath.row]] 
                             toPath:[NSString stringWithFormat:@"%@/%@", DYLIB_DIRECTORY, newDylibName] 
                              error:&error]; 
        
        if (error) NSLog(@"Dylib Disabler: E/D Error->%@", error);
        else {
            [dylibArray removeObjectAtIndex:indexPath.row];
            [dylibArray insertObject:newDylibName atIndex:indexPath.row];
            [userDefaults setObject:RESPRING_YES forKey:RESPRING_KEY];
            [userDefaults synchronize];
        }
        
        [self updateCell:[tableView cellForRowAtIndexPath:indexPath] atIndex:indexPath];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark == Memory management ==

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
	[dylibArray release];
	[super dealloc];
}

@end