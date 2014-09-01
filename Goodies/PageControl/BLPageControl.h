//
//  BLPageControl.h
//  PageControl
//
//  Created by André Abou Chami Campana on 13/06/14.
//  Copyright (c) 2014 BaffiLab. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface BLPageControl : UIControl

//Page Navigation
@property (nonatomic) NSInteger numberOfPages;
@property (nonatomic) NSInteger currentPage;
@property (nonatomic) BOOL hidesForSinglePage;

//Updating the Page Display
- (UIImage *)imageForPageState:(UIControlState)pageState UI_APPEARANCE_SELECTOR;
- (void)setImage:(UIImage *)image forPageState:(UIControlState)pageState UI_APPEARANCE_SELECTOR;

@end
