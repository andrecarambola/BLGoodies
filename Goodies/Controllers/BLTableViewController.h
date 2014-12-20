//
//  BLTableViewController.h
//  Goodies
//
//  Created by André Abou Chami Campana on 24/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BLTableViewController : UITableViewController

//Setup
- (void)setup;

//States
@property (nonatomic, getter = isLoading) BOOL loading;
- (void)didChangeLoadingStatus:(BOOL)isLoading;
- (BOOL)isVisible;
- (void)didChangeVisibilityStatus:(BOOL)isVisible;

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

//UI Actions
- (IBAction)toggleInternetLabel:(id)sender;

@end
