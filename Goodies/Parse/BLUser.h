//
//  BLUser.h
//  Parse
//
//  Created by André Abou Chami Campana on 06/07/14.
//  Copyright (c) 2014 BaffiLab. All rights reserved.
//

#import <Parse/Parse.h>
#import "PFObject+BLObject.h"


@interface BLUser : PFUser <PFSubclassing>

//States
+ (BOOL)isLogged;
+ (BOOL)isFacebookUser;
+ (BOOL)isTwitterUser;

@end
