//
//  NSNumberFormatter+BLNumber.m
//  Project
//
//  Created by André Campana on 15/12/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "NSNumberFormatter+BLNumber.h"


static NSNumberFormatter *myNF;


@implementation NSNumberFormatter (BLNumber)

+ (NSNumberFormatter *)defaultNumberFormatter
{
    @synchronized(self)
    {
        if (!myNF) {
            myNF = [[NSNumberFormatter alloc] init];
            [myNF setNumberStyle:NSNumberFormatterDecimalStyle];
        }
        return myNF;
    }
}

+ (void)destroyNumberFormatter
{
    @synchronized(self)
    {
        myNF = nil;
    }
}

@end
