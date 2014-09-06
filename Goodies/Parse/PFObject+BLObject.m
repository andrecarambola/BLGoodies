//
//  PFObject+BLObject.m
//  Parse
//
//  Created by André Abou Chami Campana on 06/07/14.
//  Copyright (c) 2014 BaffiLab. All rights reserved.
//

#import "PFObject+BLObject.h"
#import "BLQueuer.h"


@implementation PFObject (BLObject)


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


#pragma mark - Aux

+ (void)returnToSenderWithResult:(BOOL)result
              andCompletionBlock:(ParseCompletionBlock)completionBlock
{
    if (!completionBlock) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        completionBlock(result);
    });
}

+ (void)returnInBackgroundWithResult:(BOOL)result
                  andCompletionBlock:(ParseCompletionBlock)completionBlock
{
    if (!completionBlock) return;
    [BLQueuer enqueueSequentialOperationWithBlock:^
    {
        completionBlock(result);
    }];
}

@end



