//
//  NSString+BLText.m
//  Text
//
//  Created by André Abou Chami Campana on 24/05/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "NSString+BLText.h"


#pragma mark
@implementation NSString (BLTextAdditions)


#pragma mark - Cleaning Text

+ (NSString *)trimText:(NSString *)text
{
    //Sanity Check
    if (text.length > 0) {
        return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    
    //Invalid Cases
    return text;
}

- (NSString *)trimText
{
    return [NSString trimText:self];
}

+ (NSString *)cleanWhiteSpacesAndNewLineCharacters:(NSString *)text
{
    //Sanity Check
    if (text.length > 0) {
        return [[text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:@""];
    }
    
    //Invalid Cases
    return text;
}

- (NSString *)cleanWhiteSpacesAndNewLineCharacters
{
    return [NSString cleanWhiteSpacesAndNewLineCharacters:self];
}

+ (NSString *)cleanLetters:(NSString *)text
{
    //Sanity Check
    if (text.length > 0) {
        return [[text componentsSeparatedByCharactersInSet:[NSCharacterSet letterCharacterSet]] componentsJoinedByString:@""];
    }
    
    //Invalid Cases
    return text;
}

- (NSString *)cleanLetters
{
    return [NSString cleanLetters:self];
}

+ (NSString *)cleanPunctuation:(NSString *)text
{
    //Sanity Check
    if (text.length > 0) {
        return [[text componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]] componentsJoinedByString:@""];
    }
    
    //Invalid Cases
    return text;
}

- (NSString *)cleanPunctuation
{
    return [NSString cleanPunctuation:self];
}

+ (NSString *)cleanSymbols:(NSString *)text
{
    //Sanity Check
    if (text.length > 0) {
        return [[text componentsSeparatedByCharactersInSet:[NSCharacterSet symbolCharacterSet]] componentsJoinedByString:@""];
    }
    
    //Invalid Cases
    return text;
}

- (NSString *)cleanSymbols
{
    return [NSString cleanSymbols:self];
}

+ (NSString *)cleanNumbers:(NSString *)text
{
    //Sanity Check
    if (text.length > 0) {
        return [[text componentsSeparatedByCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]] componentsJoinedByString:@""];
    }
    
    //Invalid Cases
    return text;
}

- (NSString *)cleanNumbers
{
    return [NSString cleanNumbers:self];
}

+ (NSString *)cleanStringForFileSystem:(NSString *)text
{
    //Sanity Check
    if (text.length > 0) {
        text = [self cleanWhiteSpacesAndNewLineCharacters:text];
        text = [self cleanSymbols:text];
        if ([text rangeOfString:@"."].location != NSNotFound) {
            NSMutableArray *components = [[text componentsSeparatedByString:@"."] mutableCopy];
            NSString *type = [components lastObject];
            [components removeLastObject];
            NSString *result = [components componentsJoinedByString:@""];
            result = [self cleanPunctuation:result];
            return [NSString stringWithFormat:@"%@.%@",result,[self cleanPunctuation:type]];
        }
    }
    
    return text;
}

- (NSString *)cleanStringForFileSystem
{
    return [NSString cleanStringForFileSystem:self];
}


#pragma mark - General Checks

+ (BOOL)isLetter:(NSString *)string
{
    return ([[string componentsSeparatedByCharactersInSet:[NSCharacterSet letterCharacterSet]] count] == 0);
}

+ (BOOL)isNumber:(NSString *)string
{
    string = [[string componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]] componentsJoinedByString:@""];
    if (string.length > 0) {
        return ([[string componentsSeparatedByCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]] count] == 0);
    }
    return NO;
}

+ (BOOL)isSpaceCharacter:(NSString *)string
{
    return ([[string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] count] == 0);
}

+ (BOOL)isNewLineCharacter:(NSString *)string
{
    return ([[string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] count] == 0);
}

@end


#pragma mark -
@implementation NSString (BLTextValidation)


#pragma mark - Validating

+ (BOOL)isValidName:(NSString *)name
{
    name = [name cleanName];
    return (name.length > 0);
}

+ (BOOL)isValidEmail:(NSString *)email
{
    if (email.length > 0) {
        return [[NSPredicate predicateWithFormat:@"SELF MATCHES %@",@"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?"] evaluateWithObject:email];
    }
    return NO;
}

+ (BOOL)isValidPassword:(NSString *)password
{
    password = [password cleanWhiteSpacesAndNewLineCharacters];
    if (password.length > 0) {
        password = [[password componentsSeparatedByCharactersInSet:[NSCharacterSet URLPasswordAllowedCharacterSet]] componentsJoinedByString:@""];
        return (password.length == 0);
    }
    return NO;
}

