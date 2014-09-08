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


#pragma mark - Globals
static NSMutableArray *fetchingObjects;
static NSMutableArray *savingObjects;
static NSMutableArray *deletingObjects;


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


#pragma mark - Private Categories
@interface BLParseObject (PrivateFetching)

+ (NSMutableArray *)objectsToFetch;
+ (void)setObjectsToFetch:(NSMutableArray *)array;

+ (void)processObjectsToFetchWithBlock:(ParseCompletionBlock)overallCompletionBlock;
- (void)fetchEverythingWithCompletionBlock:(ParseCompletionBlock)block
                        returnToMainThread:(BOOL)shouldReturnToMainThread;

@end

@interface BLParseObject (PrivateSaving)

+ (NSMutableArray *)objectsToSave;
+ (void)setObjectsToSave:(NSMutableArray *)array;

+ (void)processObjectsToSaveWithBlock:(ParseCompletionBlock)overallCompletionBlock;
- (void)saveEverythingWithCompletionBlock:(ParseCompletionBlock)block
                       returnToMainThread:(BOOL)shouldReturnToMainThread;

@end

@interface BLParseObject (PrivateDeleting)

+ (NSMutableArray *)objectsToDelete;
+ (void)setObjectsToDelete:(NSMutableArray *)array;

+ (void)processObjectsToDeleteWithBlock:(ParseCompletionBlock)overallCompletionBlock;
- (void)deleteEverythingWithCompletionBlock:(ParseCompletionBlock)block
                         returnToMainThread:(BOOL)shouldReturnToMainThread;

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

@synthesize timeoutTimer = _timeoutTimer;

