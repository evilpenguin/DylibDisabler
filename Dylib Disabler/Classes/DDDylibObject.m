//
//  DDDylibObject.m
//  Dylib Disabler
//
//  Created by EvilPenguin on 7/12/14.
//

#import "DDDylibObject.h"

@implementation DDDylibObject
@synthesize name = _name;
@synthesize path = _path;
@synthesize plistPath = _plistPath;
@synthesize changeType = _changeType;
@synthesize statusType = _statusType;

#pragma mark - == DDDylibObject ==

- (instancetype) init {
    if (self = [super init]) {
        _changeType = DDDylibChangeNone;
        _statusType = DDDylibStatusUnknown;
    }
    
    return self;
}

#pragma mark - == Public Methods ==

- (void) setStatusTypeFromString:(NSString *)string {
    if (string.length > 0) {
        if ([string rangeOfString:@".dylib"].location != NSNotFound) {
            _statusType = DDDylibStatusEnabled;
        }
        else if ([string rangeOfString:@".disabled"].location != NSNotFound) {
            _statusType = DDDylibStatusDisabled;
        }
    }
}

#pragma mark - == Memory == 

- (void) dealloc {
    self.name = nil;
    self.path = nil;
    self.plistPath = nil;
    
    [super dealloc];
}

@end
