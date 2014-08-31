//
//  BLParseUser.m
//  Project
//
//  Created by André Abou Chami Campana on 31/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLParseUser.h"
#import <Parse/PFObject+Subclass.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import "BLInternet.h"
#import "BLLogger.h"
#import "NSString+BLText.h"
#import "BLDefines.h"
#import "PFCloud+BLCloud.h"
#import <FacebookSDK/FacebookSDK.h>


#pragma mark - Consts
NSString * const BLParseUserDidLogOutNotification = @"BLParseUserDidLogOutNotification";


#pragma mark - Private Interface
@interface BLParseUser ()

//Setup
- (void)setup;
- (void)initialSetupWithBlock:(ParseCompletionBlock)setupBlock;
- (void)loginSetupWithBlock:(ParseCompletionBlock)loginBlock;

//Background
@property (nonatomic) UIBackgroundTaskIdentifier bgTaskId;
- (void)startBackgroundTask;
- (void)endBackgroundTask;

//Timeout
@property (nonatomic, weak) NSTimer *timeoutTimer;
- (void)startTimeoutOperationWithBlock:(TimeoutBlock)timeoutBlock;
- (void)operationDidTimeout:(NSTimer *)timer;
- (void)stopTimeoutOperation;

@end


#pragma mark - Implementation
@implementation BLParseUser

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - States

+ (BOOL)isLogged
{
    return ([PFUser currentUser] != nil);
}

+ (BOOL)isFacebookUser
{
    if (![self isLogged]) return NO;
    return [PFFacebookUtils isLinkedWithUser:[self currentUser]];
}

+ (BOOL)isTwitterUser
{
    if (![self isLogged]) return NO;
    return [PFTwitterUtils isLinkedWithUser:[self currentUser]];
}


#pragma mark - Setup

+ (void)load
{
    [super load];
    [self registerSubclass];
}

@synthesize bgTaskId = _bgTaskId;
@dynamic clearCaches;

- (void)setup
{
    _bgTaskId = UIBackgroundTaskInvalid;
}

- (void)initialSetupWithBlock:(ParseCompletionBlock)setupBlock
{
    //Internet
    if (![BLInternet doWeHaveInternet]) {
        [BLParseUser returnToSenderWithResult:NO
                           andCompletionBlock:setupBlock];
        return;
    }
    
    //Initial Setup
    [self startBackgroundTask];
    [self startTimeoutOperationWithBlock:^
    {
        [BLParseUser returnToSenderWithResult:NO
                           andCompletionBlock:setupBlock];
        [[BLParseUser currentUser] stopTimeoutOperation];
    }];
    [PFCloud registerNewClientUserWithBlock:^(BOOL success)
    {
        if (!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:appName
                                            message:NSLocalizedStringFromTable(@"BLNoLoginAlert", @"BLGoodies", @"Alert to be displayed if there was an error when logging in to Parse")
                                           delegate:nil
                                  cancelButtonTitle:@"Ok"
                                  otherButtonTitles:nil] show];
            });
            [BLParseUser returnToSenderWithResult:NO
                               andCompletionBlock:^(BOOL success)
            {
                setupBlock(NO);
                [BLParseUser customLogout];
            }];
        } else {
            BLParseUser *newUser = [BLParseUser currentUser];
            [newUser setTerms:NO];
            [newUser setClearCaches:NO];
            [newUser setFacebookWrite:NO];
            [newUser saveEventually];
            [BLParseUser returnToSenderWithResult:YES
                               andCompletionBlock:setupBlock];
        }
        [[BLParseUser currentUser] stopTimeoutOperation];
        [[BLParseUser currentUser] endBackgroundTask];
    }];
}

- (void)loginSetupWithBlock:(ParseCompletionBlock)loginBlock
{
    //Internet
    if (![BLInternet doWeHaveInternet]) {
        [BLParseUser returnToSenderWithResult:NO
                           andCompletionBlock:loginBlock];
        return;
    }
    
    //Refreshing User
    [self startBackgroundTask];
    [self startTimeoutOperationWithBlock:^
    {
        [BLParseUser returnToSenderWithResult:NO
                           andCompletionBlock:loginBlock];
        [[BLParseUser currentUser] endBackgroundTask];
    }];
    [self refreshInBackgroundWithBlock:^(PFObject *object, NSError *error)
    {
        if (error) ParseLog(@"%@",error);
        if ([[BLParseUser currentUser] shouldClearCaches]) {
            [PFQuery clearAllCachedResults];
            [[BLParseUser currentUser] setClearCaches:NO];
            [[BLParseUser currentUser] saveEventually];
        }
        if ([BLParseUser isFacebookUser]) {
            [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error)
            {
                if (error) {
                    FacebookLog(@"%@",error);
                } else {
                    // result is a dictionary with the user's Facebook data
                    NSDictionary *userData = (NSDictionary *)result;
                    NSString *email = userData[@"email"];
                    BLParseUser *user = [BLParseUser currentUser];
                    if (![user.email isEqualToString:email]) {
                        [user setEmail:email];
                        [user saveEventually];
                    }
                }
                [BLParseUser returnToSenderWithResult:(error == nil)
                                   andCompletionBlock:loginBlock];
                [[BLParseUser currentUser] stopTimeoutOperation];
                [[BLParseUser currentUser] endBackgroundTask];
            }];
            return;
        }
        [BLParseUser returnToSenderWithResult:(error == nil)
                           andCompletionBlock:loginBlock];
        [[BLParseUser currentUser] stopTimeoutOperation];
        [[BLParseUser currentUser] endBackgroundTask];
    }];
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


