//
//  BLPlayerControls.h
//  Player
//
//  Created by André Abou Chami Campana on 18/05/14.
//  Copyright (c) 2014 BaffiLab. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol BLPlayerControls <NSObject>
@property (weak, nonatomic) IBOutlet UIButton *playButton;
- (IBAction)playButtonPressed:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UISlider *timeSlider;
- (IBAction)timeSliderTouchedDown:(UISlider *)sender;
- (IBAction)timeSliderTouchedDragInside:(UISlider *)sender;
- (IBAction)timeSliderValueChanged:(UISlider *)sender;
- (IBAction)timeSliderTouchedUpInside:(UISlider *)sender;
- (IBAction)timeSliderTouchedUpOutside:(UISlider *)sender;
@property (weak, nonatomic) IBOutlet UILabel *elapsedTimeLabel;
@optional
@property (weak, nonatomic) IBOutlet UIButton *previousTrackButton;
@property (weak, nonatomic) IBOutlet UIButton *nextTrackButton;
@property (weak, nonatomic) IBOutlet UIButton *skipForwardButton;
@property (weak, nonatomic) IBOutlet UIButton *skipBackwardButton;
@property (weak, nonatomic) IBOutlet UILabel *remainingTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *trackNameLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinningThing;
@end
