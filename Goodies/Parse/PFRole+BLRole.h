//
//  PFRole+BLRole.h
//  Parse
//
//  Created by André Abou Chami Campana on 06/07/14.
//  Copyright (c) 2014 BaffiLab. All rights reserved.
//

#import <Parse/Parse.h>


typedef NS_ENUM(NSInteger, blRoles) {
    blRoleAdmin,
    blRoleClient
};


@interface PFRole (BLRole)

+ (NSString *)roleNameForType:(blRoles)roleType;

@end
