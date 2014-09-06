//
//  BLDatabase.m
//  Goodies
//
//  Created by André Abou Chami Campana on 29/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLDatabase.h"
#import <CoreData/CoreData.h>
#import "BLLogger.h"


@interface BLDatabase ()

//Setup
@property (nonatomic, strong) NSString *storageFileName;
@property (nonatomic) int backgroundOperationCount;
- (BOOL)isRunningBackgroundOperation;
- (void)willStartBackgroundOperation;
- (void)didFinishBackgroundOperation;

//Core Data Stack
@property (nonatomic, strong) NSManagedObjectContext *masterManagedObjectContext;
@property (nonatomic, strong) NSManagedObjectContext *mainManagedObjectContext;
@property (nonatomic, strong) NSManagedObjectContext *backgroundManagedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

//Notifications
- (void)handleAppWillTerminateNotification:(NSNotification *)notification;

@end


@implementation BLDatabase

#pragma mark - Initializer

+ (instancetype)databaseWithObjectModelFileName:(NSString *)modelFileName
                               andStoreFileName:(NSString *)storeFileName
{
    NSAssert(modelFileName.length > 0, @"Core Data Model file name shouldn't be nil");
    NSAssert(storeFileName.length > 0, @"Core Data Store file name shouldn't be nil");
    if (modelFileName.length == 0 || storeFileName.length == 0) return nil;
    BLDatabase *result = [[BLDatabase alloc] init];
    [result setStorageFileName:storeFileName];
    
    //Core Data Stack
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:modelFileName
                                              withExtension:@"momd"];
    result.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSURL *storeURL = [[result databaseDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite",storeFileName]];
    
    NSError *error = nil;
    result.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:result.managedObjectModel];
    if (![result.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                         configuration:nil
                                                                   URL:storeURL
                                                               options:@{NSMigratePersistentStoresAutomaticallyOption:@YES,
                                                                         NSInferMappingModelAutomaticallyOption:@YES}
                                                                 error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
#ifdef DEBUG
        CoreDataLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
#endif
    }
    
    return result;
}


#pragma mark - Setup

- (void)setup
{
    [super setup];
    
    _backgroundOperationCount = 0;
    [self setHandlesAppStates:YES];
    [self setHandlesMemory:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAppWillTerminateNotification:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:[UIApplication sharedApplication]];
}

- (BOOL)isRunningBackgroundOperation
{
    return self.backgroundOperationCount > 0;
}

- (void)willStartBackgroundOperation
{
    ++self.backgroundOperationCount;
}

- (void)didFinishBackgroundOperation
{
    --self.backgroundOperationCount;
    if (self.backgroundOperationCount < 0) self.backgroundOperationCount = 0;
    if (self.backgroundOperationCount == 0) {
        __weak BLDatabase *weakSelf = self;
        [self saveInBackground:YES
                     withBlock:^(BOOL success)
        {
            [weakSelf setBackgroundManagedObjectContext:nil];
        }];
    }
}


#pragma mark - Managed Object Contexts

- (NSManagedObjectContext *)mainMOC
{
    return self.mainManagedObjectContext;
}

- (NSManagedObjectContext *)backgroundMOC
{
    return self.backgroundManagedObjectContext;
}


#pragma mark - Running Operations

- (void)executeOperation:(BLDatabaseOperationBlock)operationBlock
            inBackground:(BOOL)inBackground
     withCompletionBlock:(BLDatabaseCompletionBlock)completionBlock
{
    NSAssert(operationBlock, @"Noop");
    if (inBackground) [self willStartBackgroundOperation];
    [self startBackgroundTask];
    __weak BLDatabase *weakSelf = self;
    NSManagedObjectContext *moc = (inBackground) ? self.backgroundManagedObjectContext : self.mainManagedObjectContext;
    [moc performBlock:^
    {
        BOOL result = operationBlock();
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(result);
            });
        }
        if (inBackground) [weakSelf didFinishBackgroundOperation];
        [weakSelf endBackgroundTask];
    }];
}


#pragma mark - Saving

