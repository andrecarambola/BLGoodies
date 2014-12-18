//
//  PFConfig+BLConfig.h
//  Project
//
//  Created by André Campana on 11/12/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "PFObject+BLObject.h"


@interface PFConfig (BLConfig)

+ (void)loadConfigWithBlock:(ParseCompletionBlock)block;

@end
