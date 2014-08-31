//
//  BLParseUser.h
//  Project
//
//  Created by André Abou Chami Campana on 31/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import <Parse/Parse.h>
#import "PFObject+BLObject.h"


#pragma mark - Consts
extern NSString * const BLParseUserDidLogOutNotification;


#pragma mark - Public Interface
@interface BLParseUser : PFUser <PFSubclassing>

//States
+ (BOOL)isLogged;
+ (BOOL)isFacebookUser;
+ (BOOL)isTwitterUser;

//Logging In
+ (void)logInWithUsername:(NSString *)username
                 password:(NSString *)password
              forCreation:(BOOL)forCreation
                withBlock:(ParseCompletionBlock)block;
+ (void)logInToFacebookWithBlock:(ParseCompletionBlock)block;
+ (void)logInToTwitterWithBlock:(ParseCompletionBlock)block;

//Managing the User
+ (void)requestPasswordResetWithEmail:(NSString *)email
                             andBlock:(ParseCompletionBlock)block;
- (void)requestPasswordResetWithBlock:(ParseCompletionBlock)block;
#warning check email validation

//Logging Out
+ (void)customLogout;

//Setup
@property (nonatomic, getter = shouldClearCaches) BOOL clearCaches;

@end
