//
//  PFObject+BLObject.h
//  Parse
//
//  Created by André Abou Chami Campana on 06/07/14.
//  Copyright (c) 2014 BaffiLab. All rights reserved.
//

#import <Parse/Parse.h>
#import "NSObject+Goodies.h"


#pragma mark - Type Defs
typedef void (^ParseCompletionBlock) (BOOL success);


#pragma mark - PUBLIC INTERFACES
#pragma mark BLObject
@interface PFObject (BLObject)

//States
- (BOOL)hasBeenSavedToParse;
- (BOOL)shouldSave;

//Aux
+ (void)returnToSenderWithResult:(BOOL)result
              andCompletionBlock:(ParseCompletionBlock)completionBlock;
+ (void)returnInBackgroundWithResult:(BOOL)result
                  andCompletionBlock:(ParseCompletionBlock)completionBlock;

@end
