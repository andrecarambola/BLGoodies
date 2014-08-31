//
//  BLObject.m
//  Goodies
//
//  Created by André Abou Chami Campana on 24/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLObject.h"
#import "BLDefines.h"


@interface BLObject ()

//Background
@property (nonatomic) UIBackgroundTaskIdentifier bgTaskId;

//App States
- (void)handleWeAreGoingToTheBackgroundNotification:(NSNotification *)notification;
- (void)handleWeAreComingBackFromTheBackgroundNotification:(NSNotification *)notification;

//Internet
@property (nonatomic) BLInternetStatusChangeBlockIdentifier internetId;

//Timeout
@property (nonatomic, weak) NSTimer *timeoutTimer;

@end


@implementation BLObject

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setHandlesInternet:NO];
}


#pragma mark - Setup

- (id)init
{
    if (self = [super init]) [self setup];
    return self;
}

- (void)setup
{
    _bgTaskId = UIBackgroundTaskInvalid;
    _handlesMemory = NO;
    _handlesAppStates = NO;
    [self setHandlesInternet:YES];
    _internetId = BLInternetStatusChangeInvalid;
}


#pragma mark - Background

- (void)startBackgroundTask
{
    if (self.bgTaskId != UIBackgroundTaskInvalid) return;
    [self setBgTaskId:[BLObject startBackgroundTask]];
}

- (void)endBackgroundTask
{
    if (self.bgTaskId == UIBackgroundTaskInvalid) return;
    [BLObject endBackgroundTask:self.bgTaskId];
    [self setBgTaskId:UIBackgroundTaskInvalid];
}


#pragma mark - Memory

- (void)setHandlesMemory:(BOOL)handlesMemory
{
    if (_handlesMemory == handlesMemory || !_handlesMemory) {
        [self willChangeValueForKey:@"handlesMemory"];
        
        if (handlesMemory) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleMemoryWarningNotification:)
                                                         name:UIApplicationDidReceiveMemoryWarningNotification
                                                       object:[UIApplication sharedApplication]];
        } else {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:UIApplicationDidReceiveMemoryWarningNotification
                                                          object:[UIApplication sharedApplication]];
        }
        
        _handlesMemory = handlesMemory;
        [self didChangeValueForKey:@"handlesMemory"];
    }
}

- (void)handleMemoryWarningNotification:(NSNotification *)notification
{
    return;
}


#pragma mark - App States

- (void)setHandlesAppStates:(BOOL)handlesAppStates
{
    if (_handlesAppStates == handlesAppStates || !_handlesAppStates) {
        [self willChangeValueForKey:@"handlesAppStates"];
        
        if (handlesAppStates) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleWeAreGoingToTheBackgroundNotification:)
                                                         name:UIApplicationWillResignActiveNotification
                                                       object:[UIApplication sharedApplication]];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleWeAreComingBackFromTheBackgroundNotification:)
                                                         name:UIApplicationWillEnterForegroundNotification
                                                       object:[UIApplication sharedApplication]];
        } else {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:UIApplicationWillResignActiveNotification
                                                          object:[UIApplication sharedApplication]];
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:UIApplicationWillEnterForegroundNotification
                                                          object:[UIApplication sharedApplication]];
        }
        
        _handlesAppStates = handlesAppStates;
        [self didChangeValueForKey:@"handlesAppStates"];
    }
}

- (void)handleAppStateChange:(BOOL)toTheBackground
{
    return;
}

- (void)handleWeAreGoingToTheBackgroundNotification:(NSNotification *)notification
{
    [self handleAppStateChange:YES];
}

- (void)handleWeAreComingBackFromTheBackgroundNotification:(NSNotification *)notification
{
    [self handleAppStateChange:NO];
}


#pragma mark - Internet

- (void)setHandlesInternet:(BOOL)handlesInternet
{
    if (_handlesInternet == handlesInternet || !_handlesInternet) {
        [self willChangeValueForKey:@"handlesInternet"];
        
        if (handlesInternet) {
            if (self.internetId == BLInternetStatusChangeInvalid) {
                __weak BLObject *weakSelf = self;
                [BLInternet registerInternetStatusChangeBlock:^(NetworkStatus newStatus)
                {
                    [weakSelf handleInternetStateChange:newStatus];
                }];
            }
        } else {
            if (self.internetId != BLInternetStatusChangeInvalid) {
                [BLInternet unregisterInternetStatusChangeBlockWithId:self.internetId];
            }
        }
        
        _handlesInternet = handlesInternet;
        [self didChangeValueForKey:@"handlesInternet"];
    }
}

- (void)handleInternetStateChange:(NetworkStatus)networkStatus
{
    switch (networkStatus) {
        case NotReachable:
            [BLObject setDefaultTimeoutTime:kBLTimeoutTimeForNoConnection];
            break;
        case ReachableViaWiFi:
            [BLObject setDefaultTimeoutTime:kBLTimeoutTimeForWiFI];
            break;
        case ReachableViaWWAN:
            [BLObject setDefaultTimeoutTime:kBLTimeoutTimeFor3G];
            break;
        default:
            break;
    }
}


#pragma mark - Timeout

- (void)startTimeoutOperationWithBlock:(TimeoutBlock)timeoutBlock
{
    if (self.timeoutTimer) [self stopTimeoutOperation];
    NSTimer *timer = [BLObject startTimeoutOperationWithBlock:timeoutBlock];
    [self setTimeoutTimer:timer];
}

- (void)operationDidTimeout:(NSTimer *)timer
{
    [BLObject operationDidTimeout:timer];
    [self stopTimeoutOperation];
}

- (void)stopTimeoutOperation
{
    if (!self.timeoutTimer) return;
    [BLObject stopTimeoutOperation:self.timeoutTimer];
}

@end
