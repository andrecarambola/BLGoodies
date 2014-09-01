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
- (void)startTimeoutOperationWithBlock:(TimeoutBlock)timeoutBlock;
- (void)operationDidTimeout:(NSTimer *)timer;
- (void)stopTimeoutOperation;

//Fetching
- (void)fetchEverythingWithCompletionBlock:(ParseCompletionBlock)block;
- (void)fetchDependenciesWithBlock:(ParseCompletionBlock)dependenciesBlock;

//Saving
- (void)saveEverythingWithCompletionBlock:(ParseCompletionBlock)block;
- (void)saveDependenciesWithBlock:(ParseCompletionBlock)dependenciesBlock;

//Deleting
- (void)deleteEverythingWithCompletionBlock:(ParseCompletionBlock)block;
- (void)deleteDependenciesWithBlock:(ParseCompletionBlock)dependenciesBlock;

@end


#pragma mark - Categories
@interface BLParseObject (Fetching)

+ (void)fetchEverythingWithObjects:(NSArray *)objects
                          andBlock:(ParseCompletionBlock)block;

@end


@interface BLParseObject (Saving)

+ (void)saveEverythingWithObjects:(NSArray *)objects
                         andBlock:(ParseCompletionBlock)block;

@end


@interface BLParseObject (Deleting)

+ (void)deleteEverythingWithObjects:(NSArray *)objects
                           andBlock:(ParseCompletionBlock)block;

@end