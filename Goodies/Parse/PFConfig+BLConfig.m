//
//  PFConfig+BLConfig.m
//  Project
//
//  Created by André Campana on 11/12/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "PFConfig+BLConfig.h"
#import "BLInternet.h"
#import "BLLogger.h"


@implementation PFConfig (BLConfig)

+ (void)loadConfigWithBlock:(ParseCompletionBlock)block
{
    //Internet
    if (![BLInternet doWeHaveInternet]) {
        [PFObject returnToSenderWithResult:NO
                        andCompletionBlock:block];
        return;
    }
    
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    NSTimer *timer = [self startTimeoutOperationWithBlock:^
    {
        [PFObject returnToSenderWithResult:NO
                        andCompletionBlock:block];
        [PFConfig endBackgroundTask:bgTaskId];
    }];
    
    //Loading
    [PFConfig getConfigInBackgroundWithBlock:^(PFConfig *config, NSError *error)
    {
        if (error) ParseLog(@"%@",error);
        [PFObject returnToSenderWithResult:(config != nil)
                        andCompletionBlock:block];
        [PFConfig stopTimeoutOperation:timer];
        [PFConfig endBackgroundTask:bgTaskId];
    }];
}

@end
