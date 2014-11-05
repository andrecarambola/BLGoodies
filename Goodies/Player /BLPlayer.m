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
#import "BLQueuer.h"
#import "BLDefines.h"


#pragma mark - Defines
#define kBLPlayerDefaultSkipTimeInSeconds 30.0
#define kBLPlayerUserDefaultsSkipKey @"com.BellAppLab.BLPlayer"
#define kBLPlayerURLsPlistFileName @"BLPlayerStoredURLs"


#pragma mark - Singleton
static BLPlayer *myPlayer;


#pragma mark - Observation Contexts
//static void *MyStreamingMovieViewControllerTimedMetadataObserverContext = &MyStreamingMovieViewControllerTimedMetadataObserverContext;
static void *BLPlayerRateObservationContext = &BLPlayerRateObservationContext;
static void *BLPlayerCurrentItemObservationContext = &BLPlayerCurrentItemObservationContext;
static void *BLPlayerItemStatusObserverContext = &BLPlayerItemStatusObserverContext;

NSString *kTracksKey		= @"tracks";
NSString *kStatusKey		= @"status";
NSString *kRateKey			= @"rate";
NSString *kPlayableKey		= @"playable";
NSString *kCurrentItemKey	= @"currentItem";
//NSString *kTimedMetadataKey	= @"currentItem.timedMetadata";


#pragma mark - Private Interface
@interface BLPlayer ()
{
    BOOL wasPlayingBeforeInterruption;
}

//Singleton
+ (void)destroyPlayer;

//Setup
+ (BOOL)hasPlayer;
@property (nonatomic) NSInteger currentMediaIndex;
- (NSURL *)currentURL;
@property (nonatomic, strong) NSMutableArray *storedURLs;
@property (nonatomic) BOOL loading;
- (BOOL)hasLoaded;
@property (nonatomic) BOOL failed;
@property (nonatomic) BOOL playing;
@property (nonatomic, readonly) BOOL isUsingTheInternet;
- (BOOL)hasPreviousTrack;
- (BOOL)hasNextTrack;

//Loading
- (void)loadMedia:(BOOL)isNext;

//Playing
- (NSTimeInterval)currentTime;
- (NSTimeInterval)currentDuration;
- (NSString *)currentTrackName;

//UI
- (void)setButtonsEnabled:(BOOL)enabled;
@property (nonatomic, weak) NSTimer *timeTimer;
- (void)startTimeTimer;
- (void)updateTimeWithTimer:(NSTimer *)timer;
- (void)updateTime:(NSTimeInterval)currentTime;
- (void)updateTimeLabel:(NSTimeInterval)currentTime;
- (void)stopTimeTimer;
- (void)updateTrackName:(NSString *)trackName;
- (void)setTrackButtonsEnabledWithBackward:(BOOL)backward
                                andForward:(BOOL)forward;

//Aux
- (NSString *)formattedTime:(NSTimeInterval)time;

/*
 PERSISTING DATA
 */
//User Defaults
#ifdef DEBUG
#warning BLPlayer: Implement iCloud support
#endif
@property (nonatomic, strong) NSNumber *defaultSkipTime;
+ (NSString *)userDefaultsSkipTimeKey;

/*
 APPLE CODE
 */
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic) float restoreAfterScrubbingRate;
@property (nonatomic, strong) id timeObserver;

- (CMTime)playerItemDuration;
- (CMTime)playerItemCurrentTime;
#ifdef DEBUG
#warning BLPlayer: Implement timed metadata
#endif
//- (void)handleTimedMetadata:(AVMetadataItem*)timedMetadata;
//- (void)updateAdList:(NSArray *)newAdList;
- (void)playerItemDidReachEnd:(NSNotification*)aNotification;
- (void)assetFailedToPrepareForPlayback:(NSError *)error;
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys;

@end


#pragma mark - Implementation
@implementation BLPlayer


#pragma mark - Responder

