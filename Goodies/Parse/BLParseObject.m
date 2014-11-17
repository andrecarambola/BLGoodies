//
//  BLParseObject.m
//  Project
//
//  Created by André Abou Chami Campana on 31/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLParseObject.h"
#import <Parse/PFObject+Subclass.h>
#import "BLParseUser.h"
#import "BLDefines.h"
#import "BLLogger.h"
#import "Reachability.h"
#import "BLQueuer.h"


#pragma mark - Private Interface
@interface BLParseObject ()

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


#pragma mark - Implementations
@implementation BLParseObject

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setHandlesInternet:NO];
}


#pragma mark - Creating Objects

+ (instancetype)customObject
{
    BLParseObject *result = [[self class] object];
    [result setObject:[BLParseUser currentUser]
               forKey:@"user"];
    [result setup];
    return result;
}

+ (PFQuery *)customQuery
{
    if (![BLParseUser isLogged]) return nil;
    PFQuery *result = [[self class] query];
    [result whereKey:@"user"
             equalTo:[BLParseUser currentUser]];
    return result;
}


#pragma mark - Setup

//+ (NSString *)parseClassName
//{
//    NSAssert([self class] != [PFObject class] && [self class] != [BLParseObject class], @"%@ is not a concrete parse object subclass", [self class]);
//    return NSStringFromClass([self class]);
//}

@synthesize bgTaskId = _bgTaskId;
@synthesize handlesAppStates = _handlesAppStates;
@synthesize handlesInternet = _handlesInternet;
@synthesize internetId = _internetId;

- (void)setup
{
    _bgTaskId = UIBackgroundTaskInvalid;
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
                __weak BLParseObject *weakSelf = self;
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
    return;
}


#pragma mark - Timeout

+ (NSTimeInterval)customTimeoutTime
{
    return [BLObject defaultTimeoutTime];
}

- (NSTimeInterval)customTimeoutTime
{
    return [BLObject defaultTimeoutTime];
}

@synthesize timeoutTimer = _timeoutTimer;

- (void)startTimeoutOperationWithBlock:(TimeoutBlock)timeoutBlock
{
    [self startTimeoutOperationWithInterval:[BLObject defaultTimeoutTime]
                                   andBlock:timeoutBlock];
}

