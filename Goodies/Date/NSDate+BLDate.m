//
//  NSDate+BLDate.m
//  Project
//
//  Created by André Abou Chami Campana on 09/11/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "NSDate+BLDate.h"


static NSDateFormatter *myDF;


@implementation NSDate (BLDate)

+ (NSDateFormatter *)defaultDateFormatter
{
    @synchronized(self)
    {
        if (!myDF) {
            myDF = [[NSDateFormatter alloc] init];
            [myDF setDateStyle:NSDateFormatterShortStyle];
            [myDF setTimeStyle:NSDateFormatterNoStyle];
        }
        return myDF;
    }
}

@end
