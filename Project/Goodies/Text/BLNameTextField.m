//
//  BLNameTextField.m
//  Text
//
//  Created by André Abou Chami Campana on 24/05/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLNameTextField.h"


@implementation BLNameTextField


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
    [self setMinNumberOfCharacters:3];
    [self setMaxNumberOfCharacters:50];
}


#pragma mark - Validation

- (void)checkValidText
{
    [super checkValidText];
    BOOL isValid = [self isValid];
    if (isValid) isValid = [NSString isValidName:self.text];
    if (isValid) [self setText:[self.text cleanName]];
    [self setIsValid:isValid];
}

@end
