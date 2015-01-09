//
//  BLCityTextField.m
//  Text
//
//  Created by André Abou Chami Campana on 26/05/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLCityTextField.h"


@implementation BLCityTextField


#pragma mark - Setup

- (void)setup
{
    [super setup];
    
    [self setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    [self setAutocorrectionType:UITextAutocorrectionTypeYes];
    [self setSpellCheckingType:UITextSpellCheckingTypeNo];
    [self setKeyboardType:UIKeyboardTypeDefault];
    [self setSecureTextEntry:NO];
    [self setClearsOnBeginEditing:NO];
    [self setMinNumberOfCharacters:2];
    [self setMaxNumberOfCharacters:50];
}


#pragma mark - Validation

- (void)checkValidText
{
    [super checkValidText];
    BOOL isValid = [self isValid];
    if (isValid) isValid = [NSString isValidCity:self.text];
    if (isValid) [self formatText];
    [self setIsValid:isValid];
}

- (void)formatText
{
    [self setText:[self.text cleanCity]];
}

@end
