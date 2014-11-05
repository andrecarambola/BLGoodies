//
//  PFCloud+BLCloud.m
//  Project
//
//  Created by André Abou Chami Campana on 31/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "PFCloud+BLCloud.h"
#import "BLInternet.h"
#import "BLObject.h"
#import "BLParseUser.h"
#import "BLLogger.h"
#import "NSObject+Goodies.h"


@implementation PFCloud (BLCloud)

#pragma mark - Default Functions

+ (void)callFunction:(NSString *)function
      withParameters:(NSDictionary *)parameters
            andBlock:(ParseCompletionBlock)block
{
    //Sanity
    if (function.length == 0) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(NO);
            });
        }
        return;
    }
    
    //Internet
    if (![BLInternet doWeHaveInternet]) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(NO);
            });
        }
        return;
    }
    
    //Calling function
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    NSTimer *timer = [self startTimeoutOperationWithBlock:^
    {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(NO);
            });
        }
        [PFCloud endBackgroundTask:bgTaskId];
    }];
    [PFCloud callFunctionInBackground:function
                       withParameters:parameters
                                block:^(id object, NSError *error)
    {
        if (error) ParseLog(@"%@",error);
        BOOL success = ([object isKindOfClass:[NSNumber class]]) ? [object boolValue] : NO;
        if ([object isKindOfClass:[NSString class]]) ParseLog(@"%@",object);
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(success);
            });
        }
        [PFCloud stopTimeoutOperation:timer];
        [PFCloud endBackgroundTask:bgTaskId];
    }];
}

@end
