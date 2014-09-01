//
//  BLPlayer.m
//  Player
//
//  Created by André Abou Chami Campana on 18/05/14.
//  Copyright (c) 2014 BaffiLab. All rights reserved.
//
//BASED ON APPLE'S StitchedStreamPlayer
/*
 Version: 1.4
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import "BLPlayer.h"


#pragma mark - Defines
#define kBLPlayerDefaultSkipTimeInSeconds 30.0
#define kBLPlayerUserDefaultsSkipKey @"com.BellAppLab.BLPlayer"
#define kBLPlayerURLsPlistFileName @"BLPlayerStoredURLs"
#ifdef DEBUG
/*
 Comment this out if you don't want a logger at all.
 */
#define kBLPlayerLogger
#endif
#ifdef kBLPlayerLogger
#   define BLPlayerLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define BLPlayerLog(...)
#endif

#pragma mark - Singleton
static BLPlayer *myPlayer;


#pragma mark - Observation Contexts
//static void *MyStreamingMovieViewControllerTimedMetadataObserverContext = &MyStreamingMovieViewControllerTimedMetadataObserverContext;
static void *MyStreamingMovieViewControllerRateObservationContext = &MyStreamingMovieViewControllerRateObservationContext;
static void *MyStreamingMovieViewControllerCurrentItemObservationContext = &MyStreamingMovieViewControllerCurrentItemObservationContext;
static void *MyStreamingMovieViewControllerPlayerItemStatusObserverContext = &MyStreamingMovieViewControllerPlayerItemStatusObserverContext;

NSString *kTracksKey		= @"tracks";
NSString *kStatusKey		= @"status";
NSString *kRateKey			= @"rate";
NSString *kPlayableKey		= @"playable";
NSString *kCurrentItemKey	= @"currentItem";
//NSString *kTimedMetadataKey	= @"currentItem.timedMetadata";


#pragma mark - Private Interface
@interface BLPlayer ()
{
    //Setup
    BOOL _isLoading;
    BOOL _isPlaying;
}

//Singleton
+ (void)destroyPlayer;

//Setup
- (void)setup;
- (BOOL)hasPlayer;
@property (nonatomic) NSInteger currentMediaIndex;
@property (strong, nonatomic) NSMutableArray *storedURLs;

//Notifications
- (void)handleMemoryWarningNotification:(NSNotification *)notification;

//Loading
- (void)loadMedia:(BOOL)isNext;

//UI
- (void)setButtonsEnabled:(BOOL)enabled;

/*
 PERSISTING DATA
 */
//User Defaults
@property (readonly, nonatomic) NSUserDefaults *userDefaults;
@property (nonatomic) double defaultSkipTime;
+ (NSString *)userDefaultsSkipTimeKey;

/*
 APPLE CODE
 */
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (nonatomic) float restoreAfterScrubbingRate;
@property (strong, nonatomic) id timeObserver;

- (CMTime)playerItemDuration;
#ifdef DEBUG
#warning BLPlayer: Implement timed metadata
#endif
//- (void)handleTimedMetadata:(AVMetadataItem*)timedMetadata;
//- (void)updateAdList:(NSArray *)newAdList;
- (void)assetFailedToPrepareForPlayback:(NSError *)error;
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys;

@end


#pragma mark - Implementation
@implementation BLPlayer

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self resignFirstResponder];
}


#pragma mark - Responder

