//
//  PFCloud+BLCloud.h
//  Project
//
//  Created by André Abou Chami Campana on 31/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import <Parse/Parse.h>
#import "PFObject+BLObject.h"


@interface PFCloud (BLCloud)

//Default Functions
+ (void)callFunction:(NSString *)function
      withParameters:(NSDictionary *)parameters
            andBlock:(ParseCompletionBlock)block;

@end