- (void)startTimeoutOperationWithBlock:(TimeoutBlock)timeoutBlock
{
    if (self.timeoutTimer) [self stopTimeoutOperation];
    NSTimer *timer = [BLObject startTimeoutOperationWithTarget:self
                                                        action:@selector(operationDidTimeout:)
                                                      interval:[BLObject defaultTimeoutTime]
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


#pragma mark - Fetching

- (void)fetchEverythingWithCompletionBlock:(ParseCompletionBlock)block
{
    [self startBackgroundTask];
    __weak BLParseObject *weakSelf = self;
    [self startTimeoutOperationWithBlock:^
    {
        [BLParseObject returnInBackgroundWithResult:NO
                                 andCompletionBlock:block];
        [weakSelf endBackgroundTask];
    }];
    [self fetchEverythingWithCompletionBlock:^(BOOL success)
     {
         if (block) block(success);
         [weakSelf endBackgroundTask];
     }
                          returnToMainThread:YES];
}

- (void)fetchDependenciesWithBlock:(ParseCompletionBlock)dependenciesBlock
{
    if (dependenciesBlock) dependenciesBlock(YES);
}


#pragma mark - Saving

- (void)saveEverythingWithCompletionBlock:(ParseCompletionBlock)block
{
    [self startBackgroundTask];
    __weak BLParseObject *weakSelf = self;
    [self startTimeoutOperationWithBlock:^
    {
        [BLParseObject returnInBackgroundWithResult:NO
                                 andCompletionBlock:block];
        [weakSelf endBackgroundTask];
    }];
    [self saveEverythingWithCompletionBlock:^(BOOL success)
     {
         if (block) block(success);
         [weakSelf endBackgroundTask];
     }
                         returnToMainThread:YES];
}


- (void)saveDependenciesWithBlock:(ParseCompletionBlock)dependenciesBlock
{
    if (dependenciesBlock) dependenciesBlock(YES);
}


#pragma mark - Deleting

- (void)deleteEverythingWithCompletionBlock:(ParseCompletionBlock)block
{
    [self startBackgroundTask];
    __weak BLParseObject *weakSelf = self;
    [self startTimeoutOperationWithBlock:^
    {
        [BLParseObject returnInBackgroundWithResult:NO
                                 andCompletionBlock:block];
        [weakSelf endBackgroundTask];
    }];
    [self deleteEverythingWithCompletionBlock:^(BOOL success)
     {
         if (block) block(success);
         [weakSelf endBackgroundTask];
     }
                           returnToMainThread:YES];
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
        [self returnInBackgroundWithResult:NO
                        andCompletionBlock:block];
        return;
    }
    
    //Internet
    if (![BLInternet doWeHaveInternet]) {
        [self returnInBackgroundWithResult:NO
                        andCompletionBlock:block];
        return;
    }
    
    //Deleting
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    NSTimer *timer = [self startTimeoutOperationWithBlock:^
    {
        [BLParseObject returnInBackgroundWithResult:NO
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
    
    //Saving
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    [self setObjectsToFetch:[NSMutableArray arrayWithArray:objects]];
    [BLQueuer enqueueSequentialOperationWithBlock:^
     {
         [BLParseObject processObjectsToFetchWithBlock:^(BOOL success)
          {
              [BLParseObject returnToSenderWithResult:success
                                   andCompletionBlock:block];
              [BLParseObject endBackgroundTask:bgTaskId];
          }];
     }];
}

@end


@implementation BLParseObject (PrivateFetching)

+ (NSMutableArray *)objectsToFetch
{
    @synchronized(self)
    {
        if (!fetchingObjects) fetchingObjects = [NSMutableArray array];
        return fetchingObjects;
    }
}

+ (void)setObjectsToFetch:(NSMutableArray *)array
{
    @synchronized(self)
    {
        if (array.count == 0) {
            fetchingObjects = nil;
        } else {
            fetchingObjects = array;
        }
    }
}

+ (void)processObjectsToFetchWithBlock:(ParseCompletionBlock)overallCompletionBlock
{
    //Returning
    NSMutableArray *objectsToFetch = [self objectsToFetch];
    if (objectsToFetch.count == 0) {
        [BLParseObject setObjectsToFetch:nil];
        [BLParseObject returnToSenderWithResult:YES
                             andCompletionBlock:overallCompletionBlock];
        return;
    }
    
    //Process fetch
    BLParseObject *object = [objectsToFetch firstObject];
    [objectsToFetch removeObjectAtIndex:0];
    [BLParseObject setObjectsToFetch:objectsToFetch];
    [object startTimeoutOperationWithBlock:^
    {
        [BLParseObject setObjectsToFetch:nil];
        [BLParseObject returnToSenderWithResult:NO
                             andCompletionBlock:overallCompletionBlock];
    }];
    [object fetchEverythingWithCompletionBlock:^(BOOL success)
     {
         if (!success) {
             [BLParseObject setObjectsToFetch:nil];
             [BLParseObject returnToSenderWithResult:NO
                                  andCompletionBlock:overallCompletionBlock];
         } else {
             [objectsToFetch removeObject:object];
             [BLParseObject setObjectsToFetch:objectsToFetch];
             [BLParseObject processObjectsToFetchWithBlock:overallCompletionBlock];
         }
         [object stopTimeoutOperation];
     }
                            returnToMainThread:NO];
}

- (void)fetchEverythingWithCompletionBlock:(ParseCompletionBlock)block
                        returnToMainThread:(BOOL)shouldReturnToMainThread
{
    //Internet
    if (![self isDataAvailable] &&
        ![BLInternet doWeHaveInternet])
    {
        if (!shouldReturnToMainThread) {
            [PFObject returnInBackgroundWithResult:NO
                                andCompletionBlock:block];
        } else {
            [PFObject returnToSenderWithResult:NO
                            andCompletionBlock:block];
        }
        return;
    }
    
    //Fetching
    __weak BLParseObject *weakSelf = self;
    [self fetchDependenciesWithBlock:^(BOOL success)
     {
         if (!success) {
             if (!shouldReturnToMainThread) {
                 [PFObject returnInBackgroundWithResult:NO
                                     andCompletionBlock:block];
             } else {
                 [PFObject returnToSenderWithResult:NO
                                 andCompletionBlock:block];
             }
         } else {
             if ([weakSelf isDataAvailable]) {
                 if (!shouldReturnToMainThread) {
                     [PFObject returnInBackgroundWithResult:YES
                                         andCompletionBlock:block];
                 } else {
                     [PFObject returnToSenderWithResult:YES
                                     andCompletionBlock:block];
                 }
             } else {
                 [weakSelf fetchInBackgroundWithBlock:^(PFObject *object, NSError *error)
                  {
                      if (error) ParseLog(@"%@",error);
                      if (!shouldReturnToMainThread) {
                          [PFObject returnInBackgroundWithResult:(error == nil)
                                              andCompletionBlock:block];
                      } else {
                          [PFObject returnToSenderWithResult:(error == nil)
                                          andCompletionBlock:block];
                      }
                  }];
             }
         }
     }];
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
    
    //Saving
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    [self setObjectsToSave:[NSMutableArray arrayWithArray:objects]];
    [BLQueuer enqueueSequentialOperationWithBlock:^
     {
         [BLParseObject processObjectsToSaveWithBlock:^(BOOL success)
          {
              [BLParseObject returnToSenderWithResult:success
                                   andCompletionBlock:block];
              [BLParseObject endBackgroundTask:bgTaskId];
          }];
     }];
}

@end


@implementation BLParseObject (PrivateSaving)

+ (NSMutableArray *)objectsToSave
{
    @synchronized(self)
    {
        if (!savingObjects) savingObjects = [NSMutableArray array];
        return savingObjects;
    }
}

+ (void)setObjectsToSave:(NSMutableArray *)array
{
    @synchronized(self)
    {
        if (array.count == 0) {
            savingObjects = nil;
        } else {
            savingObjects = array;
        }
    }
}

+ (void)processObjectsToSaveWithBlock:(ParseCompletionBlock)overallCompletionBlock
{
    //Returning
    NSMutableArray *objectsToSave = [self objectsToSave];
    if (objectsToSave.count == 0) {
        [BLParseObject setObjectsToSave:nil];
        [BLParseObject returnToSenderWithResult:YES
                             andCompletionBlock:overallCompletionBlock];
        return;
    }
    
    //Process save
    BLParseObject *object = [objectsToSave firstObject];
    [object startTimeoutOperationWithBlock:^
    {
        [BLParseObject setObjectsToSave:nil];
        [BLParseObject returnToSenderWithResult:NO
                             andCompletionBlock:overallCompletionBlock];
    }];
    [object saveEverythingWithCompletionBlock:^(BOOL success)
     {
         if (!success) {
             [BLParseObject setObjectsToSave:nil];
             [BLParseObject returnToSenderWithResult:NO
                                  andCompletionBlock:overallCompletionBlock];
         } else {
             [objectsToSave removeObject:object];
             [BLParseObject setObjectsToSave:objectsToSave];
             [BLParseObject processObjectsToSaveWithBlock:overallCompletionBlock];
         }
         [object stopTimeoutOperation];
     }
                           returnToMainThread:NO];
}

- (void)saveEverythingWithCompletionBlock:(ParseCompletionBlock)block
                       returnToMainThread:(BOOL)shouldReturnToMainThread
{
    //Sanity
    if (![self shouldSave]) {
        if (!shouldReturnToMainThread) {
            [PFObject returnInBackgroundWithResult:YES
                                andCompletionBlock:block];
        } else {
            [PFObject returnToSenderWithResult:YES
                            andCompletionBlock:block];
        }
        return;
    }
    
    //Internet
    if (![self hasBeenSavedToParse] &&
        ![BLInternet doWeHaveInternet])
    {
        if (!shouldReturnToMainThread) {
            [PFObject returnInBackgroundWithResult:NO
                                andCompletionBlock:block];
        } else {
            [PFObject returnToSenderWithResult:NO
                            andCompletionBlock:block];
        }
        return;
    }
    
    __weak BLParseObject *weakSelf = self;
    [self saveDependenciesWithBlock:^(BOOL success)
    {
        if (!success)
        {
            if (!shouldReturnToMainThread) {
                [PFObject returnInBackgroundWithResult:NO
                                    andCompletionBlock:block];
            } else {
                [PFObject returnToSenderWithResult:NO
                                andCompletionBlock:block];
            }
        }
        else
        {
            if ([weakSelf hasBeenSavedToParse])
            { //Saving Locally
                [self saveEventually];
                if (!shouldReturnToMainThread) {
                    [PFObject returnInBackgroundWithResult:YES
                                        andCompletionBlock:block];
                } else {
                    [PFObject returnToSenderWithResult:YES
                                    andCompletionBlock:block];
                }
            }
            else
            { //Saving to the server
                [weakSelf saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                 {
                     if (error) ParseLog(@"%@",error);
                     if (!shouldReturnToMainThread) {
                         [PFObject returnInBackgroundWithResult:succeeded
                                             andCompletionBlock:block];
                     } else {
                         [PFObject returnToSenderWithResult:succeeded
                                         andCompletionBlock:block];
                     }
                 }];
            }
        }
    }];
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
    
    //Saving
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    [self setObjectsToDelete:[NSMutableArray arrayWithArray:objects]];
    [BLQueuer enqueueSequentialOperationWithBlock:^
     {
         [BLParseObject processObjectsToDeleteWithBlock:^(BOOL success)
          {
              [BLParseObject returnToSenderWithResult:success
                                   andCompletionBlock:block];
              [BLParseObject endBackgroundTask:bgTaskId];
          }];
     }];
}

@end


@implementation BLParseObject (PrivateDeleting)

+ (NSMutableArray *)objectsToDelete
{
    @synchronized(self)
    {
        if (!deletingObjects) deletingObjects = [NSMutableArray array];
        return deletingObjects;
    }
}

+ (void)setObjectsToDelete:(NSMutableArray *)array
{
    @synchronized(self)
    {
        if (array.count == 0) {
            deletingObjects = nil;
        } else {
            deletingObjects = array;
        }
    }
}

+ (void)processObjectsToDeleteWithBlock:(ParseCompletionBlock)overallCompletionBlock
{
    //Returning
    NSMutableArray *objectsToDelete = [self objectsToDelete];
    if (objectsToDelete.count == 0) {
        [BLParseObject setObjectsToDelete:nil];
        [BLParseObject returnToSenderWithResult:YES
                             andCompletionBlock:overallCompletionBlock];
        return;
    }
    
    //Process delete
    BLParseObject *object = [objectsToDelete firstObject];
    [object startTimeoutOperationWithBlock:^
    {
        [BLParseObject setObjectsToDelete:nil];
        [BLParseObject returnToSenderWithResult:NO
                             andCompletionBlock:overallCompletionBlock];
    }];
    [object deleteEverythingWithCompletionBlock:^(BOOL success)
     {
         if (!success) {
             [BLParseObject setObjectsToDelete:nil];
             [BLParseObject returnToSenderWithResult:NO
                                  andCompletionBlock:overallCompletionBlock];
         } else {
             [objectsToDelete removeObject:object];
             [BLParseObject setObjectsToDelete:objectsToDelete];
             [BLParseObject processObjectsToDeleteWithBlock:overallCompletionBlock];
         }
         [object stopTimeoutOperation];
     }
                             returnToMainThread:NO];
}

- (void)deleteEverythingWithCompletionBlock:(ParseCompletionBlock)block
                         returnToMainThread:(BOOL)shouldReturnToMainThread
{
    if ([self hasBeenSavedToParse])
    { //Deleting on the server
        __weak BLParseObject *weakSelf = self;
        [self deleteDependenciesWithBlock:^(BOOL success)
         {
             if (!success) {
                 if (!shouldReturnToMainThread) {
                     [PFObject returnInBackgroundWithResult:NO
                                         andCompletionBlock:block];
                 } else {
                     [PFObject returnToSenderWithResult:NO
                                     andCompletionBlock:block];
                 }
             } else {
                 if ([BLInternet doWeHaveInternet]) {
                     [weakSelf deleteInBackground];
                 } else {
                     [weakSelf deleteEventually];
                 }
                 if (!shouldReturnToMainThread) {
                     [PFObject returnInBackgroundWithResult:YES
                                         andCompletionBlock:block];
                 } else {
                     [PFObject returnToSenderWithResult:YES
                                     andCompletionBlock:block];
                 }
             }
         }];
    }
    else
    { //Not deleting
        if (!shouldReturnToMainThread) {
            [PFObject returnInBackgroundWithResult:YES
                                andCompletionBlock:block];
        } else {
            [PFObject returnToSenderWithResult:YES
                            andCompletionBlock:block];
        }
    }
}

@end
