//
//  BLCPFTextField.m
//  Project
//
//  Created by André Abou Chami Campana on 04/12/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLCPFTextField.h"


@implementation BLCPFTextField


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
    [self setMinNumberOfCharacters:11];
    [self setMaxNumberOfCharacters:14];
}


#pragma mark - Validation

- (void)checkValidText
{
    [super checkValidText];
    BOOL isValid = [self isValid];
    if (isValid) isValid = [NSString isValidCity:self.text];
    if (isValid) [self setText:[self.text cleanCity]];
    [self setIsValid:isValid];
}

@end