- (BOOL)canResignFirstResponder
{
    return ![BLPlayer hasPlayer];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeRemoteControl) {
        switch (event.subtype) {
            case UIEventSubtypeRemoteControlBeginSeekingBackward:
                [self skipTimeBackward];
                break;
            case UIEventSubtypeRemoteControlBeginSeekingForward:
                [self skipTimeForward];
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                [self moveToNextTrack];
                break;
            case UIEventSubtypeRemoteControlPause:
                [self pause];
                break;
            case UIEventSubtypeRemoteControlPlay:
                [self play];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                [self moveToPreviousTrack];
                break;
            case UIEventSubtypeRemoteControlStop:
                [self stop];
                break;
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [self togglePlay];
                break;
            case UIEventSubtypeRemoteControlEndSeekingBackward:
            case UIEventSubtypeRemoteControlEndSeekingForward:
                break;
            default:
                break;
        }
    }
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
            [myPlayer stopTimeTimer];
            [myPlayer endBackgroundTask];
        }
        myPlayer = nil;
    }
}


#pragma mark - Setup

- (void)setup
{
    [super setup];
    
    //Variables' initial state
    _loading = NO;
    _failed = NO;
    _playing = NO;
    _currentMediaIndex = -1;
    wasPlayingBeforeInterruption = NO;
    [self setRestoreAfterScrubbingRate:0.f];
    
    [self startBackgroundTask];
}

+ (BOOL)hasPlayer
{
    return (myPlayer != nil);
}

- (void)setLoading:(BOOL)loading
{
    if (_loading != loading)
    {
        //KVO
        [self willChangeValueForKey:@"isLoading"];
        
        //Storing the new value
        _loading = loading;
        
        //Failure
        [self setFailed:NO];
        
        //Reporting to delegate
        __weak BLPlayer *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[weakSelf delegate] player:weakSelf
                 didChangeLoadingStatus:loading];
        });
        
        //Updating the UI
        [self setPlaying:NO];
        [self setButtonsEnabled:!loading];
        [self updateTime:-1];
        [self updateTrackName:nil];
        id<BLPlayerControls> controls = self.playerControls;
        if ([controls respondsToSelector:@selector(mediaSpinningThing)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (loading) {
                    [[controls mediaSpinningThing] startAnimating];
                } else {
                    [[controls mediaSpinningThing] stopAnimating];
                }
            });
        }
        
        //KVO
        [self didChangeValueForKey:@"isLoading"];
    }
}

- (BOOL)hasLoaded
{
    return (self.player &&
            self.player.currentItem.status == AVPlayerItemStatusReadyToPlay);
}

- (void)setFailed:(BOOL)hasFailed
{
    _failed = hasFailed;
    if (!hasFailed) {
        [self setButtonsEnabled:NO];
        [self updateTime:-1];
        [self updateTrackName:nil];
        [[self.playerControls playButton] setEnabled:YES];
    }
}

- (void)setPlaying:(BOOL)playing
{
    if (!self.failed)
    {
        if (_playing != playing)
        {
            if (!self.isLoading || !playing)
            {
                //KVO
                [self willChangeValueForKey:@"isPlaying"];
                
                //Storing the new value
                _playing = playing;
                
                [self setFailed:NO];
                
                //Updating the UI
                [self setButtonsEnabled:YES];
                [self updateTime:self.currentTime];
                [self updateTrackName:self.currentTrackName];
                [self setTrackButtonsEnabledWithBackward:self.hasPreviousTrack
                                              andForward:self.hasNextTrack];
                id<BLPlayerControls> controls = self.playerControls;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[controls playButton] setSelected:playing];
                });
                if (playing) {
                    [self startTimeTimer];
                } else {
                    [self stopTimeTimer];
                }
                
                //KVO
                [self didChangeValueForKey:@"isPlaying"];
            }
        }
    }
}

