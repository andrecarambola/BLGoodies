//
//  BLTextViewController.m
//  Text
//
//  Created by André Abou Chami Campana on 23/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLTextViewController.h"

#ifndef kBLTextDefaultInputAccessoryViewHeight
#define kBLTextDefaultInputAccessoryViewHeight 30.f
#endif


#pragma mark - Private Interface
@interface BLTextViewController ()
{
    BOOL isShowingKeyboard;
}

//Notifications
- (void)handleKeyboardWillAppearNotification:(NSNotification *)notification;
- (void)handleKeyboardWillHideNotification:(NSNotification *)notification;

//Keyboard Handling
- (UIView *)defaultInputAccessoryView;
- (UITextField *)nextTextFieldForTextField:(UITextField *)textField;
- (void)keyboardOkPressed:(UIBarButtonItem *)sender;

//UI Elements
@property (nonatomic, weak) UITextField *activeTextField;

@end


#pragma mark - Implementation
@implementation BLTextViewController


#pragma mark - Setup

- (BOOL)isKeyboardViewController
{
    return (self.keyboardScrollView != nil && self.allTextFields.count > 0);
}

- (void)setup
{
    [super setup];
    _useForms = NO;
    _keyboardEnabled = YES;
    _editingText = NO;
    isShowingKeyboard = NO;
}


#pragma mark - States

- (void)setKeyboardEnabled:(BOOL)keyboardEnabled
{
    if (_keyboardEnabled != keyboardEnabled || !keyboardEnabled) {
        [self willChangeValueForKey:@"keyboardEnabled"];
        
        for (UITextField *textField in self.allTextFields) {
            [textField setEnabled:keyboardEnabled];
        }
        
        _keyboardEnabled = keyboardEnabled;
        [self didChangeValueForKey:@"keyboardEnabled"];
    }
}

- (void)setEditingText:(BOOL)editingText
{
    if (_editingText != editingText || !editingText) {
        [self willChangeValueForKey:@"editingText"];
        
        if (editingText) {
            UITextField *firstTextField = [self.allTextFields firstObject];
            [firstTextField becomeFirstResponder];
        } else {
            BOOL shouldUseForm = self.shouldUseForms;
            [self setUseForms:NO];
            [self.activeTextField resignFirstResponder];
            [self setUseForms:shouldUseForm];
        }
        
        _editingText = editingText;
        [self didChangeValueForKey:@"editingText"];
    }
}


#pragma mark - Forms

//- (UITextField *)nextTextFieldForTextField:(UITextField *)element
//{
//    return nil;
//}

- (void)storeValidatedTextForTextField:(UITextField *)element
{
    return;
}


#pragma mark - View Controller Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.isKeyboardViewController) {
        NSArray *orderedTextFields = [self.allTextFields sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
        {
            UITextField *firstTextField = obj1;
            UITextField *secondTextField = obj2;
            if (firstTextField.tag > secondTextField.tag) return (NSComparisonResult)NSOrderedDescending;
            if (firstTextField.tag < secondTextField.tag) return (NSComparisonResult)NSOrderedAscending;
            return (NSComparisonResult)NSOrderedSame;
        }];
        [self setAllTextFields:orderedTextFields];
        NSArray *orderedValidationViews = [self.allTextValidationViews sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
        {
            UIView *firstTextField = obj1;
            UIView *secondTextField = obj2;
            if (firstTextField.tag > secondTextField.tag) return (NSComparisonResult)NSOrderedDescending;
            if (firstTextField.tag < secondTextField.tag) return (NSComparisonResult)NSOrderedAscending;
            return (NSComparisonResult)NSOrderedSame;
        }];
        [self setAllTextValidationViews:orderedValidationViews];
        for (UITextField *textField in self.allTextFields) {
            for (UIView *validationView in self.allTextValidationViews) {
                if (textField.tag == validationView.tag) {
                    [textField setRightView:validationView];
                }
            }
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.isKeyboardViewController) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleKeyboardWillAppearNotification:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleKeyboardWillHideNotification:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self setEditingText:NO];
    if (self.isKeyboardViewController) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIKeyboardWillShowNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIKeyboardWillHideNotification
                                                      object:nil];
    }
    
    [super viewWillDisappear:animated];
}


#pragma mark - Notifications

- (void)handleKeyboardWillAppearNotification:(NSNotification *)notification
{
    if (isShowingKeyboard) return;
    isShowingKeyboard = YES;
    
    if (notification &&
        self.keyboardScrollView.frame.size.height == self.view.frame.size.height)
    {
        //Keyboard size
        CGRect kbRect;
        NSDictionary *info = [notification userInfo];
        kbRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        kbRect.size.height += kBLTextDefaultInputAccessoryViewHeight + 4.f;
        kbRect.origin.y -= kBLTextDefaultInputAccessoryViewHeight + 4.f;
        
        [self.keyboardScrollView setFrame:CGRectMake(self.keyboardScrollView.frame.origin.x,
                                                     self.keyboardScrollView.frame.origin.y,
                                                     self.keyboardScrollView.frame.size.width,
                                                     self.keyboardScrollView.frame.size.height - kbRect.size.height)];
    }
    
    [self.keyboardScrollView scrollRectToVisible:self.activeTextField.frame
                                        animated:YES];
}

