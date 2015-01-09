//
//  BLPostalCodeTextField.m
//  Text
//
//  Created by André Abou Chami Campana on 24/05/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLPostalCodeTextField.h"


@implementation BLPostalCodeTextField


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
    [self setMinNumberOfCharacters:9];
    [self setMaxNumberOfCharacters:9];
}


#pragma mark - Validation

- (void)checkValidText
{
    [super checkValidText];
    BOOL isValid = [self isValid];
    if (isValid) isValid = [NSString isValidPostalCode:self.text];
    if (isValid) [self formatText];
    [self setIsValid:isValid];
}

- (void)formatText
{
    [self setText:[NSString formattedPostalCode:self.text]];
}

@end