- (void)addMediaURLs:(NSArray *)mediaURLs
{
    BOOL didAdd = NO;
    if (mediaURLs.count > 0) {
        for (NSURL *tempURL in mediaURLs) {
            if (tempURL.scheme) {
                BOOL shouldAdd = YES;
                for (NSURL *storedURL in self.storedURLs) {
                    if (storedURL == tempURL ||
                        [[storedURL absoluteString] isEqualToString:[tempURL absoluteString]])
                    {
                        shouldAdd = NO;
                        break;
                    }
                }
                if (shouldAdd) {
                    [self.storedURLs addObject:tempURL];
                    didAdd = YES;
                }
            }
        }
    }
    if (didAdd) {
        [self setTrackButtonsEnabledWithBackward:self.hasPreviousTrack
                                      andForward:self.hasNextTrack];
        if (!self.hasLoaded) [self loadMedia:YES];
    }
}

- (void)removeMediaURLs:(NSArray *)mediaURLs
{
    BOOL didRemove = NO;
    if (mediaURLs.count > 0 && _storedURLs.count > 0) {
        for (NSURL *tempURL in mediaURLs) {
            if (self.storedURLs.count == 0) {
                [self setStoredURLs:nil];
                didRemove = YES;
                break;
            }
            
            NSURL *urlToRemove;
            for (NSURL *storedURL in self.storedURLs) {
                if (storedURL == tempURL ||
                    [[storedURL absoluteString] isEqualToString:[tempURL absoluteString]])
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
                didRemove = YES;
            }
        }
    }
    if (didRemove) [self setTrackButtonsEnabledWithBackward:self.hasPreviousTrack
                                                 andForward:self.hasNextTrack];
}

- (NSMutableArray *)storedURLs
{
    if (!_storedURLs) _storedURLs = [NSMutableArray array];
    return _storedURLs;
}

- (NSURL *)currentURL
{
    if (self.currentMediaIndex < 0) return nil;
    if (!_storedURLs || _storedURLs.count == 0) return nil;
    return [_storedURLs objectAtIndex:self.currentMediaIndex];
}

- (BOOL)isUsingTheInternet
{
    NSURL *currentURL = self.currentURL;
    if (!currentURL) return NO;
    return ([currentURL.scheme rangeOfString:@"http"
                                     options:NSCaseInsensitiveSearch].location != NSNotFound);
}

- (BOOL)hasPreviousTrack
{
    if (self.currentMediaIndex < 0) return NO;
    if (!_storedURLs || _storedURLs.count < 2) return NO;
    return self.currentMediaIndex > 0;
}

- (BOOL)hasNextTrack
{
    if (self.currentMediaIndex < 0) return NO;
    if (!_storedURLs || _storedURLs.count < 2) return NO;
    return self.currentMediaIndex < self.storedURLs.count - 1;
}


#pragma mark - Notifications

- (void)handleMemoryWarningNotification:(NSNotification *)notification
{
    if (_storedURLs.count == 0) {
        [self setStoredURLs:nil];
    }
    if (!self.isPlaying) {
        [BLPlayer destroyPlayer];
    }
}

- (void)handleInternetStateChange:(NetworkStatus)networkStatus
{
    if (networkStatus == NotReachable) {
        if (self.isPlaying) {
            if (self.isUsingTheInternet) {
                wasPlayingBeforeInterruption = self.isPlaying;
                [self pause];
            }
        }
    } else {
        if (wasPlayingBeforeInterruption) {
            [self play];
        }
        wasPlayingBeforeInterruption = NO;
    }
}


#pragma mark
#pragma mark - Loading

- (BOOL)isLoading
{
    return self.loading;
}