+ (BOOL)isValidPhoneNumber:(NSString *)phoneNumber
{
#warning add locales
    phoneNumber = [phoneNumber cleanPhoneNumber];
    if (phoneNumber.length > 0) {
        if ([[[NSLocale currentLocale] localeIdentifier] rangeOfString:@"BR"
                                                               options:NSCaseInsensitiveSearch].location != NSNotFound)
        {
            return (phoneNumber.length >= 10 && phoneNumber.length <= 12);
        }
        return YES;
    }
    return NO;
}

+ (BOOL)isValidPostalCode:(NSString *)postalCode
{
#warning add locales
    postalCode = [postalCode cleanPostalCode];
    if (postalCode.length > 0) {
        if ([[[NSLocale currentLocale] localeIdentifier] rangeOfString:@"BR"
                                                               options:NSCaseInsensitiveSearch].location != NSNotFound)
        {
            return (postalCode.length == 8);
        }
        return YES;
    }
    return NO;
}

+ (BOOL)isValidCity:(NSString *)city
{
    city = [city cleanCity];
    if (city.length > 0) {
        return YES;
    }
    return NO;
}

+ (BOOL)isValidState:(NSString *)state
{
    state = [state cleanState];
    if (state.length > 0) {
        return YES;
    }
    return NO;
}


#pragma mark - Cleaning Text

- (NSString *)cleanName
{
    NSString *result = [self cleanWhiteSpacesAndNewLineCharacters];
    result = [result cleanPunctuation];
    result = [result cleanSymbols];
    result = [result cleanNumbers];
    return result;
}

- (NSString *)cleanEmail
{
    return [self trimText];
}

- (NSString *)cleanPassword
{
    return [self trimText];
}

- (NSString *)cleanPhoneNumber
{
    NSString *result = [self trimText];
    result = [result cleanWhiteSpacesAndNewLineCharacters];
    result = [result cleanLetters];
    result = [result cleanPunctuation];
    result = [result cleanSymbols];
    return result;
}

- (NSString *)cleanPostalCode
{
    return [self cleanPhoneNumber];
}

- (NSString *)cleanState
{
    NSString *result = [self cleanName];
    return [result uppercaseString];
}

- (NSString *)cleanCity
{
    return [self cleanName];
}

@end


#pragma mark -
@implementation NSString (BLTextFormatting)


#pragma mark - Phone Number

