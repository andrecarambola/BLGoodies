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
#import "PFRole+BLRole.h"


#pragma mark - Consts
NSString * const BLParseUserDidLogOutNotification = @"BLParseUserDidLogOutNotification";


#pragma mark - Globals
static ParseCompletionBlock pushCompletionBlock;


#pragma mark - Private Interface
@interface BLParseUser ()

//Setup
- (void)setup;
@property (nonatomic) BOOL shouldClearCaches;
- (void)privateLoginSetupWithBlock:(ParseCompletionBlock)loginBlock;
//New Users
- (void)privateInitialSetupWithBlock:(ParseCompletionBlock)setupBlock;
+ (void)registerNewClientUserWithBlock:(ParseCompletionBlock)block;

//Background
@property (nonatomic) UIBackgroundTaskIdentifier bgTaskId;

//Timeout
@property (nonatomic, weak) NSTimer *timeoutTimer;
- (void)operationDidTimeout:(NSTimer *)timer;

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

//+ (void)load
//{
//    [super load];
//    [self registerSubclass];
//}

@synthesize bgTaskId = _bgTaskId;
@dynamic clearCaches;
@dynamic terms;

- (void)setup
{
    _bgTaskId = UIBackgroundTaskInvalid;
}

@dynamic shouldClearCaches;

#pragma mark New Users

- (void)privateInitialSetupWithBlock:(ParseCompletionBlock)setupBlock
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
    [BLParseUser registerNewClientUserWithBlock:^(BOOL success)
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
            [[BLParseUser currentUser] stopTimeoutOperation];
            [[BLParseUser currentUser] endBackgroundTask];
        } else {
            BLParseUser *newUser = [BLParseUser currentUser];
            [newUser setTerms:NO];
            [newUser setClearCaches:NO];
            PFACL *acl = [PFACL ACLWithUser:newUser];
            [acl setWriteAccess:YES
                forRoleWithName:[PFRole roleNameForType:blRoleAdmin]];
            [acl setReadAccess:YES
               forRoleWithName:[PFRole roleNameForType:blRoleAdmin]];
            [newUser setACL:acl];
            [newUser saveEventually];
            [newUser initialSetupWithBlock:^(BOOL success)
            {
                [BLParseUser returnToSenderWithResult:success
                                   andCompletionBlock:setupBlock];
                [[BLParseUser currentUser] stopTimeoutOperation];
                [[BLParseUser currentUser] endBackgroundTask];
            }];
        }
    }];
//    PFAnonymousUtils
}

+ (void)registerNewClientUserWithBlock:(ParseCompletionBlock)block
{
    //Sanity
    if (![BLParseUser isLogged]) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(NO);
            });
        }
        return;
    }
    
    [PFCloud callFunction:@"updateNewUser"
           withParameters:@{@"userId": [[BLParseUser currentUser] objectId]}
                 andBlock:^(BOOL success)
     {
         if (block) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 block(success);
             });
         }
     }];
}

- (void)initialSetupWithBlock:(ParseCompletionBlock)setupBlock
{
    if (setupBlock) setupBlock(YES);
}

- (void)privateLoginSetupWithBlock:(ParseCompletionBlock)loginBlock
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
    [self fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error)
     {
         if (error) {
             ParseLog(@"%@",error);
             [BLParseUser returnToSenderWithResult:NO
                                andCompletionBlock:loginBlock];
             [[BLParseUser currentUser] stopTimeoutOperation];
             [[BLParseUser currentUser] endBackgroundTask];
             return ;
         }
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
                      if ([[[[error userInfo] objectForKey:@"error"] objectForKey:@"type"]
                           isEqualToString: @"OAuthException"])
                      { // Since the request failed, we can check if it was due to an invalid session
                          FacebookLog(@"The facebook session was invalidated");
                          [BLParseUser customLogout];
#warning implement message
                      }
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
                  [[BLParseUser currentUser] loginSetupWithBlock:^(BOOL success)
                   {
                       [BLParseUser returnToSenderWithResult:success
                                          andCompletionBlock:loginBlock];
                       [[BLParseUser currentUser] stopTimeoutOperation];
                       [[BLParseUser currentUser] endBackgroundTask];
                   }];
              }];
             return;
         }
         [[BLParseUser currentUser] loginSetupWithBlock:^(BOOL success)
          {
              [BLParseUser returnToSenderWithResult:success
                                 andCompletionBlock:loginBlock];
              [[BLParseUser currentUser] stopTimeoutOperation];
              [[BLParseUser currentUser] endBackgroundTask];
          }];
     }];
}

- (void)loginSetupWithBlock:(ParseCompletionBlock)loginBlock
{
    if (loginBlock) loginBlock(YES);
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
    NSTimer *timer = [BLObject startTimeoutOperationWithTarget:self
                                                        action:@selector(operationDidTimeout:)
                                                      interval:[BLObject defaultTimeoutTime]
                                                      andBlock:timeoutBlock];
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
        [newUser setShouldClearCaches:NO];
        [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
        {
            ParseLog(@"%@",error);
            if (succeeded) {
                [newUser privateInitialSetupWithBlock:^(BOOL success)
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
            [[BLParseUser currentUser] privateLoginSetupWithBlock:^(BOOL success)
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
                [[BLParseUser currentUser] privateInitialSetupWithBlock:block];
            } else {
                [[BLParseUser currentUser] privateLoginSetupWithBlock:block];
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
                [[BLParseUser currentUser] privateInitialSetupWithBlock:block];
            } else {
                [[BLParseUser currentUser] privateLoginSetupWithBlock:block];
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


#pragma mark - Push

- (void)registerForPushNotificationsWithBlock:(ParseCompletionBlock)block
{
    if (block) pushCompletionBlock = [block copy];
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
}

- (void)handlePushRegistrationWithSuccess:(BOOL)hasSucceeded
                                  andData:(NSData *)data
{
    BOOL success = (hasSucceeded == YES && data != nil);
    if (success) {
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        [currentInstallation setDeviceTokenFromData:data];
        [currentInstallation setObject:self
                                forKey:@"user"];
        [currentInstallation saveInBackground];
    }
    ParseCompletionBlock block = pushCompletionBlock;
    [BLParseUser returnToSenderWithResult:success
                       andCompletionBlock:block];
    pushCompletionBlock = nil;
}


#pragma mark - Logging Out

+ (void)customLogout
{
    [[self currentUser] endBackgroundTask];
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