- (void)loadMedia:(BOOL)isNext
{
    //Sanity
    if (_storedURLs.count == 0) return;
    
    if (isNext) {
        ++self.currentMediaIndex;
    } else {
        --self.currentMediaIndex;
    }
    BOOL hasMedia = self.currentMediaIndex >= 0 && self.currentMediaIndex < self.storedURLs.count - 1;
    if (!hasMedia) {
        [BLPlayer destroyPlayer];
    } else {
        NSURL *url = self.currentURL;
        
        /* Has the user entered a movie URL? */
        if (url)
        {
            [self setLoading:YES];
            /*
             Create an asset for inspection of a resource referenced by a given URL.
             Load the values for the asset keys "tracks", "playable".
             */
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url
                                                    options:nil];
            
            NSArray *requestedKeys = [NSArray arrayWithObjects:kTracksKey, kPlayableKey, nil];
            
            __weak BLPlayer *weakSelf = self;
            /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
            [asset loadValuesAsynchronouslyForKeys:requestedKeys
                                 completionHandler:^
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
                    [weakSelf prepareToPlayAsset:asset
                                        withKeys:requestedKeys];
                });
            }];
        }
        else
        {
            [self setFailed:YES];
        }
    }
}


#pragma mark
#pragma mark - Playing

- (NSTimeInterval)currentTime
{
    CMTime time = self.playerItemCurrentTime;
    if (CMTIME_IS_VALID(time)) return (NSTimeInterval)CMTimeGetSeconds(time);
    return -1;
}

- (NSTimeInterval)currentDuration
{
    CMTime time = self.playerItemDuration;
    if (CMTIME_IS_VALID(time)) return (NSTimeInterval)CMTimeGetSeconds(time);
    return -1;
}

- (NSString *)currentTrackName
{
    return [self.delegate trackNameForPlayer:self
                             andMediaWithURL:self.currentURL];
}


#pragma mark
#pragma mark - UI

- (void)setPlayerControls:(id<BLPlayerControls>)playerControls
{
    _playerControls = playerControls;
    if (playerControls) {
        [self setButtonsEnabled:!self.isLoading];
        [self updateTime:self.currentTime];
        [self updateTrackName:self.currentTrackName];
        [self startTimeTimer];
    } else {
        [self stopTimeTimer];
    }
}

- (void)setVideoControls:(id<BLPlayerVideoControls>)videoControls
{
    _videoControls = videoControls;
    [self setPlayerControls:videoControls];
    if (videoControls) {
        if (self.player) [[videoControls videoView] setPlayer:self.player];
    }
}

- (void)setButtonsEnabled:(BOOL)enabled
{
    id<BLPlayerControls> controls = self.playerControls;
    if (controls) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[controls playButton] setEnabled:enabled];
            [[controls timeSlider] setEnabled:enabled];
            if ([controls respondsToSelector:@selector(previousTrackButton)]) [[controls previousTrackButton] setEnabled:enabled];
            if ([controls respondsToSelector:@selector(nextTrackButton)]) [[controls nextTrackButton] setEnabled:enabled];
            if ([controls respondsToSelector:@selector(skipForwardButton)]) [[controls skipForwardButton] setEnabled:enabled];
            if ([controls respondsToSelector:@selector(skipBackwardButton)]) [[controls skipBackwardButton] setEnabled:enabled];
        });
    }
}

- (void)startTimeTimer
{
    [self stopTimeTimer];
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.9
                                             target:self
                                           selector:@selector(updateTimeWithTimer:)
                                           userInfo:nil
                                            repeats:YES];
    if (isiOS7) [timer setTolerance:0.2];
    __weak BLPlayer *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSRunLoop currentRunLoop] addTimer:timer
                                     forMode:NSDefaultRunLoopMode];
        [weakSelf setTimeTimer:timer];
    });
}

- (void)updateTimeWithTimer:(NSTimer *)timer
{
    [self updateTime:self.currentTime];
}

- (void)updateTime:(double)currentTime
{
    //Label
    [self updateTimeLabel:currentTime];
    id<BLPlayerControls> controls = self.playerControls;
    __weak BLPlayer *weakSelf = self;
    if (currentTime < 0.0) currentTime = 0.0;
    dispatch_async(dispatch_get_main_queue(), ^{
        //Scrubber
        UISlider *slider = [controls timeSlider];
        if (slider) {
            double duration = [weakSelf currentDuration];
            [slider setValue:roundf(currentTime / duration * slider.maximumValue)
                    animated:YES];
        }
    });
}

