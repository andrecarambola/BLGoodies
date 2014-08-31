//
//  PFObject+BLObject.m
//  Parse
//
//  Created by André Abou Chami Campana on 06/07/14.
//  Copyright (c) 2014 BaffiLab. All rights reserved.
//

#import "PFObject+BLObject.h"
#import "BLLogger.h"
#import "Reachability.h"


@implementation PFObject (BLObject)

#pragma mark - Creating Objects

+ (instancetype)customObject
{
    return nil;
}

+ (PFQuery *)customQuery
{
    return nil;
}


#pragma mark - States

- (BOOL)hasBeenSavedToParse
{
    return (self.objectId.length > 0);
}

- (BOOL)shouldSave
{
    if (!self.hasBeenSavedToParse) return YES;
    return self.isDirty;
}


#pragma mark - Saving

+ (void)saveEverythingWithObjects:(NSArray *)objects
                         andBlock:(ParseCompletionBlock)block
{
    //Sanity
    if (objects.count == 0) {
        [self returnToSenderWithResult:YES
                    andCompletionBlock:block];
        return;
    }
    
    //
}

- (void)saveEverythingWithCompletionBlock:(ParseCompletionBlock)block;

#pragma mark - Deleting
+ (void)deleteEverythingWithObjects:(NSArray *)objects
                           andBlock:(ParseCompletionBlock)block;
- (void)deleteEverythingWithCompletionBlock:(ParseCompletionBlock)block;

#pragma mark - Aux
+ (void)returnToSenderWithResult:(BOOL)result
              andCompletionBlock:(ParseCompletionBlock)completionBlock;

@end