- (void)handleKeyboardWillHideNotification:(NSNotification *)notification
{
    if (!isShowingKeyboard) return;
    isShowingKeyboard = NO;
    
    [self.keyboardScrollView setFrame:self.view.frame];
    [self.keyboardScrollView setContentOffset:CGPointZero
                                     animated:YES];
}


#pragma mark - Text Field Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string
{
    if (self.isKeyboardViewController &&
        self.activeTextField &&
        [self.activeTextField isKindOfClass:[BLTextField class]])
    {
        //Deleting Text
        if (string.length == 0) {
            [textField setText:[textField.text substringToIndex:textField.text.length - 1]];
            return NO;
        }
        
        BLTextField *tempTextField = (BLTextField *)self.activeTextField;
        
        //Checking Max Number of Characters
        if (textField.text.length == tempTextField.maxNumberOfCharacters)
        {
            return NO;
        }
        else
        {
            BOOL appendString = NO;
            if ([textField isKindOfClass:[BLPhoneNumberTextField class]] &&
                [NSString isNumber:string])
            {
                appendString = YES;
            }
            else if ([textField isKindOfClass:[BLPostalCodeTextField class]] &&
                     [NSString isNumber:string])
            {
                appendString = YES;
            }
            else if ([textField isKindOfClass:[BLNameTextField class]] &&
                     [NSString isLetter:string])
            {
                appendString = YES;
            }
            else if ([textField isKindOfClass:[BLPasswordTextField class]] &&
                     ![NSString isNewLineCharacter:string] &&
                     ![NSString isSpaceCharacter:string])
            {
                appendString = YES;
            }
            else if ([textField isKindOfClass:[BLStateTextField class]] &&
                     [NSString isLetter:string])
            {
                appendString = YES;
            }
            else if ([textField isKindOfClass:[BLCityTextField class]] &&
                     [NSString isLetter:string])
            {
                appendString = YES;
            }
            if (appendString) {
                [textField setText:[textField.text stringByAppendingString:string]];
                return NO;
            }
        }
    }
    
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if ([self isKeyboardViewController])
    {
        //Setting an accessory view to the keyboard if needed
        BOOL shouldIncludeAccessoryView = NO;
        switch ([textField keyboardType]) {
            case UIKeyboardTypeNumberPad:
                shouldIncludeAccessoryView = YES;
                break;
            case UIKeyboardTypePhonePad:
                shouldIncludeAccessoryView = YES;
                break;
            case UIKeyboardTypeDecimalPad:
                shouldIncludeAccessoryView = YES;
                break;
            default:
                break;
        }
        [textField setInputAccessoryView:(shouldIncludeAccessoryView) ? [self defaultInputAccessoryView] : nil];
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ([self isKeyboardViewController]) {
        self.activeTextField = textField;
        if ([textField isKindOfClass:[BLTextField class]]) {
            [(BLTextField *)self.activeTextField setIsValid:YES];
        }
        
        [self.keyboardScrollView scrollRectToVisible:textField.frame
                                            animated:YES];
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (self.isKeyboardViewController) {
        if ([self.activeTextField isKindOfClass:[BLTextField class]]) [(BLTextField *)self.activeTextField checkValidText];
    }
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (self.isKeyboardViewController)
    {
        [self storeValidatedTextForTextField:self.activeTextField];
        if (self.useForms) {
            UITextField *nextTextField = [self nextTextFieldForTextField:self.activeTextField];
            if (nextTextField) [nextTextField becomeFirstResponder];
        }
    }
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.activeTextField resignFirstResponder];
    
    return YES;
}


#pragma mark - Keyboard Handling

- (UIView *)defaultInputAccessoryView
{
    UIToolbar *okToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.f,
                                                                       0.f,
                                                                       self.view.frame.size.width,
                                                                       kBLTextDefaultInputAccessoryViewHeight)];
    UIBarButtonItem *separator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                               target:nil
                                                                               action:NULL];
    UIBarButtonItem *okButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Ok", NULL)
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(keyboardOkPressed:)];
    [okToolbar setItems:@[separator, okButton]];
    return okToolbar;
}

- (UITextField *)nextTextFieldForTextField:(UITextField *)textField
{
    if (!self.shouldUseForms) return nil;
    for (UITextField *tempTextField in self.allTextFields) {
        if (tempTextField.tag > textField.tag) {
            return tempTextField;
        }
    }
    return nil;
}

- (void)keyboardOkPressed:(UIBarButtonItem *)sender
{
    [self.activeTextField resignFirstResponder];
}

@end
