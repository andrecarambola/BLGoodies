//
//  NSObject+Goodies.m
//  Goodies
//
//  Created by André Abou Chami Campana on 24/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "NSObject+Goodies.h"


#ifndef kBLTimeoutBlockKey
#define kBLTimeoutBlockKey @"TimeoutBlockKey"
#endif


static NSTimeInterval defaultTimeoutTime = 10;


@implementation NSObject (Background)

+ (UIBackgroundTaskIdentifier)startBackgroundTask
{
    UIBackgroundTaskIdentifier bgTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
    {
        [NSObject endBackgroundTask:bgTaskId];
    }];
    return bgTaskId;
}

+ (void)endBackgroundTask:(UIBackgroundTaskIdentifier)bgTaskId
{
    if (bgTaskId == UIBackgroundTaskInvalid) return;
    [[UIApplication sharedApplication] endBackgroundTask:bgTaskId];
    bgTaskId = UIBackgroundTaskInvalid;
}

@end


@implementation NSObject (Timeout)

+ (void)setDefaultTimeoutTime:(NSTimeInterval)defaultTimeout
{
    defaultTimeoutTime = defaultTimeout;
}

+ (NSTimeInterval)defaultTimeoutTime
{
    return defaultTimeoutTime;
}

+ (NSTimer *)startTimeoutOperationWithBlock:(TimeoutBlock)timeoutBlock
{
    return [self startTimeoutOperationWithInterval:[self defaultTimeoutTime]
                                          andBlock:timeoutBlock];
}

+ (NSTimer *)startTimeoutOperationWithInterval:(NSTimeInterval)interval
                                      andBlock:(TimeoutBlock)timeoutBlock
{
    return [self startTimeoutOperationWithTarget:self
                                          action:@selector(operationDidTimeout:)
                                        interval:interval
                                        andBlock:timeoutBlock];
}

+ (NSTimer *)startTimeoutOperationWithTarget:(id)target
                                      action:(SEL)action
                                    interval:(NSTimeInterval)interval
                                    andBlock:(TimeoutBlock)timeoutBlock
{
    NSAssert(target != nil && action != NULL, @"Target and action should not be void");
    NSDictionary *userInfo = (timeoutBlock != nil) ? @{kBLTimeoutBlockKey: [timeoutBlock copy]} : nil;
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                      target:target
                                                    selector:action
                                                    userInfo:userInfo
                                                     repeats:NO];
    return timer;
}

+ (void)operationDidTimeout:(NSTimer *)timer
{
    TimeoutBlock block = [timer.userInfo objectForKey:kBLTimeoutBlockKey];
    if (block) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
    [self stopTimeoutOperation:timer];
}

+ (void)stopTimeoutOperation:(NSTimer *)timer
{
    [timer invalidate];
}

@end
