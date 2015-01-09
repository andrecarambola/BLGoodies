//
//  BLStateTextField.m
//  Text
//
//  Created by André Abou Chami Campana on 26/05/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLStateTextField.h"


@implementation BLStateTextField


#pragma mark - Setup

- (void)setup
{
    [super setup];
    
    [self setAutocapitalizationType:UITextAutocapitalizationTypeAllCharacters];
    [self setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self setSpellCheckingType:UITextSpellCheckingTypeNo];
    [self setKeyboardType:UIKeyboardTypeDefault];
    [self setSecureTextEntry:NO];
    [self setClearsOnBeginEditing:NO];
    [self setMinNumberOfCharacters:2];
    [self setMaxNumberOfCharacters:2];
}


#pragma mark - Validation

- (void)checkValidText
{
    [super checkValidText];
    BOOL isValid = [self isValid];
    if (isValid) isValid = [NSString isValidState:self.text];
    if (isValid) [self formatText];
    [self setIsValid:isValid];
}

- (void)formatText
{
    [self setText:[self.text cleanState]];
}

@end
