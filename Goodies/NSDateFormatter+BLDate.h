//
//  NSDateFormatter+BLDate.h
//  Project
//
//  Created by André Campana on 15/12/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDateFormatter (BLDate)

+ (NSDateFormatter *)defaultDateFormatter;
+ (void)destroyDateFormatter;

@end
