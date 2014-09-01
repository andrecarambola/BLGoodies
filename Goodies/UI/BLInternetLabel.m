//
//  BLInternetLabel.m
//  Goodies
//
//  Created by André Abou Chami Campana on 24/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLInternetLabel.h"
#import "BLDefines.h"


#ifndef kBLInternetLabelDefaultMargin
#define kBLInternetLabelDefaultMargin 2.f
#endif


@interface BLInternetLabel ()

- (void)setup;

@end


@implementation BLInternetLabel

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) [self setup];
    return self;
}

- (id)initWithWidth:(CGFloat)width
{
    if (self == [self init] && width > 0) {
        NSAttributedString *attString = [[NSAttributedString alloc] initWithString:self.text];
        CGRect textRect = [attString boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                                  context:nil];
        [self setFrame:CGRectMake(0.f,
                                  0.f,
                                  width,
                                  ceilf(textRect.size.height) + 2.f * kBLInternetLabelDefaultMargin)];
    }
    return self;
}

- (id)init
{
    if (self = [super init]) [self setup];
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
    [self setNumberOfLines:0];
    [self setTextAlignment:NSTextAlignmentCenter];
    [self setText:NSLocalizedStringFromTable(@"BLNoInternetAlert", @"BLGoodies", @"Text to be presented when a connection to the internet cannot be estabilished")];
}

@end
