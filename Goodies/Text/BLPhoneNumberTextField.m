//
//  BLPhoneNumberTextField.m
//  Text
//
//  Created by André Abou Chami Campana on 24/05/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLPhoneNumberTextField.h"


@implementation BLPhoneNumberTextField


#pragma mark - Setup

- (void)setup
{
    [super setup];
    
    [self setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self setSpellCheckingType:UITextSpellCheckingTypeNo];
    [self setKeyboardType:UIKeyboardTypeNumberPad];
    [self setSecureTextEntry:NO];
    [self setClearsOnBeginEditing:NO];
    [self setMinNumberOfCharacters:5];
    [self setMaxNumberOfCharacters:16];
}


#pragma mark - Validation

- (void)checkValidText
{
    [super checkValidText];
    BOOL isValid = [self isValid];
    if (isValid) isValid = [NSString isValidPhoneNumber:self.text];
    if (isValid) [self formatText];
    [self setIsValid:isValid];
}

- (void)formatText
{
    [self setText:[NSString formattedPhoneNumber:self.text]];
}

@end
