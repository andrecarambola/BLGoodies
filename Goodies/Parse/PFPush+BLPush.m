//
//  PFPush+BLPush.m
//  Project
//
//  Created by André Abou Chami Campana on 05/11/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "PFPush+BLPush.h"
#import "PFCloud+BLCloud.h"
#import "BLParseUser.h"


@interface PFPush (BLAdditions)

+ (BOOL)isValidPushData:(NSDictionary *)data;

@end


@implementation PFPush (BLPush)

#pragma mark - Send Push To Channel

+ (void)sendPushToChannels:(NSArray *)channels
                  withData:(NSDictionary *)data
                  andBlock:(ParseCompletionBlock)block
{
    //Sanity Check
    if (channels.count == 0 || ![self isValidPushData:data])
    {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(NO);
            });
        }
        return;
    }
    
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    //Calling Push Function
    [PFCloud callFunction:@"sendPushToChannels"
           withParameters:@{@"channels": channels,
                            @"pushData": data}
                 andBlock:^(BOOL success)
    {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(success);
            });
        }
        [PFObject endBackgroundTask:bgTaskId];
    }];
}


#pragma mark - Send Push To User

+ (void)sendPushToUsers:(NSArray *)users
               withData:(NSDictionary *)data
               andBlock:(ParseCompletionBlock)block
{
    //Sanity Check
    if (users.count == 0 || ![self isValidPushData:data])
    {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(NO);
            });
        }
        return;
    }
    
    NSMutableArray *userIds = [NSMutableArray array];
    for (BLParseUser *user in users) {
        [userIds addObject:user.objectId];
    }
    
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    //Calling Push Function
    [PFCloud callFunction:@"sendPushToUsers"
           withParameters:@{@"userIds": users,
                            @"pushData": data}
                 andBlock:^(BOOL success)
     {
         if (block) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 block(success);
             });
         }
         [PFObject endBackgroundTask:bgTaskId];
     }];
}

@end


@implementation PFPush (BLAdditions)

+ (BOOL)isValidPushData:(NSDictionary *)data
{
    if (!data) return NO;
    if (data.allKeys.count == 0) return NO;
    id message = [data objectForKey:@"alert"];
    if (![message isKindOfClass:[NSString class]]) return NO;
    if ([(NSString *)message length] == 0) return NO;
    return YES;
}

@end
