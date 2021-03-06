//
//  BLViewController.m
//  Goodies
//
//  Created by André Abou Chami Campana on 24/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLViewController.h"
#import "NSObject+Goodies.h"
#import "BLInternet.h"
#import "BLInternetLabel.h"
#import "BLDefines.h"


@interface BLViewController ()
{
    int loadingCounter;
}

//States
@property (nonatomic) BOOL hasAppeared;

//App States
@property (nonatomic) BOOL isInBackground;
- (void)handleWeAreGoingToTheBackgroundNotification:(NSNotification *)notification;
- (void)handleWeAreComingBackFromTheBackgroundNotification:(NSNotification *)notification;

//Internet
@property (nonatomic, weak) BLInternetLabel *internetLabel;
@property (nonatomic) BLInternetStatusChangeBlockIdentifier internetId;
- (void)toggleInternetLabelWithConnection:(BOOL)hasConnection
                                 animated:(BOOL)animated;

@end


@implementation BLViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Setup

- (id)initFromNib
{
    self = [self initWithNibName:NSStringFromClass([self class])
                          bundle:nil];
    return self;
}

- (id)init
{
    if (self = [super init]) [self setup];
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
    loadingCounter = 0;
    _hasAppeared = NO;
    _isInBackground = NO;
    _handlesAppStates = NO;
    _handlesInternet = NO;
    _internetId = BLInternetStatusChangeInvalid;
}


#pragma mark - View Controller Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //UI
    [self.movableContentViewForInternet setOpaque:NO];
    [self.movableContentViewForInternet setBackgroundColor:[UIColor clearColor]];
    
    //Visibility
    [self setHandlesAppStates:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self setHasAppeared:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self setHasAppeared:NO];
    
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - States

- (BOOL)isLoading
{
    return loadingCounter > 0;
}

- (void)setLoading:(BOOL)loading
{
    if (self.loading != loading || !loading) {
        [self willChangeValueForKey:@"loading"];
        
        if (loading) {
            [self.spinningThing startAnimating];
        } else {
            [self.spinningThing stopAnimating];
        }
        
        for (UIControl *control in self.loadingControls) {
            [control setEnabled:!loading];
        }
        
        for (UIBarItem *barItem in self.loadingBarItems) {
            [barItem setEnabled:!loading];
        }
        
        for (UIView *view in self.loadingViews) {
            [view setHidden:loading];
        }
        
        if (loading) {
            ++loadingCounter;
        } else {
            --loadingCounter;
            if (loadingCounter < 0) loadingCounter = 0;
        }
        
        [self didChangeLoadingStatus:loading];
        [self didChangeValueForKey:@"loading"];
    }
}

- (void)didChangeLoadingStatus:(BOOL)isLoading
{
    return;
}

- (BOOL)isVisible
{
    return (self.isViewLoaded && self.hasAppeared && !self.isInBackground);
}

- (void)setHasAppeared:(BOOL)hasAppeared
{
    BOOL isVisible = self.isVisible;
    if (hasAppeared && self.isInBackground) [self setIsInBackground:NO];
    _hasAppeared = hasAppeared;
    if (self.isVisible != isVisible) [self didChangeVisibilityStatus:self.isVisible];
}

- (void)setIsInBackground:(BOOL)isInBackground
{
    BOOL isVisible = self.isVisible;
    _isInBackground = isInBackground;
    if (self.isVisible != isVisible) [self didChangeVisibilityStatus:self.isVisible];
}

- (void)didChangeVisibilityStatus:(BOOL)isVisible
{
    return;
}


#pragma mark - App States

- (void)setHandlesAppStates:(BOOL)handlesAppStates
{
    if (_handlesAppStates == handlesAppStates || !_handlesAppStates) {
        [self willChangeValueForKey:@"handlesAppStates"];
        
        if (handlesAppStates) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleWeAreGoingToTheBackgroundNotification:)
                                                         name:UIApplicationWillResignActiveNotification
                                                       object:[UIApplication sharedApplication]];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleWeAreComingBackFromTheBackgroundNotification:)
                                                         name:UIApplicationWillEnterForegroundNotification
                                                       object:[UIApplication sharedApplication]];
        } else {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:UIApplicationWillResignActiveNotification
                                                          object:[UIApplication sharedApplication]];
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:UIApplicationWillEnterForegroundNotification
                                                          object:[UIApplication sharedApplication]];
        }
        
        _handlesAppStates = handlesAppStates;
        [self didChangeValueForKey:@"handlesAppStates"];
    }
}

