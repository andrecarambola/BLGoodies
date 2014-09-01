//
//  PFRole+BLRole.m
//  Parse
//
//  Created by André Abou Chami Campana on 06/07/14.
//  Copyright (c) 2014 BaffiLab. All rights reserved.
//

#import "PFRole+BLRole.h"


@implementation PFRole (BLRole)

+ (NSString *)roleNameForType:(blRoles)roleType
{
    NSString *result = @"";
    switch (roleType) {
        case blRoleAdmin:
            result = @"Admin";
            break;
        case blRoleClient:
            result = @"Client";
            break;
        default:
            break;
    }
    return result;
}

@end