- (void)updateTimeLabel:(double)currentTime
{
    id<BLPlayerControls> controls = self.playerControls;
    __weak BLPlayer *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        //Label
        UILabel *elapsedTimeLabel = [controls elapsedTimeLabel];
        UILabel *remainingTimeLabel = ([controls respondsToSelector:@selector(remainingTimeLabel)]) ? [controls remainingTimeLabel] : nil;
        if (elapsedTimeLabel) [elapsedTimeLabel setText:[weakSelf formattedTime:currentTime]];
        if (remainingTimeLabel) {
            double remainingTime = [weakSelf currentDuration] - currentTime;
            [remainingTimeLabel setText:[weakSelf formattedTime:remainingTime]];
        }
    });
}

- (void)stopTimeTimer
{
    __weak BLPlayer *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[weakSelf timeTimer] invalidate];
        [weakSelf setTimeTimer:nil];
    });
}

- (void)updateTrackName:(NSString *)trackName
{
    if ([self.playerControls respondsToSelector:@selector(trackNameLabel)]) {
        UILabel *nameLabel = [self.playerControls trackNameLabel];
        NSString *name = (trackName.length == 0) ? @"-" : trackName;
        dispatch_async(dispatch_get_main_queue(), ^{
            [nameLabel setText:name];
        });
    }
}

- (void)setTrackButtonsEnabledWithBackward:(BOOL)backward
                                andForward:(BOOL)forward
{
    if (!self.isLoading && !self.failed) {
        id<BLPlayerControls> controls = self.playerControls;
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([controls respondsToSelector:@selector(previousTrackButton)]) [[controls previousTrackButton] setEnabled:backward];
            if ([controls respondsToSelector:@selector(nextTrackButton)]) [[controls nextTrackButton] setEnabled:forward];
        });
    }
}


#pragma mark
#pragma mark - Persisting Data

#pragma mark - User Defaults

- (NSTimeInterval)skipTime
{
    return (NSTimeInterval)self.defaultSkipTime.doubleValue;
}

- (NSNumber *)defaultSkipTime
{
    NSNumber *result = [self.userDefaults objectForKey:[BLPlayer userDefaultsSkipTimeKey]];
    if (!result) {
        result = @(kBLPlayerDefaultSkipTimeInSeconds);
        [BLPlayer registerDefaultSkipTimeInSeconds:(NSTimeInterval)result.doubleValue];
    }
    return result;
}

+ (NSString *)userDefaultsSkipTimeKey
{
    return [NSString stringWithFormat:@"%@.%@",kBLPlayerUserDefaultsSkipKey,[[NSBundle mainBundle] bundleIdentifier]];
}

