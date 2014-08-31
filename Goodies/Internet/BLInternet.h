//
//  BLInternet.h
//  Goodies
//
//  Created by André Abou Chami Campana on 24/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLObject.h"
#import "Reachability.h"


typedef void (^InternetStatusChangeBlock) (NetworkStatus newStatus);
typedef NSUInteger BLInternetStatusChangeBlockIdentifier;
extern BLInternetStatusChangeBlockIdentifier const BLInternetStatusChangeInvalid;


@interface BLInternet : BLObject

//Setup
+ (void)startInternetWithHost:(NSString *)host;
+ (void)setThresholdForNetworkActivityIndicator:(NSTimeInterval)threshold;

//Internet Status
+ (BOOL)doWeHaveInternet;
+ (BOOL)doWeHaveInternetWithAlert:(BOOL)showAlert;
+ (NetworkStatus)networkStatus;

//Internet Status Change Block
+ (BLInternetStatusChangeBlockIdentifier)registerInternetStatusChangeBlock:(InternetStatusChangeBlock)block;
+ (void)unregisterInternetStatusChangeBlockWithId:(BLInternetStatusChangeBlockIdentifier)identifier;

//Network Activity Indicator
+ (void)willStartInternetOperation;
+ (BOOL)areWeUsingTheInternet;
+ (void)didEndInternetOperation;

@end