+ (NSString *)formattedPhoneNumber:(NSString *)text
{
#warning add locales
    NSString *tempString = [text cleanPhoneNumber];
    if (tempString.length == 0) return @"";
    
    NSString *result = @"";
    if ([[[NSLocale currentLocale] localeIdentifier] rangeOfString:@"UK"
                                                           options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        if (tempString.length == 0 || ![[tempString substringToIndex:1] isEqualToString:@"0"])
            tempString = [NSString stringWithFormat:@"0%@",tempString];
        if (tempString.length <= 8)
        {
            if (tempString.length > 4) {
                result = [NSString stringWithFormat:@"%@ %@",[tempString substringToIndex:4],[tempString substringFromIndex:4]];
            } else {
                result = tempString;
            }
        }
        else if (tempString.length <= 10)
        {
            if (![[tempString substringToIndex:2] isEqualToString:@"01"]) {
                result = [NSString stringWithFormat:@"%@ %@",[tempString substringToIndex:4],[tempString substringFromIndex:4]];
            } else if ([[tempString substringToIndex:6] isEqualToString:@"016977"]) {
                result = [NSString stringWithFormat:@"(%@) %@",[tempString substringToIndex:6],[tempString substringFromIndex:6]];
            } else {
                result = [NSString stringWithFormat:@"(%@) %@",[tempString substringToIndex:5],[tempString substringFromIndex:5]];
            }
        }
        else
        {
            if ([[tempString substringToIndex:2] isEqualToString:@"01"])
            {
                result = [NSString stringWithFormat:@"(%@) %@",[tempString substringToIndex:5],[tempString substringFromIndex:5]];
            }
            else if ([[tempString substringToIndex:2] isEqualToString:@"02"])
            {
                NSString *subString = [tempString substringFromIndex:3];
                NSString *finalString = [subString substringFromIndex:4];
                result = [NSString stringWithFormat:@"(%@) %@ %@",[tempString substringToIndex:3],[subString substringToIndex:3],finalString];
            }
            else if ([[tempString substringToIndex:2] isEqualToString:@"05"] ||
                     [[tempString substringToIndex:2] isEqualToString:@"07"])
            {
                NSString *subString = [tempString substringFromIndex:3];
                NSString *finalString = [subString substringFromIndex:4];
                result = [NSString stringWithFormat:@"%@ %@ %@",[tempString substringToIndex:3],[subString substringToIndex:3],finalString];
            }
            else
            {
                NSString *subString = [tempString substringFromIndex:4];
                NSString *finalString = [subString substringFromIndex:3];
                result = [NSString stringWithFormat:@"%@ %@ %@",[tempString substringToIndex:4],[subString substringToIndex:3],finalString];
            }
        }
    }
    else if ([[[NSLocale currentLocale] localeIdentifier] rangeOfString:@"BR"
                                                                options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        if (tempString.length == 0 || ![[tempString substringToIndex:1] isEqualToString:@"0"])
            tempString = [NSString stringWithFormat:@"0%@",tempString];
        if (tempString.length <= 5) {
            result = [NSString stringWithFormat:@"(%@)",tempString];
        }
        else if (tempString.length <= 7)
        {
            result = [NSString stringWithFormat:@"(%@) %@",[tempString substringToIndex:3],[tempString substringFromIndex:3]];
        }
        else if (tempString.length < 11)
        {
            NSRange range = {3,3};
            result = [NSString stringWithFormat:@"(%@) %@-%@",[tempString substringToIndex:3],[tempString substringWithRange:range],[tempString substringFromIndex:6]];
        }
        else if (tempString.length == 11)
        {
            NSRange range = {3,4};
            result = [NSString stringWithFormat:@"(%@) %@-%@",[tempString substringToIndex:3],[tempString substringWithRange:range],[tempString substringFromIndex:7]];
        }
        else if (tempString.length <= 12)
        {
            NSRange range = {3,5};
            result = [NSString stringWithFormat:@"(%@) %@-%@",[tempString substringToIndex:3],[tempString substringWithRange:range],[tempString substringFromIndex:8]];
        }
        else if (tempString.length <= 13)
        {
            NSRange range = {5,4};
            result = [NSString stringWithFormat:@"(%@) %@-%@",[tempString substringToIndex:5],[tempString substringWithRange:range],[tempString substringFromIndex:9]];
        }
        else
        {
            NSString *subString = [tempString substringFromIndex:5];
            NSString *finalString = [subString substringFromIndex:5];
            result = [NSString stringWithFormat:@"(%@) %@-%@",[tempString substringToIndex:5],[subString substringToIndex:5],[finalString substringToIndex:4]];
        }
    }
    else if ([[[NSLocale currentLocale] localeIdentifier] rangeOfString:@"PT"
                                                                options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        if (tempString.length <= 3)
        {
            result = tempString;
        }
        else if (tempString.length <= 6)
        {
            result = [NSString stringWithFormat:@"%@ %@",[tempString substringToIndex:3],[tempString substringFromIndex:3]];
        }
        else
        {
            NSString *subString = [tempString substringFromIndex:3];
            NSString *finalString = [subString substringFromIndex:3];
            result = [NSString stringWithFormat:@"%@ %@ %@",[tempString substringToIndex:3],[subString substringToIndex:3],finalString];
        }
    }
    else
    {
        //Defaults to US format
        if (tempString.length <= 3)
        {
            result = [NSString stringWithFormat:@"(%@)",tempString];
        }
        else if (tempString.length <= 6)
        {
            result = [NSString stringWithFormat:@"(%@) %@",[tempString substringToIndex:3],[tempString substringFromIndex:3]];
        }
        else
        {
            NSString *subString = [tempString substringFromIndex:3];
            NSString *finalString = [subString substringFromIndex:3];
            result = [NSString stringWithFormat:@"(%@) %@-%@",[tempString substringToIndex:3],[subString substringToIndex:3],finalString];
        }
    }
    return result;
}

- (NSString *)formattedPhoneNumber
{
    return [NSString formattedPhoneNumber:self];
}

#pragma mark - Postal Code

+ (NSString *)formattedPostalCode:(NSString *)text
{
#warning add locales
    NSString *tempString = [text cleanPostalCode];
    if (tempString.length == 0) return @"";
    
    NSString *result = @"";
    if (tempString.length <= 5) {
        result = [NSString stringWithFormat:@"%@",tempString];
    }
    else if (tempString.length <= 8)
    {
        result = [NSString stringWithFormat:@"%@-%@",[tempString substringToIndex:5],[tempString substringFromIndex:5]];
    }
    else
    {
        result = [NSString stringWithFormat:@"%@-%@",[tempString substringToIndex:5],[[tempString substringFromIndex:5] substringToIndex:3]];
    }
    return result;
}

- (NSString *)formattedPostalCode
{
    return [NSString formattedPostalCode:self];
}

@end