+ (void)registerDefaultSkipTimeInSeconds:(NSTimeInterval)skipTime
{
    if ([self hasPlayer]) [myPlayer setDefaultSkipTime:nil];
    [[NSUserDefaults standardUserDefaults] setObject:@(skipTime)
                                              forKey:[self userDefaultsSkipTimeKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - Aux

- (NSString *)formattedTime:(NSTimeInterval)time
{
    if (time < 0.0) {
        return @"-";
    } else if (time == 0.0) {
        return @"00:00";
    }
    NSMutableString *result = [NSMutableString string];
    int hours = round(time / 60.0 / 60.0);
    if (hours > 0) [result appendFormat:@"%d:",hours];
    int minutes = round(time / 60.0);
    [result appendFormat:@"%@%d:",(minutes > 9) ? @"" : @"0",minutes];
    int seconds = round(minutes * 60.0 - time);
    [result appendFormat:@"%@%d",(seconds > 9) ? @"" : @"0",seconds];
    return [result copy];
}


#pragma mark
#pragma mark - Apple Code

- (CMTime)playerItemDuration
{
    AVPlayerItem *thePlayerItem = [self.player currentItem];
    if (thePlayerItem && thePlayerItem.status == AVPlayerItemStatusReadyToPlay)
    {
        /*
         NOTE:
         Because of the dynamic nature of HTTP Live Streaming Media, the best practice
         for obtaining the duration of an AVPlayerItem object has changed in iOS 4.3.
         Prior to iOS 4.3, you would obtain the duration of a player item by fetching
         the value of the duration property of its associated AVAsset object. However,
         note that for HTTP Live Streaming Media the duration of a player item during
         any particular playback session may differ from the duration of its asset. For
         this reason a new key-value observable duration property has been defined on
         AVPlayerItem.
         
         See the AV Foundation Release Notes for iOS 4.3 for more information.
         */
        
        return([self.playerItem duration]);
    }
    
    return(kCMTimeInvalid);
}

- (CMTime)playerItemCurrentTime
{
    AVPlayerItem *thePlayerItem = [self.player currentItem];
    if (thePlayerItem && thePlayerItem.status == AVPlayerItemStatusReadyToPlay)
    {
        return([self.playerItem currentTime]);
    }
    
    return(kCMTimeInvalid);
}


#pragma mark -
#pragma mark Loading the Asset Keys Asynchronously

#pragma mark -
#pragma mark Error Handling - Preparing Assets for Playback Failed

/* --------------------------------------------------------------
 **  Called when an asset fails to prepare for playback for any of
 **  the following reasons:
 **
 **  1) values of asset keys did not load successfully,
 **  2) the asset keys did load successfully, but the asset is not
 **     playable
 **  3) the item did not become ready to play.
 ** ----------------------------------------------------------- */

- (void)assetFailedToPrepareForPlayback:(NSError *)error
{
//    [self removePlayerTimeObserver];
    [self setLoading:NO];
    [self setFailed:YES];
    
    /* Display the error. */
    MediaLog(@"couldn't load media because: %@",error);
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[UIAlertView alloc] initWithTitle:appName
                                    message:NSLocalizedStringFromTable(@"BLPlayerLoadFailureAlert", @"BLGoodies", @"Alert to be displayed if an audio or a video file has failed loading")
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
    });
}

#pragma mark Prepare to play asset

/*
 Invoked at the completion of the loading of the values for all keys on the asset that we require.
 Checks whether loading was successfull and whether the asset is playable.
 If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
    /* Make sure that the value of each key has loaded successfully. */
    for (NSString *thisKey in requestedKeys)
    {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey
                                                          error:&error];
        if (keyStatus == AVKeyValueStatusFailed)
        {
            [self assetFailedToPrepareForPlayback:error];
            return;
        }
        /* If you are also implementing the use of -[AVAsset cancelLoading], add your code here to bail
         out properly in the case of cancellation. */
    }
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable)
    {
        /* Generate an error describing the failure. */
        NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
        NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.", @"Item cannot be played failure reason");
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   localizedDescription, NSLocalizedDescriptionKey,
                                   localizedFailureReason, NSLocalizedFailureReasonErrorKey,
                                   nil];
        NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"StitchedStreamPlayer" code:0 userInfo:errorDict];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }
    
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (self.playerItem)
    {
        /* Remove existing player item key value observers and notifications. */
        
        [self.playerItem removeObserver:self
                             forKeyPath:kStatusKey];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];
    }
    
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    /* Observe the player item "status" key to determine when it is ready to play. */
    [self.playerItem addObserver:self
                      forKeyPath:kStatusKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:BLPlayerItemStatusObserverContext];
    
    /* When the player item has played to its end time we'll toggle
     the movie controller Pause button to be the Play button */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
    
    /* Create new player, if we don't already have one. */
    if (![self player])
    {
        /* Get a new AVPlayer initialized to play the specified player item. */
        [self setPlayer:[AVPlayer playerWithPlayerItem:self.playerItem]];
        
        /* Observe the AVPlayer "currentItem" property to find out when any
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
         occur.*/
        [self.player addObserver:self
                      forKeyPath:kCurrentItemKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:BLPlayerCurrentItemObservationContext];
        
        /* A 'currentItem.timedMetadata' property observer to parse the media stream timed metadata. */
        //        [self.player addObserver:self
        //                      forKeyPath:kTimedMetadataKey
        //                         options:0
        //                         context:MyStreamingMovieViewControllerTimedMetadataObserverContext];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [self.player addObserver:self
                      forKeyPath:kRateKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:BLPlayerRateObservationContext];
    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if (self.player.currentItem != self.playerItem)
    {
        /* Replace the player item with a new player item. The item replacement occurs
         asynchronously; observe the currentItem property to find out when the
         replacement will/did occur*/
        [[self player] replaceCurrentItemWithPlayerItem:self.playerItem];
    }
    
    /* At this point we're ready to set up for playback of the asset. */
    
    [self setLoading:NO];
}

