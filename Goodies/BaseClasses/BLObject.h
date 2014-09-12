//
//  BLObject.h
//  Goodies
//
//  Created by André Abou Chami Campana on 24/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+Goodies.h"
#import "Reachability.h"


@interface BLObject : NSObject

//Setup
- (void)setup;

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
