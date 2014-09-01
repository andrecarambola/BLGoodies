//
//  BLQueuer.m
//  Goodies
//
//  Created by André Abou Chami Campana on 24/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLQueuer.h"


static BLQueuer *myQueuer;


@interface BLQueuer ()
{
    int operationCount;
}

//Singleton
+ (BLQueuer *)privateQueuer;
+ (void)destroyQueuer;

//Queues
@property (nonatomic, strong) NSOperationQueue *concurrentQueue;
@property (nonatomic, strong) NSOperationQueue *sequentialQueue;

//Enqueueing Operations
- (void)enqueueOperation:(NSOperation *)operation
            isConcurrent:(BOOL)isConcurrent;
- (void)operationDidStart;
- (void)operationDidEnd;

//Aux
- (BOOL)hasOperations;

@end


@implementation BLQueuer

#pragma mark - Public Methods

+ (void)enqueueConcurrentOperationWithBlock:(void (^)(void))block
{
    if (!block) return;
    [self enqueueConcurrentOperation:[NSBlockOperation blockOperationWithBlock:block]];
}

+ (void)enqueueConcurrentOperation:(NSOperation *)operation
{
    if (!operation) return;
    [[BLQueuer privateQueuer] enqueueOperation:operation
                                  isConcurrent:YES];
}

+ (void)enqueueSequentialOperationWithBlock:(void (^)(void))block
{
    if (!block) return;
    [self enqueueSequentialOperation:[NSBlockOperation blockOperationWithBlock:block]];
}

+ (void)enqueueSequentialOperation:(NSOperation *)operation
{
    if (!operation) return;
    [[BLQueuer privateQueuer] enqueueOperation:operation
                                  isConcurrent:NO];
}


#pragma mark - Singleton

+ (BLQueuer *)privateQueuer
{
    @synchronized(self)
    {
        if (!myQueuer) myQueuer = [[BLQueuer alloc] init];
        return myQueuer;
    }
}

+ (void)destroyQueuer
{
    @synchronized(self)
    {
        myQueuer = nil;
    }
}


#pragma mark - Setup

- (void)setup
{
    [super setup];
    operationCount = 0;
    [self setHandlesMemory:YES];
    [self setHandlesAppStates:YES];
}


#pragma mark - Memory

- (void)handleMemoryWarningNotification:(NSNotification *)notification
{
    [super handleMemoryWarningNotification:notification];
    if (!self.hasOperations) [BLQueuer destroyQueuer];
}


#pragma mark - App States

- (void)handleAppStateChange:(BOOL)toTheBackground
{
    [super handleAppStateChange:toTheBackground];
    if (toTheBackground && !self.hasOperations) [BLQueuer destroyQueuer];
}


#pragma mark - Queues

- (NSOperationQueue *)concurrentQueue
{
    if (!_concurrentQueue) {
        _concurrentQueue = [[NSOperationQueue alloc] init];
        [_concurrentQueue setName:@"BLConcurrentQueue"];
    }
    return _concurrentQueue;
}

- (NSOperationQueue *)sequentialQueue
{
    if (!_sequentialQueue) {
        _sequentialQueue = [[NSOperationQueue alloc] init];
        [_sequentialQueue setName:@"BLSequentialQueue"];
        [_sequentialQueue setMaxConcurrentOperationCount:1];
    }
    return _sequentialQueue;
}


#pragma mark - Enqueueing Operations

- (void)enqueueOperation:(NSOperation *)operation
            isConcurrent:(BOOL)isConcurrent
{
    [self operationDidStart];
    UIBackgroundTaskIdentifier bgTaskId = [BLQueuer startBackgroundTask];
    void (^completionBlock) (void) = operation.completionBlock;
    [operation setCompletionBlock:^{
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock();
            });
        }
        [BLQueuer endBackgroundTask:bgTaskId];
        [[BLQueuer privateQueuer] operationDidEnd];
    }];
    NSOperationQueue *queue = (isConcurrent) ? self.concurrentQueue : self.sequentialQueue;
    [queue addOperation:operation];
}

- (void)operationDidStart
{
    ++operationCount;
}

- (void)operationDidEnd
{
    --operationCount;
    if (operationCount < 0) operationCount = 0;
    if (![self hasOperations]) [BLQueuer destroyQueuer];
}


#pragma mark - Aux

- (BOOL)hasOperations
{
    return operationCount > 0;
}

@end