#pragma mark -
#pragma mark Asset Key Value Observing
#pragma mark

#pragma mark Key Value Observer for player rate, currentItem, player item status

/* ---------------------------------------------------------
 **  Called when the value at the specified key path relative
 **  to the given object has changed.
 **  Adjust the movie play and pause button controls when the
 **  player item "status" value changes. Update the movie
 **  scrubber control when the player item is ready to play.
 **  Adjust the movie scrubber control when the player item
 **  "rate" value changes. For updates of the player
 **  "currentItem" property, set the AVPlayer for which the
 **  player layer displays visual output.
 **  NOTE: this method is invoked on the main queue.
 ** ------------------------------------------------------- */

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    /* AVPlayerItem "status" property value observer. */
    if (context == BLPlayerItemStatusObserverContext)
    {
        [self setPlaying:NO];
        
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
            case AVPlayerStatusUnknown:
            {
//                [self removePlayerTimeObserver];
            }
                break;
                
            case AVPlayerStatusReadyToPlay:
            {
                /* Set the AVPlayerLayer on the view to allow the AVPlayer object to display
                 its content. */
                if (self.videoControls) [[self.videoControls videoView] setPlayer:self.player];
            }
                break;
                
            case AVPlayerStatusFailed:
            {
                AVPlayerItem *thePlayerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:thePlayerItem.error];
            }
                break;
        }
    }
    /* AVPlayer "rate" property value observer. */
    else if (context == BLPlayerRateObservationContext)
    {
        [self setPlaying:NO];
    }
    /* AVPlayer "currentItem" property observer.
     Called when the AVPlayer replaceCurrentItemWithPlayerItem:
     replacement will/did occur. */
    else if (context == BLPlayerCurrentItemObservationContext)
    {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        /* New player item null? */
        if (newPlayerItem == (id)[NSNull null])
        {
            [self setFailed:YES];
        }
        else /* Replacement of player currentItem has occurred */
        {
            /* Set the AVPlayer for which the player layer displays visual output. */
            if (self.videoControls) {
                [[self.videoControls videoView] setPlayer:self.player];
            }
            
            /* Specifies that the player should preserve the video’s aspect ratio and
             fit the video within the layer’s bounds. */
            //            [playerLayerView setVideoFillMode:AVLayerVideoGravityResizeAspect];
            
            [self setPlaying:NO];
        }
    }
    /* Observe the AVPlayer "currentItem.timedMetadata" property to parse the media stream
     timed metadata. */
    //	else if (context == MyStreamingMovieViewControllerTimedMetadataObserverContext)
    //	{
    //		NSArray* array = [[player currentItem] timedMetadata];
    //		for (AVMetadataItem *metadataItem in array)
    //		{
    //			[self handleTimedMetadata:metadataItem];
    //		}
    //	}
    else
    {
        [super observeValueForKeyPath:path
                             ofObject:object
                               change:change
                              context:context];
    }
    
    return;
}

@end





