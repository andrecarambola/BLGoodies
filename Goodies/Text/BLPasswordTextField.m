//
//  BLPasswordTextField.m
//  Text
//
//  Created by André Abou Chami Campana on 24/05/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLPasswordTextField.h"


@implementation BLPasswordTextField


#pragma mark - Setup

- (void)setup
{
    [super setup];
    
    [self setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self setSpellCheckingType:UITextSpellCheckingTypeNo];
    [self setKeyboardType:UIKeyboardTypeDefault];
    [self setSecureTextEntry:YES];
    [self setClearsOnBeginEditing:YES];
    [self setMinNumberOfCharacters:3];
    [self setMaxNumberOfCharacters:20];
}


#pragma mark - Validation

- (void)checkValidText
{
    [super checkValidText];
    BOOL isValid = [self isValid];
    if (isValid) isValid = [NSString isValidPassword:self.text];
    if (isValid) [self formatText];
    [self setIsValid:isValid];
}

- (void)formatText
{
    [self setText:[self.text cleanPassword]];
}

@end