- (void)startTimeoutOperationWithInterval:(NSTimeInterval)timeInterval
                                 andBlock:(TimeoutBlock)timeoutBlock
{
    if (self.timeoutTimer) [self stopTimeoutOperation];
    NSTimer *timer = [BLObject startTimeoutOperationWithTarget:self
                                                        action:@selector(operationDidTimeout:)
                                                      interval:timeInterval
                                                      andBlock:timeoutBlock];
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


#pragma mark - Fetching
@implementation BLParseObject (Fetching)

+ (void)fetchEverythingWithObjects:(NSArray *)objects
                          andBlock:(ParseCompletionBlock)block
{
    //Sanity
    if (objects.count == 0) {
        [self returnToSenderWithResult:YES
                    andCompletionBlock:block];
        return;
    }
    
    //Internet
    if (![BLInternet doWeHaveInternet]) {
        [self returnToSenderWithResult:NO
                    andCompletionBlock:block];
        return;
    }
    
    //Saving
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    NSTimer *timer = [self startTimeoutOperationWithInterval:[self customTimeoutTime]
                                                    andBlock:^
    {
        [BLParseObject returnToSenderWithResult:NO
                             andCompletionBlock:block];
        [BLParseObject endBackgroundTask:bgTaskId];
    }];
    
    void (^returnBlock) (BOOL) = ^(BOOL result)
    {
        [BLParseObject returnToSenderWithResult:result
                             andCompletionBlock:block];
        [BLParseObject stopTimeoutOperation:timer];
        [BLParseObject endBackgroundTask:bgTaskId];
    };
    
    [self fetchDependenciesWithObjects:objects
                              andBlock:^(BOOL success)
    {
        if (!success) {
            returnBlock(NO);
        } else {
            [PFObject fetchAllInBackground:objects
                                     block:^(NSArray *objects, NSError *error)
            {
                if (error) ParseLog(@"%@",error);
                returnBlock(error == nil);
            }];
        }
    }];
}

+ (void)fetchDependenciesWithObjects:(NSArray *)objects
                            andBlock:(ParseCompletionBlock)dependenciesBlock
{
    if (dependenciesBlock) dependenciesBlock(YES);
}

- (void)fetchEverythingWithCompletionBlock:(ParseCompletionBlock)block
{
    //Internet
    if (![self isDataAvailable] &&
        ![BLInternet doWeHaveInternet])
    {
        [PFObject returnToSenderWithResult:NO
                        andCompletionBlock:block];
        return;
    }
    
    //Fetching
    [self startBackgroundTask];
    __weak BLParseObject *weakSelf = self;
    [self startTimeoutOperationWithInterval:[self customTimeoutTime]
                                   andBlock:^
     {
         [BLParseObject returnToSenderWithResult:NO
                              andCompletionBlock:block];
         [weakSelf endBackgroundTask];
     }];
    
    void (^returnBlock) (BOOL) = ^(BOOL result)
    {
        [PFObject returnToSenderWithResult:result
                        andCompletionBlock:block];
        [weakSelf stopTimeoutOperation];
        [weakSelf endBackgroundTask];
    };
    
    void (^dependenciesBlock) (NSError *) = ^(NSError *parseError)
    {
        if (parseError) {
            ParseLog(@"%@",parseError);
            returnBlock(NO);
        } else {
            [weakSelf fetchDependenciesWithBlock:^(BOOL success)
            {
                returnBlock(success);
            }];
        }
    };
    
    if (self.isDataAvailable) {
        dependenciesBlock(nil);
    } else {
        [self fetchInBackgroundWithBlock:^(PFObject *object, NSError *error)
        {
            dependenciesBlock(error);
        }];
    }
}

- (void)fetchDependenciesWithBlock:(ParseCompletionBlock)dependenciesBlock
{
    if (dependenciesBlock) dependenciesBlock(YES);
}

@end


#pragma mark - Saving
@implementation BLParseObject (Saving)

+ (void)saveEverythingWithObjects:(NSArray *)objects
                         andBlock:(ParseCompletionBlock)block
{
    //Sanity
    if (objects.count == 0) {
        [self returnToSenderWithResult:YES
                    andCompletionBlock:block];
        return;
    }
    
    //Internet
    if (![BLInternet doWeHaveInternet]) {
        [self returnToSenderWithResult:NO
                    andCompletionBlock:block];
        return;
    }
    
    //Saving
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    NSTimer *timer = [self startTimeoutOperationWithInterval:[self customTimeoutTime]
                                                    andBlock:^
    {
        [BLParseObject returnToSenderWithResult:NO
                             andCompletionBlock:block];
        [BLParseObject endBackgroundTask:bgTaskId];
    }];
    
    void (^returnBlock) (BOOL) = ^(BOOL result)
    {
        [BLParseObject returnToSenderWithResult:result
                             andCompletionBlock:block];
        [BLParseObject stopTimeoutOperation:timer];
        [BLParseObject endBackgroundTask:bgTaskId];
    };
    
    [self saveDependenciesWithObjects:objects
                             andBlock:^(BOOL success)
    {
        if (!success) {
            returnBlock(NO);
        } else {
            [PFObject saveAllInBackground:objects
                                    block:^(BOOL succeeded, NSError *error)
            {
                if (error) ParseLog(@"%@",error);
                returnBlock(error == nil);
            }];
        }
    }];
}

+ (void)saveDependenciesWithObjects:(NSArray *)objects
                           andBlock:(ParseCompletionBlock)dependenciesBlock
{
    if (dependenciesBlock) dependenciesBlock(YES);
}

- (void)saveEverythingWithCompletionBlock:(ParseCompletionBlock)block
{
    //Sanity
    if (![self shouldSave]) {
        [PFObject returnToSenderWithResult:YES
                        andCompletionBlock:block];
        return;
    }
    
    //Internet
    if (![self hasBeenSavedToParse] &&
        ![BLInternet doWeHaveInternet])
    {
        [PFObject returnToSenderWithResult:NO
                        andCompletionBlock:block];
        return;
    }
    
    //Saving
    [self startBackgroundTask];
    __weak BLParseObject *weakSelf = self;
    [self startTimeoutOperationWithInterval:[self customTimeoutTime]
                                   andBlock:^
     {
         [BLParseObject returnToSenderWithResult:NO
                              andCompletionBlock:block];
         [weakSelf endBackgroundTask];
     }];
    
    void (^returnBlock) (BOOL) = ^(BOOL result)
    {
        [PFObject returnToSenderWithResult:result
                        andCompletionBlock:block];
        [weakSelf stopTimeoutOperation];
        [weakSelf endBackgroundTask];
    };
    
    [self saveDependenciesWithBlock:^(BOOL success)
     {
         if (!success)
         {
             returnBlock(NO);
         }
         else
         {
             if ([weakSelf hasBeenSavedToParse])
             { //Saving Locally
                 [self saveEventually];
                 returnBlock(YES);
             }
             else
             { //Saving to the server
                 [weakSelf saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                  {
                      if (error) ParseLog(@"%@",error);
                      returnBlock(error == nil);
                  }];
             }
         }
     }];
}


- (void)saveDependenciesWithBlock:(ParseCompletionBlock)dependenciesBlock
{
    if (dependenciesBlock) dependenciesBlock(YES);
}

@end


#pragma mark - Deleting
@implementation BLParseObject (Deleting)

+ (void)deleteEverythingWithObjects:(NSArray *)objects
                           andBlock:(ParseCompletionBlock)block
{
    //Sanity
    if (objects.count == 0) {
        [self returnToSenderWithResult:YES
                    andCompletionBlock:block];
        return;
    }
    
    //Deleting
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    NSTimer *timer = [self startTimeoutOperationWithInterval:[self customTimeoutTime]
                                                    andBlock:^
    {
        [BLParseObject returnToSenderWithResult:NO
                             andCompletionBlock:block];
        [BLParseObject endBackgroundTask:bgTaskId];
    }];
    
    void (^returnBlock) (BOOL) = ^(BOOL result)
    {
        [BLParseObject returnToSenderWithResult:result
                             andCompletionBlock:block];
        [BLParseObject stopTimeoutOperation:timer];
        [BLParseObject endBackgroundTask:bgTaskId];
    };
    
    [self deleteDependenciesWithObjects:objects
                               andBlock:^(BOOL success)
    {
        if (!success) {
            returnBlock(NO);
        } else {
            [PFObject deleteAllInBackground:objects
                                      block:^(BOOL succeeded, NSError *error)
            {
                ParseLog(@"%@",error);
                returnBlock(error == nil);
            }];
        }
    }];
}

+ (void)deleteDependenciesWithObjects:(NSArray *)objects
                             andBlock:(ParseCompletionBlock)dependenciesBlock
{
    if (dependenciesBlock) dependenciesBlock(YES);
}

- (void)deleteEverythingWithCompletionBlock:(ParseCompletionBlock)block
{
    [self startBackgroundTask];
    __weak BLParseObject *weakSelf = self;
    [self startTimeoutOperationWithInterval:[self customTimeoutTime]
                                   andBlock:^
     {
         [BLParseObject returnToSenderWithResult:NO
                              andCompletionBlock:block];
         [weakSelf endBackgroundTask];
     }];
    
    void (^returnBlock) (BOOL) = ^(BOOL result)
    {
        [BLParseObject returnToSenderWithResult:result
                             andCompletionBlock:block];
        [weakSelf stopTimeoutOperation];
        [weakSelf endBackgroundTask];
    };
    
    if ([self hasBeenSavedToParse])
    { //Deleting on the server
        [self deleteDependenciesWithBlock:^(BOOL success)
         {
             if (!success) {
                 returnBlock(NO);
             } else {
                 if ([BLInternet doWeHaveInternet]) {
                     [weakSelf deleteInBackground];
                 } else {
                     [weakSelf deleteEventually];
                 }
                 returnBlock(YES);
             }
         }];
    }
    else
    { //Not deleting
        returnBlock(YES);
    }
}

- (void)deleteDependenciesWithBlock:(ParseCompletionBlock)dependenciesBlock
{
    if (dependenciesBlock) dependenciesBlock(YES);
}

+ (void)deleteAllObjectsForUser:(BLParseUser *)user
                      withBlock:(ParseCompletionBlock)block
{
    //Sanity
    if (!user) {
        [self returnToSenderWithResult:NO
                    andCompletionBlock:block];
        return;
    }
    
    //Internet
    if (![BLInternet doWeHaveInternet]) {
        [self returnToSenderWithResult:NO
                    andCompletionBlock:block];
        return;
    }
    
    //Deleting
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    NSTimer *timer = [self startTimeoutOperationWithInterval:[self customTimeoutTime]
                                                    andBlock:^
    {
        [BLParseObject returnToSenderWithResult:NO
                             andCompletionBlock:block];
        [BLParseObject endBackgroundTask:bgTaskId];
    }];
    PFQuery *query = [self query];
    [query whereKey:@"user"
            equalTo:user];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (error) ParseLog(@"%@",error);
         if (objects.count > 0) {
             [PFObject deleteAllInBackground:objects
                                       block:^(BOOL succeeded, NSError *error)
              {
                  if (error) ParseLog(@"%@",error);
                  [BLParseObject returnToSenderWithResult:succeeded
                                       andCompletionBlock:block];
                  [BLParseObject stopTimeoutOperation:timer];
                  [BLParseObject endBackgroundTask:bgTaskId];
              }];
         } else {
             [BLParseObject returnToSenderWithResult:(error == nil)
                                  andCompletionBlock:block];
             [BLParseObject stopTimeoutOperation:timer];
             [BLParseObject endBackgroundTask:bgTaskId];
         }
     }];
}

@end