- (UIResponder *)nextResponder
{
    return [UIApplication sharedApplication];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    BOOL result = [super becomeFirstResponder];
    if (result) [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    return result;
}

- (BOOL)canResignFirstResponder
{
    return ![self hasPlayer];
}

- (BOOL)resignFirstResponder
{
    BOOL result = [super resignFirstResponder];
    if (result) [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    return result;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
#warning BLPlayer: implement
}


#pragma mark - Singleton

+ (BLPlayer *)sharedPlayer
{
    @synchronized(self)
    {
        if (!myPlayer) {
            myPlayer = [[BLPlayer alloc] init];
        }
        return myPlayer;
    }
}

+ (void)destroyPlayer
{
    @synchronized(self)
    {
        if (myPlayer) {
            [myPlayer.userDefaults synchronize];
        }
        myPlayer = nil;
    }
}


#pragma mark - Setup

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    //Variables' initial state
    _isLoading = NO;
    _isPlaying = NO;
    _currentMediaIndex = 0;
    [self setRestoreAfterScrubbingRate:0.f];
    
    //Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMemoryWarningNotification:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:[UIApplication sharedApplication]];
    
    //UI Responder
    [self becomeFirstResponder];
}

- (BOOL)hasPlayer
{
    return (self.player != nil);
}

- (BOOL)isLoading
{
    return _isLoading;
}

- (void)setIsLoading:(BOOL)isLoading
{
    //KVO
    [self willChangeValueForKey:@"isLoading"];
    
    //Storing the new value
    _isLoading = isLoading;
    
    //Reporting to delegate
    __weak BLPlayer *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[weakSelf delegate] player:weakSelf
             didChangeLoadingStatus:isLoading];
    });
    
    //Updating the UI
    [self setButtonsEnabled:!isLoading];
    id<BLPlayerControls> controls = self.playerControls;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isLoading) {
            [[controls spinningThing] startAnimating];
        } else {
            [[controls spinningThing] stopAnimating];
        }
    });
    
    //KVO
    [self didChangeValueForKey:@"isLoading"];
}

- (void)addMediaURLs:(NSArray *)mediaURLs
{
    if (mediaURLs.count > 0) {
        for (NSURL *tempURL in mediaURLs) {
            BOOL shouldAdd = YES;
            for (NSURL *storedURL in self.storedURLs) {
                if (storedURL == tempURL ||
                    [[storedURL path] isEqualToString:[tempURL path]])
                {
                    shouldAdd = NO;
                    break;
                }
            }
            if (shouldAdd) [self.storedURLs addObject:tempURL];
        }
        [self.storedURLs addObjectsFromArray:mediaURLs];
#warning implement loading if needed
    }
}

- (void)removeMediaURLs:(NSArray *)mediaURLs
{
    if (mediaURLs.count > 0) {
        for (NSURL *tempURL in mediaURLs) {
            if (self.storedURLs.count == 0) break;
            
            NSURL *urlToRemove;
            for (NSURL *storedURL in self.storedURLs) {
                if (storedURL == tempURL ||
                    [[storedURL path] isEqualToString:[tempURL path]])
                {
                    urlToRemove = tempURL;
                    break;
                }
            }
            
            if (urlToRemove) {
                if (self.storedURLs.count == 1) {
                    [self stop];
                    break;
                } else {
                    [self.storedURLs removeObject:urlToRemove];
                }
            }
        }
    }
}

- (NSMutableArray *)storedURLs
{
    if (!_storedURLs) {
        _storedURLs = [NSMutableArray array];
    }
    return _storedURLs;
}


#pragma mark - Notifications

- (void)handleMemoryWarningNotification:(NSNotification *)notification
{
    if (_storedURLs.count == 0) {
        [self setStoredURLs:nil];
    }
}


#pragma mark
#pragma mark - Persisting Data

#pragma mark - User Defaults

- (NSUserDefaults *)userDefaults
{
#ifdef DEBUG
#warning BLPlayer: Implement iCloud support
#endif
    return [NSUserDefaults standardUserDefaults];
}

- (double)defaultSkipTime
{
    NSNumber *result = [self.userDefaults objectForKey:[BLPlayer userDefaultsSkipTimeKey]];
    if (!result) {
        __weak BLPlayer *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf setDefaultSkipTime:kBLPlayerDefaultSkipTimeInSeconds];
        });
        return kBLPlayerDefaultSkipTimeInSeconds;
    }
    return [result doubleValue];
}

- (void)setDefaultSkipTime:(double)defaultSkipTime
{
    [self.userDefaults setObject:@(defaultSkipTime)
                          forKey:[BLPlayer userDefaultsSkipTimeKey]];
}

+ (NSString *)userDefaultsSkipTimeKey
{
    return [NSString stringWithFormat:@"%@.%@",kBLPlayerUserDefaultsSkipKey,[[NSBundle mainBundle] bundleIdentifier]];
}


#pragma mark
#pragma mark - Apple Code

@end





