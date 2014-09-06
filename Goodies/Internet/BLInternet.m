//
//  BLInternet.m
//  Goodies
//
//  Created by André Abou Chami Campana on 24/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLInternet.h"
#import "BLDefines.h"


BLInternetStatusChangeBlockIdentifier const BLInternetStatusChangeInvalid = NSNotFound;
static NSString *myHost;
static BLInternet *myInternet;
static NSTimeInterval activityIndicatorThreshold = 1.0;


@interface BLInternet ()

//Singleton
+ (BLInternet *)privateSingleton;
+ (void)destroySingleton;

//Reachability
@property (nonatomic, strong) Reachability *reachability;
- (void)startReachability;
- (void)stopReachability;

//Internet Status Change Block
@property (nonatomic, strong) NSMutableArray *allBlocks;

//Network Activity Indicator
@property (nonatomic) int operationCounter;
@property (nonatomic, weak) NSTimer *internetActivityTimer;
- (void)startInternetActivityTimer;
- (void)activateInternetActivityIndicator:(NSTimer *)timer;
- (void)stopInternetActivityTimer;

//Notifications
- (void)handleReachabilityChangeNotification:(NSNotification *)notification;

@end


@implementation BLInternet


#pragma mark - Singleton

+ (BLInternet *)privateSingleton
{
    @synchronized(self)
    {
        if (!myInternet) myInternet = [[BLInternet alloc] init];
        return myInternet;
    }
}

+ (void)destroySingleton
{
    @synchronized(self)
    {
        myInternet = nil;
    }
}


#pragma mark - Setup

+ (void)startInternetWithHost:(NSString *)host
{
    myHost = host;
    [BLInternet doWeHaveInternet];
}

+ (void)setThresholdForNetworkActivityIndicator:(NSTimeInterval)threshold
{
    activityIndicatorThreshold = threshold;
}

- (void)setup
{
    [super setup];
    _operationCounter = 0;
    [self setHandlesMemory:YES];
    [self setHandlesAppStates:YES];
    [self startReachability];
}


#pragma mark - Internet Status

+ (BOOL)doWeHaveInternet
{
    return [self doWeHaveInternetWithAlert:NO];
}

+ (BOOL)doWeHaveInternetWithAlert:(BOOL)showAlert
{
    BOOL result = ([BLInternet privateSingleton].reachability.currentReachabilityStatus != NotReachable);
    if (showAlert && !result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:appName
                                        message:NSLocalizedStringFromTable(@"BLNoInternetAlert", @"BLGoodies", @"Text to be presented when a connection to the internet cannot be estabilished")
                                       delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil] show];
        });
    }
    return result;
}

+ (NetworkStatus)networkStatus
{
    return [BLInternet privateSingleton].reachability.currentReachabilityStatus;
}


#pragma mark - Internet Status Change Block

+ (BLInternetStatusChangeBlockIdentifier)registerInternetStatusChangeBlock:(InternetStatusChangeBlock)block
{
    if (!block) return BLInternetStatusChangeInvalid;
    [[BLInternet privateSingleton].allBlocks addObject:[block copy]];
    return (BLInternetStatusChangeBlockIdentifier)[BLInternet privateSingleton].allBlocks.count;
}

+ (void)unregisterInternetStatusChangeBlockWithId:(BLInternetStatusChangeBlockIdentifier)identifier
{
    if (identifier == BLInternetStatusChangeInvalid) return;
    if ((int)identifier >= [BLInternet privateSingleton].allBlocks.count) return;
    NSMutableArray *allBlocks = [BLInternet privateSingleton].allBlocks;
    if (allBlocks.count == 0) [[BLInternet privateSingleton] setAllBlocks:nil];
    [allBlocks replaceObjectAtIndex:(int)identifier - 1
                         withObject:[NSNull null]];
    BOOL shouldDelete = YES;
    for (id obj in allBlocks) {
        if (![obj isEqual:[NSNull null]]) {
            shouldDelete = NO;
            break;
        }
    }
    if (shouldDelete) [[BLInternet privateSingleton] setAllBlocks:nil];
}

- (NSMutableArray *)allBlocks
{
    if (!_allBlocks) _allBlocks = [NSMutableArray array];
    return _allBlocks;
}


#pragma mark - Network Activity Indicator

+ (void)willStartInternetOperation
{
    if (![self areWeUsingTheInternet]) [[BLInternet privateSingleton] startInternetActivityTimer];
    ++[BLInternet privateSingleton].operationCounter;
}

+ (BOOL)areWeUsingTheInternet
{
    return [BLInternet privateSingleton].operationCounter > 0;
}

+ (void)didEndInternetOperation
{
    --[BLInternet privateSingleton].operationCounter;
    if ([BLInternet privateSingleton].operationCounter < 0) [BLInternet privateSingleton].operationCounter = 0;
    if (![self areWeUsingTheInternet]) {
        [[BLInternet privateSingleton] startInternetActivityTimer];
    }
}

- (void)startInternetActivityTimer
{
    [self stopInternetActivityTimer];
    self.internetActivityTimer = [NSTimer scheduledTimerWithTimeInterval:activityIndicatorThreshold
                                                                  target:self
                                                                selector:@selector(activateInternetActivityIndicator:)
                                                                userInfo:nil
                                                                 repeats:NO];
}

- (void)activateInternetActivityIndicator:(NSTimer *)timer
{
    if ([BLInternet areWeUsingTheInternet]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        });
    }
    [self stopInternetActivityTimer];
}

- (void)stopInternetActivityTimer
{
    [self.internetActivityTimer invalidate];
    [self setInternetActivityTimer:nil];
}


#pragma mark - Reachability

- (void)startReachability
{
    [self stopReachability];
    if (myHost.length > 0) {
        self.reachability = [Reachability reachabilityWithHostName:myHost];
    } else {
        self.reachability = [Reachability reachabilityForInternetConnection];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleReachabilityChangeNotification:)
                                                 name:kReachabilityChangedNotification
                                               object:self.reachability];
    [self.reachability startNotifier];
}

- (void)stopReachability
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kReachabilityChangedNotification
                                                  object:self.reachability];
    [self.reachability stopNotifier];
    self.reachability = nil;
}


#pragma mark - Notifications

- (void)handleMemoryWarningNotification:(NSNotification *)notification
{
    [super handleMemoryWarningNotification:notification];
    if (_allBlocks.count == 0) {
        _allBlocks = nil;
        [self stopReachability];
    }
    self.operationCounter = 0;
    [BLInternet didEndInternetOperation];
    [BLInternet destroySingleton];
}

- (void)handleAppStateChange:(BOOL)toTheBackground
{
    [super handleAppStateChange:toTheBackground];
    if (toTheBackground) {
        if (_allBlocks.count == 0) {
            _allBlocks = nil;
            [self stopReachability];
        }
    } else {
        if ([BLInternet areWeUsingTheInternet]) {
            [self activateInternetActivityIndicator:nil];
        }
    }
}

- (void)handleReachabilityChangeNotification:(NSNotification *)notification
{
    if (_allBlocks.count == 0) return;
    NetworkStatus newStatus = self.reachability.currentReachabilityStatus;
    for (id obj in self.allBlocks) {
        if (![obj isEqual:[NSNull null]]) {
            InternetStatusChangeBlock block = obj;
            dispatch_async(dispatch_get_main_queue(), ^{
                block(newStatus);
            });
        }
    }
    switch (newStatus) {
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

@end
