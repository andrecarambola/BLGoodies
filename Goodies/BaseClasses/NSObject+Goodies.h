//
//  NSObject+Goodies.h
//  Goodies
//
//  Created by André Abou Chami Campana on 24/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef void (^TimeoutBlock) (void);


@interface NSObject (Background)

+ (UIBackgroundTaskIdentifier)startBackgroundTask;
+ (void)endBackgroundTask:(UIBackgroundTaskIdentifier)bgTaskId;

@end


@interface NSObject (Timeout)

+ (void)setDefaultTimeoutTime:(NSTimeInterval)defaultTimeout;
+ (NSTimeInterval)defaultTimeoutTime;
+ (NSTimer *)startTimeoutOperationWithBlock:(TimeoutBlock)timeoutBlock;
+ (NSTimer *)startTimeoutOperationWithInterval:(NSTimeInterval)interval
                                      andBlock:(TimeoutBlock)timeoutBlock;
+ (NSTimer *)startTimeoutOperationWithTarget:(id)target
                                      action:(SEL)action
                                    interval:(NSTimeInterval)interval
                                    andBlock:(TimeoutBlock)timeoutBlock;
+ (void)operationDidTimeout:(NSTimer *)timer;
+ (void)stopTimeoutOperation:(NSTimer *)timer;

@end
