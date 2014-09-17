//
//  BLParseObject.h
//  Project
//
//  Created by André Abou Chami Campana on 31/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import <Parse/Parse.h>
#import "PFObject+BLObject.h"
#import "BLInternet.h"


@class BLParseUser;


#pragma mark - Public Interface
@interface BLParseObject : PFObject <PFSubclassing>

//Creating Objects
+ (instancetype)customObject;
+ (PFQuery *)customQuery;

//Setup
- (void)setup;

//Background
- (void)startBackgroundTask;
- (void)endBackgroundTask;

//App States
@property (nonatomic) BOOL handlesAppStates;
- (void)handleAppStateChange:(BOOL)toTheBackground;

//Internet
@property (nonatomic) BOOL handlesInternet;
- (void)handleInternetStateChange:(NetworkStatus)networkStatus;

//Timeout
+ (NSTimeInterval)customTimeoutTime;
- (NSTimeInterval)customTimeoutTime;
- (void)startTimeoutOperationWithBlock:(TimeoutBlock)timeoutBlock;
- (void)startTimeoutOperationWithInterval:(NSTimeInterval)timeInterval
                                 andBlock:(TimeoutBlock)timeoutBlock;
- (void)operationDidTimeout:(NSTimer *)timer;
- (void)stopTimeoutOperation;

@end


#pragma mark - Categories
@interface BLParseObject (Fetching)

+ (void)fetchEverythingWithObjects:(NSArray *)objects
                          andBlock:(ParseCompletionBlock)block;
+ (void)fetchDependenciesWithObjects:(NSArray *)objects
                            andBlock:(ParseCompletionBlock)dependenciesBlock;
- (void)fetchEverythingWithCompletionBlock:(ParseCompletionBlock)block;
- (void)fetchDependenciesWithBlock:(ParseCompletionBlock)dependenciesBlock;

@end


@interface BLParseObject (Saving)

+ (void)saveEverythingWithObjects:(NSArray *)objects
                         andBlock:(ParseCompletionBlock)block;
+ (void)saveDependenciesWithObjects:(NSArray *)objects
                           andBlock:(ParseCompletionBlock)dependenciesBlock;
- (void)saveEverythingWithCompletionBlock:(ParseCompletionBlock)block;
- (void)saveDependenciesWithBlock:(ParseCompletionBlock)dependenciesBlock;

@end


@interface BLParseObject (Deleting)

+ (void)deleteEverythingWithObjects:(NSArray *)objects
                           andBlock:(ParseCompletionBlock)block;
+ (void)deleteDependenciesWithObjects:(NSArray *)objects
                             andBlock:(ParseCompletionBlock)dependenciesBlock;
- (void)deleteEverythingWithCompletionBlock:(ParseCompletionBlock)block;
- (void)deleteDependenciesWithBlock:(ParseCompletionBlock)dependenciesBlock;
+ (void)deleteAllObjectsForUser:(BLParseUser *)user
                      withBlock:(ParseCompletionBlock)block;

@end