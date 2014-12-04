//
//  BLPlayerResponder.h
//  Project
//
//  Created by André Abou Chami Campana on 17/09/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLInternet.h"


@interface BLPlayerResponder : UIResponder

//Setup
- (void)setup;

//User Defaults
@property (nonatomic, readonly) NSUserDefaults *userDefaults;

//Background
- (void)startBackgroundTask;
- (void)endBackgroundTask;

//Memory
@property (nonatomic) BOOL handlesMemory;
- (void)handleMemoryWarningNotification:(NSNotification *)notification;

//App States
@property (nonatomic) BOOL handlesAppStates;
- (void)handleAppStateChange:(BOOL)toTheBackground;

//Internet
@property (nonatomic) BOOL handlesInternet;
- (void)handleInternetStateChange:(NetworkStatus)networkStatus;

//Timeout
- (void)startTimeoutOperationWithBlock:(TimeoutBlock)timeoutBlock;
- (void)startTimeoutOperationWithInterval:(NSTimeInterval)timeInterval
                                 andBlock:(TimeoutBlock)timeoutBlock;
- (void)operationDidTimeout:(NSTimer *)timer;
- (void)stopTimeoutOperation;

@end
