//
//  BLTableViewController.m
//  Goodies
//
//  Created by André Abou Chami Campana on 24/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLTableViewController.h"
#import "NSObject+Goodies.h"
#import "BLInternet.h"
#import "BLInternetLabel.h"
#import "BLDefines.h"


@interface BLTableViewController ()
{
    int loadingCounter;
}

//App States
- (void)handleWeAreGoingToTheBackgroundNotification:(NSNotification *)notification;
- (void)handleWeAreComingBackFromTheBackgroundNotification:(NSNotification *)notification;

//Internet
@property (nonatomic, weak) BLInternetLabel *internetLabel;
@property (nonatomic) BLInternetStatusChangeBlockIdentifier internetId;
- (void)toggleInternetLabelWithConnection:(BOOL)hasConnection
                                 animated:(BOOL)animated;

@end


@implementation BLTableViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Setup

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

- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) [self setup];
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
    _handlesAppStates = NO;
    _handlesInternet = NO;
    _internetId = BLInternetStatusChangeInvalid;
}


#pragma mark - View Controller Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    [self handleAppStateChange:YES];
}

- (void)handleWeAreComingBackFromTheBackgroundNotification:(NSNotification *)notification
{
    [self handleAppStateChange:NO];
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 0;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Internet

- (void)setHandlesInternet:(BOOL)handlesInternet
{
    if (_handlesInternet == handlesInternet || !_handlesInternet) {
        [self willChangeValueForKey:@"handlesInternet"];
        
        if (handlesInternet) {
            if (self.internetId == BLInternetStatusChangeInvalid) {
                __weak BLTableViewController *weakSelf = self;
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
        [label setOpaque:NO];
        [label setBackgroundColor:[label.backgroundColor colorWithAlphaComponent:.7f]];
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
    
    CGRect labelRect;
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
    } else {
        labelRect = CGRectMake(0.f,
                               -label.frame.size.height,
                               label.frame.size.width,
                               label.frame.size.height);
    }
    
    void (^animationBlock) () = ^
    {
        [label setFrame:labelRect];
        [label setAlpha:(show) ? 1.f : 0.f];
    };
    
    __weak BLTableViewController *weakSelf = self;
    void (^completionBlock) (BOOL) = ^(BOOL finished)
    {
        if (finished) {
            if (!show) {
                [label removeFromSuperview];
                [weakSelf setInternetLabel:nil];
            }
        }
    };
    
    [self.tableView setContentOffset:CGPointMake(0.f,
                                                 -label.frame.size.height)
                            animated:animated];
    
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

@end
