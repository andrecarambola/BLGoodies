//
//  PFObject+BLObject.h
//  Parse
//
//  Created by André Abou Chami Campana on 06/07/14.
//  Copyright (c) 2014 BaffiLab. All rights reserved.
//

#import <Parse/Parse.h>


typedef void (^ParseCompletionBlock) (BOOL success);


@interface PFObject (BLObject)

//Creating Objects
+ (instancetype)customObject;
+ (PFQuery *)customQuery;

//States
- (BOOL)hasBeenSavedToParse;
- (BOOL)shouldSave;

//Saving
+ (void)saveEverythingWithObjects:(NSArray *)objects
                         andBlock:(ParseCompletionBlock)block;
- (void)saveEverythingWithCompletionBlock:(ParseCompletionBlock)block;

//Deleting
+ (void)deleteEverythingWithObjects:(NSArray *)objects
                           andBlock:(ParseCompletionBlock)block;
- (void)deleteEverythingWithCompletionBlock:(ParseCompletionBlock)block;

//Aux
+ (void)returnToSenderWithResult:(BOOL)result
              andCompletionBlock:(ParseCompletionBlock)completionBlock;

@end
