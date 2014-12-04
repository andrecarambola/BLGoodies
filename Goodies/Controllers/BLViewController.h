//
//  BLViewController.h
//  Goodies
//
//  Created by André Abou Chami Campana on 24/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BLViewController : UIViewController

//Setup
- (id)initFromNib;
- (void)setup;

//States
@property (nonatomic, getter = isLoading) BOOL loading;
- (void)didChangeLoadingStatus:(BOOL)isLoading;

//App States
@property (nonatomic) BOOL handlesAppStates;
- (void)handleAppStateChange:(BOOL)toTheBackground;

//Internet
@property (nonatomic) BOOL handlesInternet;
- (void)handleInternetStateChange:(BOOL)hasConnection;

//UI Elements
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *spinningThing;
@property (nonatomic, strong) IBOutletCollection(UIControl) NSArray *loadingControls;
@property (nonatomic, strong) IBOutletCollection(UIBarItem) NSArray *loadingBarItems;
@property (nonatomic, strong) IBOutletCollection(UIView) NSArray *loadingViews;
@property (nonatomic, weak) IBOutlet UIView *movableContentViewForInternet;

//UI Actions
- (IBAction)toggleInternetLabel:(id)sender;

@end
