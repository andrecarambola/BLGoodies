//
//  BLPlayerDelegate.h
//  Player
//
//  Created by André Abou Chami Campana on 18/05/14.
//  Copyright (c) 2014 BaffiLab. All rights reserved.
//

#import <Foundation/Foundation.h>


@class BLPlayer;


@protocol BLPlayerDelegate <NSObject>
- (void)player:(BLPlayer *)player didChangeLoadingStatus:(BOOL)isLoading;
- (void)player:(BLPlayer *)player willStartPlayingMediaWithURL:(NSURL *)mediaURL;
- (NSTimeInterval)player:(BLPlayer *)player timeToSeekBeforePlayingMediaWithURL:(NSURL *)mediaURL;
- (BOOL)shouldEnableSliderForPlayer:(BLPlayer *)player andMediaWithURL:(NSURL *)mediaURL;
- (NSString *)trackNameForPlayer:(BLPlayer *)player andMediaWithURL:(NSURL *)mediaURL;
- (void)player:(BLPlayer *)player didStopPlayingMediaWithURL:(NSURL *)mediaURL atTime:(double)timeInSeconds;
@end
