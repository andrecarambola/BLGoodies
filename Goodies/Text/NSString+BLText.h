//
//  NSString+BLText.h
//  Text
//
//  Created by André Abou Chami Campana on 24/05/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (BLTextAdditions)

//Cleaning Text
+ (NSString *)trimText:(NSString *)text;
- (NSString *)trimText;
+ (NSString *)cleanWhiteSpaces:(NSString *)text;
- (NSString *)cleanWhiteSpaces;
+ (NSString *)cleanNewLineCharacters:(NSString *)text;
- (NSString *)cleanNewLineCharacters;
+ (NSString *)cleanWhiteSpacesAndNewLineCharacters:(NSString *)text;
- (NSString *)cleanWhiteSpacesAndNewLineCharacters;
+ (NSString *)cleanLetters:(NSString *)text;
- (NSString *)cleanLetters;
+ (NSString *)cleanPunctuation:(NSString *)text;
- (NSString *)cleanPunctuation;
+ (NSString *)cleanSymbols:(NSString *)text;
- (NSString *)cleanSymbols;
+ (NSString *)cleanNumbers:(NSString *)text;
- (NSString *)cleanNumbers;
+ (NSString *)cleanStringForFileSystem:(NSString *)text;
- (NSString *)cleanStringForFileSystem;
+ (NSString *)cleanHTMLTags:(NSString *)text;
- (NSString *)cleanHTMLTags;

//General Checks
+ (BOOL)isLetter:(NSString *)string;
+ (BOOL)isNumber:(NSString *)string;
+ (BOOL)isSpaceCharacter:(NSString *)string;
+ (BOOL)isNewLineCharacter:(NSString *)string;

@end


@interface NSString (BLTextValidation)

//Validating
+ (BOOL)isValidName:(NSString *)name;
+ (BOOL)isValidEmail:(NSString *)email;
+ (BOOL)isValidPassword:(NSString *)password;
+ (BOOL)isValidPhoneNumber:(NSString *)phoneNumber;
+ (BOOL)isValidPostalCode:(NSString *)postalCode;
+ (BOOL)isValidCity:(NSString *)city;
+ (BOOL)isValidState:(NSString *)state;
+ (BOOL)isValidCPF:(NSString *)cpf;

//Cleaning Text
- (NSString *)cleanName;
- (NSString *)cleanEmail;
- (NSString *)cleanPassword;
- (NSString *)cleanPhoneNumber;
- (NSString *)cleanPostalCode;
- (NSString *)cleanCity;
- (NSString *)cleanState;
- (NSString *)cleanCPF;

@end


@interface NSString (BLTextFormatting)

//Phone Number
+ (NSString *)formattedPhoneNumber:(NSString *)text;
- (NSString *)formattedPhoneNumber;

//Postal Code
+ (NSString *)formattedPostalCode:(NSString *)text;
- (NSString *)formattedPostalCode;

//CPF
+ (NSString *)formattedCPF:(NSString *)cpf;
- (NSString *)formattedCPF;

@end