- (void)handleAppStateChange:(BOOL)toTheBackground
{
    return;
}

- (void)handleWeAreGoingToTheBackgroundNotification:(NSNotification *)notification
{
    [self setIsInBackground:YES];
    [self handleAppStateChange:YES];
}

- (void)handleWeAreComingBackFromTheBackgroundNotification:(NSNotification *)notification
{
    [self setIsInBackground:NO];
    [self handleAppStateChange:NO];
}


#pragma mark - Internet

- (void)setHandlesInternet:(BOOL)handlesInternet
{
    if (_handlesInternet == handlesInternet || !_handlesInternet) {
        [self willChangeValueForKey:@"handlesInternet"];
        
        if (handlesInternet) {
            if (self.internetId == BLInternetStatusChangeInvalid) {
                __weak BLViewController *weakSelf = self;
                [BLInternet registerInternetStatusChangeBlock:^(NetworkStatus newStatus)
                {
                    [weakSelf handleInternetStateChange:(newStatus != NotReachable)];
                }];
            }
        } else {
            if (self.internetId != BLInternetStatusChangeInvalid) {
                [BLInternet unregisterInternetStatusChangeBlockWithId:self.internetId];
            }
        }
        
        _handlesInternet = handlesInternet;
        [self didChangeValueForKey:@"handlesInternet"];
    }
}

- (void)handleInternetStateChange:(BOOL)hasConnection
{
    [self toggleInternetLabelWithConnection:hasConnection
                                   animated:YES];
}

- (BLInternetLabel *)internetLabel
{
    if (!_internetLabel) {
        BLInternetLabel *label = [[BLInternetLabel alloc] initWithWidth:self.view.frame.size.width];
        [label setHidden:YES];
        [self.view insertSubview:label
                    aboveSubview:[self.view.subviews lastObject]];
        _internetLabel = label;
    }
    return _internetLabel;
}

- (void)toggleInternetLabelWithConnection:(BOOL)hasConnection
                                 animated:(BOOL)animated
{
    //Sanity
    if (hasConnection && !_internetLabel) return;
    if (!hasConnection && _internetLabel) return;
    
    BOOL show = !hasConnection;
    
    BLInternetLabel *label = self.internetLabel;
    UIView *contentView = self.movableContentViewForInternet;
    
    CGRect labelRect, contentRect;
    if (show) {
        [label setFrame:CGRectMake(0.f,
                                   -label.frame.size.height,
                                   label.frame.size.width,
                                   label.frame.size.height)];
        [label setAlpha:0.f];
        [label setHidden:NO];
        labelRect = CGRectMake(0.f,
                               0.f,
                               label.frame.size.width,
                               label.frame.size.height);
        contentRect = CGRectMake(0.f,
                                 label.frame.size.height,
                                 contentView.frame.size.width,
                                 contentView.frame.size.height);
    } else {
        labelRect = CGRectMake(0.f,
                               -label.frame.size.height,
                               label.frame.size.width,
                               label.frame.size.height);
        contentRect = CGRectMake(0.f,
                                 0.f,
                                 contentView.frame.size.width,
                                 contentView.frame.size.height);
    }
    
    void (^animationBlock) () = ^
    {
        [contentView setFrame:contentRect];
        [label setFrame:labelRect];
        [label setAlpha:(show) ? 1.f : 0.f];
    };
    
    __weak BLViewController *weakSelf = self;
    void (^completionBlock) (BOOL) = ^(BOOL finished)
    {
        if (finished) {
            if (!show) {
                [label removeFromSuperview];
                [weakSelf setInternetLabel:nil];
            }
        }
    };
    
    if (animated) {
        [UIView animateWithDuration:kBLDefaultAnimationTime
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionOverrideInheritedDuration
                         animations:animationBlock
                         completion:completionBlock];
    } else {
        animationBlock();
        completionBlock(YES);
    }
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


#pragma mark - UI Actions

- (IBAction)toggleInternetLabel:(id)sender
{
    [self toggleInternetLabelWithConnection:[BLInternet doWeHaveInternet]
                                   animated:YES];
}


#pragma mark - KVO

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    if ([key isEqualToString:@"handlesAppStates"] || 
        [key isEqualToString:@"handlesInternet"] ||
        [key isEqualToString:@"loading"]) 
    {
        return NO;
    }
    return [super automaticallyNotifiesObserversForKey:key];
}

@end
