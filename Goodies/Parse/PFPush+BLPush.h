//
//  PFPush+BLPush.h
//  Project
//
//  Created by André Abou Chami Campana on 05/11/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import <Parse/Parse.h>
#import "PFObject+BLObject.h"


@class BLParseUser;


@interface PFPush (BLPush)

//Send Push To Channel
+ (void)sendPushToChannel:(NSString *)channel
                 withData:(NSDictionary *)data
                 andBlock:(ParseCompletionBlock)block;

//Send Push To User
+ (void)sendPushToUser:(BLParseUser *)user
              withData:(NSDictionary *)data
              andBlock:(ParseCompletionBlock)block;

@end