#pragma mark - Timeout

@synthesize timeoutTimer = _timeoutTimer;

- (void)startTimeoutOperationWithBlock:(TimeoutBlock)timeoutBlock
{
    if (self.timeoutTimer) [self stopTimeoutOperation];
    NSTimer *timer = [BLObject startTimeoutOperationWithBlock:timeoutBlock];
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


#pragma mark - Logging In

+ (void)logInWithUsername:(NSString *)username
                 password:(NSString *)password
              forCreation:(BOOL)forCreation
                withBlock:(ParseCompletionBlock)block
{
    //Sanity
    if (![NSString isValidEmail:username]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:appName
                                        message:NSLocalizedStringFromTable(@"BLInvalidEmailAlert", @"BLGoodies", @"Alert to be displayed if the user inserts an invalid email address")
                                       delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil] show];
        });
        [self returnToSenderWithResult:NO
                    andCompletionBlock:block];
        return;
    }
    if (![NSString isValidPassword:password]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:appName
                                        message:NSLocalizedStringFromTable(@"BLInvalidPasswordAlert", @"BLGoodies", @"Alert to be displayed if the user inserts an invalid password")
                                       delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil] show];
        });
        [self returnToSenderWithResult:NO
                    andCompletionBlock:block];
        return;
    }
    
    //Internet
    if (![BLInternet doWeHaveInternetWithAlert:YES]) {
        [self returnToSenderWithResult:NO
                    andCompletionBlock:block];
        return;
    }
    
    //Logging In
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    NSTimer *timer = [self startTimeoutOperationWithBlock:^
    {
        [BLParseUser returnToSenderWithResult:NO
                           andCompletionBlock:block];
        [BLParseUser endBackgroundTask:bgTaskId];
    }];
    
    //Sign Up
    if (forCreation) {
        BLParseUser *newUser = [self object];
        [newUser setEmail:username];
        [newUser setUsername:username];
        [newUser setPassword:password];
        [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
        {
            ParseLog(@"%@",error);
            if (succeeded) {
                [newUser initialSetupWithBlock:^(BOOL success)
                {
                    [BLParseUser returnToSenderWithResult:succeeded
                                       andCompletionBlock:block];
                }];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:appName
                                                message:NSLocalizedStringFromTable(@"BLNoLoginAlert", @"BLGoodies", @"Alert to be displayed if there was an error when logging in to Parse")
                                               delegate:nil
                                      cancelButtonTitle:@"Ok"
                                      otherButtonTitles:nil] show];
                });
                [BLParseUser returnToSenderWithResult:NO
                                   andCompletionBlock:block];
            }
            [BLParseUser stopTimeoutOperation:timer];
            [BLParseUser endBackgroundTask:bgTaskId];
        }];
        return;
    }
    
    //Actual login
    [self logInWithUsernameInBackground:username
                               password:password
                                  block:^(PFUser *user, NSError *error)
    {
        if (error) ParseLog(@"%@",error);
        if (user) {
            [[BLParseUser currentUser] loginSetupWithBlock:^(BOOL success)
            {
                [BLParseUser returnToSenderWithResult:success
                                   andCompletionBlock:block];
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:appName
                                            message:NSLocalizedStringFromTable(@"BLNoLoginAlert", @"BLGoodies", @"Alert to be displayed if there was an error when logging in to Parse")
                                           delegate:nil
                                  cancelButtonTitle:@"Ok"
                                  otherButtonTitles:nil] show];
            });
            [BLParseUser returnToSenderWithResult:NO
                               andCompletionBlock:block];
        }
        [BLParseUser stopTimeoutOperation:timer];
        [BLParseUser endBackgroundTask:bgTaskId];
    }];
}

