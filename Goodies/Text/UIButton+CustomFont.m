//
//  UIButton+CustomFont.m
//  Manipula
//
//  Created by André Abou Chami Campana on 02/06/14.
//  Copyright (c) 2014 Carambola. All rights reserved.
//

#import "UIButton+CustomFont.h"


@implementation UIButton (CustomFont)

- (NSString *)fontName {
    return self.titleLabel.font.fontName;
}

- (void)setFontName:(NSString *)fontName
{
    self.titleLabel.font = [UIFont fontWithName:fontName
                                           size:self.titleLabel.font.pointSize];
}

@end
