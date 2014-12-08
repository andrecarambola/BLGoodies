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

//Registering
+ (void)registerForPushNotificationsWithBlock:(ParseCompletionBlock)block;
+ (void)handlePushRegistrationWithSuccess:(BOOL)hasSucceeded
                                  andData:(NSData *)data;

//Send Push To Channel
+ (void)sendPushToChannels:(NSArray *)channels
                  withData:(NSDictionary *)data
                  andBlock:(ParseCompletionBlock)block;

//Send Push To User
+ (void)sendPushToUsers:(NSArray *)users
               withData:(NSDictionary *)data
               andBlock:(ParseCompletionBlock)block;

@end
