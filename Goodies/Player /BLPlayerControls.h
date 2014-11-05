//
//  BLPlayerControls.h
//  Player
//
//  Created by André Abou Chami Campana on 18/05/14.
//  Copyright (c) 2014 BaffiLab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLVideoView.h"


@protocol BLPlayerControls <NSObject>
@property (nonatomic, weak) IBOutlet UIButton *playButton;
- (IBAction)playButtonPressed:(UIButton *)sender;
@property (nonatomic, weak) IBOutlet UISlider *timeSlider;
- (IBAction)timeSliderTouchedDown:(UISlider *)sender;
- (IBAction)timeSliderTouchedDragInside:(UISlider *)sender;
- (IBAction)timeSliderValueChanged:(UISlider *)sender;
- (IBAction)timeSliderTouchedUpInside:(UISlider *)sender;
- (IBAction)timeSliderTouchedUpOutside:(UISlider *)sender;
@property (nonatomic, weak) IBOutlet UILabel *elapsedTimeLabel;
@optional
@property (nonatomic, weak) IBOutlet UIButton *previousTrackButton;
@property (nonatomic, weak) IBOutlet UIButton *nextTrackButton;
- (IBAction)changeTrackPressed:(UIButton *)sender;
@property (nonatomic, weak) IBOutlet UIButton *skipForwardButton;
@property (nonatomic, weak) IBOutlet UIButton *skipBackwardButton;
- (IBAction)skipPressed:(UIButton *)sender;
@property (nonatomic, weak) IBOutlet UILabel *remainingTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *trackNameLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *mediaSpinningThing;
@end


@protocol BLPlayerVideoControls <BLPlayerControls>
@property (nonatomic, weak) IBOutlet BLVideoView *videoView;
@optional
@property (nonatomic, weak) IBOutlet UIButton *toggleGravityButton;
- (IBAction)toggleGravityPressed:(UIButton *)sender;
@end
