//
//  PFRole+BLRole.h
//  Parse
//
//  Created by André Abou Chami Campana on 06/07/14.
//  Copyright (c) 2014 BaffiLab. All rights reserved.
//

#import <Parse/Parse.h>


typedef enum {
    blRoleAdmin,
    blRoleClient
} blRoles;


@interface PFRole (BLRole)

+ (NSString *)roleNameForType:(blRoles)roleType;

@end
