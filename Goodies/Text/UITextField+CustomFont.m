//
//  UITextField+CustomFont.m
//  Manipula
//
//  Created by André Abou Chami Campana on 02/06/14.
//  Copyright (c) 2014 Carambola. All rights reserved.
//

#import "UITextField+CustomFont.h"


@implementation UITextField (CustomFont)

- (NSString *)fontName {
    return self.font.fontName;
}

- (void)setFontName:(NSString *)fontName
{
    self.font = [UIFont fontWithName:fontName
                                size:self.font.pointSize];
}

@end
