//
//  BLUser.m
//  Parse
//
//  Created by André Abou Chami Campana on 06/07/14.
//  Copyright (c) 2014 BaffiLab. All rights reserved.
//

#import "BLUser.h"
#import <Parse/PFObject+Subclass.h>


@implementation BLUser

+ (BOOL)isLogged
{
    return ([PFUser currentUser] != nil);
}



@end
