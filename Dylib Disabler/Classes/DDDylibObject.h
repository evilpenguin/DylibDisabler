//
//  DDDylibObject.h
//  Dylib Disabler
//
//  Created by EvilPenguin on 7/12/14.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    DDDylibChangeNone       = -1,
    DDDylibChangeDelete     = 1,
    DDDylibChangeDisable    = 2,
    DDDylibChangeEnable     = 3
} DDDylibChangeType;

typedef enum {
    DDDylibStatusUnknown    = -1,
    DDDylibStatusDisabled   = 0,
    DDDylibStatusEnabled    = 1
} DDDylibStatusType;

@interface DDDylibObject : NSObject {
    
}
@property (nonatomic, retain) NSString          *name;
@property (nonatomic, retain) NSString          *path;
@property (nonatomic, retain) NSString          *plistPath;
@property (nonatomic, assign) DDDylibChangeType changeType;
@property (nonatomic, assign) DDDylibStatusType statusType;

- (instancetype) init;
- (void) setStatusTypeFromString:(NSString *)string;

@end