- (void)saveInBackground:(BOOL)inBackground
               withBlock:(BLDatabaseCompletionBlock)completionBlock
{
    NSManagedObjectContext *moc;
    if (inBackground) {
        if (_backgroundManagedObjectContext) {
            moc = self.backgroundManagedObjectContext;
            [self startBackgroundTask];
            __weak BLDatabase *weakSelf = self;
            [moc performBlock:^
            {
                NSError *error;
                BOOL result = [moc save:&error];
                if (!result && error) CoreDataLog(@"%@",error);
                if (completionBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionBlock(result);
                    });
                }
                [weakSelf endBackgroundTask];
            }];
        } else {
            if (completionBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(YES);
                });
            }
        }
    } else {
        moc = self.mainManagedObjectContext;
        [self executeOperation:^
         {
             NSError *error;
             BOOL result = [moc save:&error];
             if (!result && error) CoreDataLog(@"%@",error);
             return result;
         }
                  inBackground:NO
           withCompletionBlock:completionBlock];
    }
}


#pragma mark - Aux

+ (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)databaseDirectory
{
    NSURL *result = [[[BLDatabase applicationDocumentsDirectory] URLByAppendingPathComponent:@"BLDatabase"] URLByAppendingPathComponent:self.storageFileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[result path]]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtURL:result
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:&error];
        if (error) FileLog(@"%@",error);
    }
    return result;
}

- (NSURL *)filesDirectory
{
    NSURL *result = [self.databaseDirectory URLByAppendingPathComponent:@"Files"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[result path]]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtURL:result
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:&error];
        if (error) FileLog(@"%@",error);
    }
    return result;
}


#pragma mark - Core Data Stack

- (NSManagedObjectContext *)masterManagedObjectContext
{
    if (_masterManagedObjectContext) return _masterManagedObjectContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _masterManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_masterManagedObjectContext setPersistentStoreCoordinator:coordinator];
        [_masterManagedObjectContext setMergePolicy:NSOverwriteMergePolicy];
    }
    return _masterManagedObjectContext;
}

- (NSManagedObjectContext *)mainManagedObjectContext
{
    if (_mainManagedObjectContext != nil) return _mainManagedObjectContext;
    
    _mainManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _mainManagedObjectContext.parentContext = self.masterManagedObjectContext;
    return _mainManagedObjectContext;
}

- (NSManagedObjectContext *)backgroundManagedObjectContext
{
    if (_backgroundManagedObjectContext != nil) return _backgroundManagedObjectContext;
    
    _backgroundManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    _backgroundManagedObjectContext.parentContext = self.mainManagedObjectContext;
    return _backgroundManagedObjectContext;
}


#pragma mark - Notifications

- (void)handleAppStateChange:(BOOL)toTheBackground
{
    [super handleAppStateChange:toTheBackground];
    if (toTheBackground && !self.isRunningBackgroundOperation && _backgroundManagedObjectContext) {
        [self setBackgroundManagedObjectContext:nil];
    }
}

- (void)handleMemoryWarningNotification:(NSNotification *)notification
{
    [super handleMemoryWarningNotification:notification];
    if (!self.isRunningBackgroundOperation && _backgroundManagedObjectContext) {
        [self setBackgroundManagedObjectContext:nil];
    }
}

- (void)handleAppWillTerminateNotification:(NSNotification *)notification
{
    UIBackgroundTaskIdentifier bgTaskId = [BLDatabase startBackgroundTask];
    __weak BLDatabase *weakSelf = self;
    [self saveInBackground:NO
                 withBlock:^(BOOL success)
    {
        if (success) {
            [[weakSelf masterManagedObjectContext] performBlock:^
             {
                 NSError *error;
                 BOOL result = [[weakSelf masterManagedObjectContext] save:&error];
                 if (!result && error) CoreDataLog(@"%@",error);
                 [BLDatabase endBackgroundTask:bgTaskId];
             }];
        } else {
            [BLDatabase endBackgroundTask:bgTaskId];
        }
    }];
}

@end
