//
//  BLTextField.h
//  Text
//
//  Created by André Abou Chami Campana on 24/05/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSString+BLText.h"


@interface BLTextField : UITextField

//Setup
- (void)setup;

//Validation
@property (nonatomic) BOOL isValid;
@property (nonatomic) NSInteger minNumberOfCharacters;
@property (nonatomic) NSInteger maxNumberOfCharacters;
- (void)checkValidText;
- (void)formatText;

@end
