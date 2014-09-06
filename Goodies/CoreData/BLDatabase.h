//
//  BLDatabase.h
//  Goodies
//
//  Created by André Abou Chami Campana on 29/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLObject.h"


typedef void (^BLDatabaseCompletionBlock) (BOOL success);
typedef BOOL (^BLDatabaseOperationBlock) ();


@interface BLDatabase : BLObject

//Initializer
+ (instancetype)databaseWithObjectModelFileName:(NSString *)modelFileName
                               andStoreFileName:(NSString *)storeFileName;

//Managed Object Contexts
@property (nonatomic, readonly) NSManagedObjectContext *mainMOC;
@property (nonatomic, readonly) NSManagedObjectContext *backgroundMOC;

//Running Operations
- (void)executeOperation:(BLDatabaseOperationBlock)operationBlock
            inBackground:(BOOL)inBackground
     withCompletionBlock:(BLDatabaseCompletionBlock)completionBlock;

//Saving
- (void)saveInBackground:(BOOL)inBackground
               withBlock:(BLDatabaseCompletionBlock)completionBlock;

//Aux
+ (NSURL *)applicationDocumentsDirectory;
- (NSURL *)databaseDirectory;
- (NSURL *)filesDirectory;

@end