+ (void)logInToFacebookWithBlock:(ParseCompletionBlock)block
{
    //Internet
    if (![BLInternet doWeHaveInternetWithAlert:YES]) {
        [BLParseUser returnToSenderWithResult:NO
                           andCompletionBlock:block];
        return;
    }
    
    //Logging In
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    NSTimer *timer = [self startTimeoutOperationWithBlock:^
    {
        [BLParseUser returnToSenderWithResult:NO
                           andCompletionBlock:block];
        [BLParseUser endBackgroundTask:bgTaskId];
    }];
    [PFFacebookUtils logInWithPermissions:[BLParseUser facebookReadPermissions]
                                    block:^(PFUser *user, NSError *error)
    {
        if (error) FacebookLog(@"%@",error);
        if (user) {
            if (user.isNew) {
                [[BLParseUser currentUser] initialSetupWithBlock:block];
            } else {
                [[BLParseUser currentUser] loginSetupWithBlock:block];
            }
        } else {
            [BLParseUser returnToSenderWithResult:NO
                               andCompletionBlock:block];
        }
        [BLParseUser stopTimeoutOperation:timer];
        [BLParseUser endBackgroundTask:bgTaskId];
    }];
}

+ (void)logInToTwitterWithBlock:(ParseCompletionBlock)block
{
    //Internet
    if (![BLInternet doWeHaveInternetWithAlert:YES]) {
        [BLParseUser returnToSenderWithResult:NO
                           andCompletionBlock:block];
        return;
    }
    
    //Logging In
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    NSTimer *timer = [self startTimeoutOperationWithBlock:^
    {
        [BLParseUser returnToSenderWithResult:NO
                           andCompletionBlock:block];
        [BLParseUser endBackgroundTask:bgTaskId];
    }];
    [PFTwitterUtils logInWithBlock:^(PFUser *user, NSError *error)
    {
        if (error) TwitterLog(@"%@",error);
        if (user) {
            if (user.isNew) {
                [[BLParseUser currentUser] initialSetupWithBlock:block];
            } else {
                [[BLParseUser currentUser] loginSetupWithBlock:block];
            }
        } else {
            [BLParseUser returnToSenderWithResult:NO
                               andCompletionBlock:block];
        }
        [BLParseUser stopTimeoutOperation:timer];
        [BLParseUser endBackgroundTask:bgTaskId];
    }];
}


#pragma mark - Managing the User

+ (void)requestPasswordResetWithEmail:(NSString *)email
                             andBlock:(ParseCompletionBlock)block
{
    //Sanity
    if (![NSString isValidEmail:email]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:appName
                                        message:NSLocalizedStringFromTable(@"BLInvalidEmailAlert", @"BLGoodies", @"Alert to be displayed if the user inserts an invalid email address")
                                       delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil] show];
        });
        [self returnToSenderWithResult:NO
                    andCompletionBlock:block];
        return;
    }
    
    //Internet
    if (![BLInternet doWeHaveInternetWithAlert:YES]) {
        [self returnToSenderWithResult:NO
                    andCompletionBlock:block];
        return;
    }
    
    //Resetting email
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    NSTimer *timer = [self startTimeoutOperationWithBlock:^
    {
        [BLParseUser returnToSenderWithResult:NO
                           andCompletionBlock:block];
        [BLParseUser endBackgroundTask:bgTaskId];
    }];
    [self requestPasswordResetForEmailInBackground:email
                                             block:^(BOOL succeeded, NSError *error)
    {
        if (error) ParseLog(@"%@",error);
        if (succeeded) {
            [[[UIAlertView alloc] initWithTitle:appName
                                        message:NSLocalizedStringFromTable(@"BLEmailSentAlert", @"BLGoodies", @"Alert to be displayed after an email has been successfully sent to the user")
                                       delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil] show];
        }
        [BLParseUser returnToSenderWithResult:succeeded
                           andCompletionBlock:block];
        [BLParseUser stopTimeoutOperation:timer];
        [BLParseUser endBackgroundTask:bgTaskId];
    }];
}

- (void)requestPasswordResetWithBlock:(ParseCompletionBlock)block
{
    [BLParseUser requestPasswordResetWithEmail:self.email
                                      andBlock:^(BOOL success)
    {
        if (success) [BLParseUser customLogout];
        [BLParseUser returnToSenderWithResult:success
                           andCompletionBlock:block];
    }];
}


#pragma mark - Logging Out

+ (void)customLogout
{
    [self logOut];
    [PFQuery clearAllCachedResults];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:BLParseUserDidLogOutNotification
                                                            object:nil];
    });
}


#pragma mark - Aux

+ (NSArray *)facebookReadPermissions
{
    return @[@"public_profile",
             @"email",
             @"user_friends"];
}

+ (NSArray *)facebookWritePermissions
{
    return @[@"publish_actions"];
}

@end
