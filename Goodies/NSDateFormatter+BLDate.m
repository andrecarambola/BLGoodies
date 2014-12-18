//
//  NSDateFormatter+BLDate.m
//  Project
//
//  Created by André Campana on 15/12/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "NSDateFormatter+BLDate.h"


static NSDateFormatter *myDF;


@implementation NSDateFormatter (BLDate)

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

+ (void)destroyDateFormatter
{
    @synchronized(self)
    {
        myDF = nil;
    }
}

@end
