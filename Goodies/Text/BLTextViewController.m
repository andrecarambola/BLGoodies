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
    BOOL isJumpingThroughForm;
    CGRect originalScrollViewRect;
}

//Setup
- (BOOL)isKeyboardViewController;
- (void)organizeCollections;

//Notifications
- (void)handleKeyboardWillAppearNotification:(NSNotification *)notification;
- (void)handleKeyboardWillHideNotification:(NSNotification *)notification;

//Keyboard Handling
- (UIView *)defaultInputAccessoryView;
- (id)nextTextElementForTextElement:(id)textField;
- (void)handleNextTextElement;
- (void)keyboardOkPressed:(UIBarButtonItem *)sender;

//UI Elements
@property (nonatomic, weak) UITextField *activeTextField;
@property (nonatomic, weak) UITextView *activeTextView;
- (id)activeTextElement;
- (void)setActiveTextElement:(id)textElement;
@property (nonatomic, strong) NSArray *allTextElements;

@end


#pragma mark - Implementation
@implementation BLTextViewController


#pragma mark - Setup

- (BOOL)isKeyboardViewController
{
    return (self.allTextFields.count > 0 || self.allTextViews.count > 0);
}

- (void)setup
{
    [super setup];
    _useForms = NO;
    _keyboardEnabled = YES;
    _editingText = NO;
    isShowingKeyboard = NO;
    isJumpingThroughForm = NO;
    originalScrollViewRect = CGRectZero;
}

- (void)organizeCollections
{
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
    NSArray *orderedTextViews = [self.allTextViews sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
                                 {
                                     UITextView *firstTextField = obj1;
                                     UITextView *secondTextField = obj2;
                                     if (firstTextField.tag > secondTextField.tag) return (NSComparisonResult)NSOrderedDescending;
                                     if (firstTextField.tag < secondTextField.tag) return (NSComparisonResult)NSOrderedAscending;
                                     return (NSComparisonResult)NSOrderedSame;
                                 }];
    [self setAllTextViews:orderedTextViews];
    
    NSMutableArray *tempTextElements = [NSMutableArray arrayWithCapacity:self.allTextFields.count + self.allTextViews.count];
    if (self.allTextFields.count > 0) [tempTextElements addObjectsFromArray:self.allTextFields];
    if (self.allTextViews.count > 0) [tempTextElements addObjectsFromArray:self.allTextViews];
    NSArray *orderedTextElements = [tempTextElements sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
                                    {
                                        if ([obj1 tag] > [obj2 tag]) return (NSComparisonResult)NSOrderedDescending;
                                        if ([obj1 tag] < [obj2 tag]) return (NSComparisonResult)NSOrderedAscending;
                                        return (NSComparisonResult)NSOrderedSame;
                                    }];
    [self setAllTextElements:orderedTextElements];
    
    [self.keyboardScrollView setClipsToBounds:NO];
    [self.keyboardScrollView setAutoresizesSubviews:NO];
}


#pragma mark - States

- (void)setKeyboardEnabled:(BOOL)keyboardEnabled
{
    if (_keyboardEnabled != keyboardEnabled || !keyboardEnabled) {
        [self willChangeValueForKey:@"keyboardEnabled"];
        
        for (UITextField *textField in self.allTextFields) {
            [textField setEnabled:keyboardEnabled];
        }
        for (UITextView *textView in self.allTextViews) {
            [textView setEditable:keyboardEnabled];
        }
        
        _keyboardEnabled = keyboardEnabled;
        [self didChangeValueForKey:@"keyboardEnabled"];
    }
}

- (void)setEditingText:(BOOL)editingText
{
    if (_editingText != editingText || !editingText) {
        [self willChangeValueForKey:@"editingText"];
        
        if (self.isKeyboardViewController) {
            if (editingText) {
                if (!self.activeTextElement) {
                    id firstTextElement = [self.allTextElements firstObject];
                    [firstTextElement becomeFirstResponder];
                }
            } else {
                BOOL shouldUseForm = self.shouldUseForms;
                [self setUseForms:NO];
                [self.activeTextElement resignFirstResponder];
                [self setUseForms:shouldUseForm];
            }
        }
        
        _editingText = editingText;
        [self didChangeValueForKey:@"editingText"];
    }
}


#pragma mark - UI Actions

- (void)addTextElements:(NSArray *)textElements
{
    if (textElements.count == 0) return;
    BOOL didAdd = NO;
    NSMutableArray *textFields = (self.allTextFields.count > 0) ? [NSMutableArray arrayWithArray:self.allTextFields] : [NSMutableArray array];
    NSMutableArray *textViews = (self.allTextViews.count > 0) ? [NSMutableArray arrayWithArray:self.allTextViews] : [NSMutableArray array];
    for (id element in textElements) {
        if ([element isKindOfClass:[UITextField class]]) {
            didAdd = YES;
            [textFields addObject:element];
        } else if ([element isKindOfClass:[UITextView class]]) {
            didAdd = YES;
            [textViews addObject:textViews];
        }
    }
    if (didAdd) {
        [self setAllTextFields:[NSArray arrayWithArray:textFields]];
        [self setAllTextViews:[NSArray arrayWithArray:textViews]];
        [self organizeCollections];
    }
}

- (void)storeValidatedTextForTextElement:(id)element
{
    return;
}


#pragma mark - View Controller Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.isKeyboardViewController) {
        [self organizeCollections];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.isKeyboardViewController && self.keyboardScrollView) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleKeyboardWillAppearNotification:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleKeyboardWillHideNotification:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
        [self.keyboardScrollView setContentSize:CGSizeMake(self.keyboardScrollView.frame.size.width, 
                                                           self.keyboardScrollView.frame.size.height)];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self setEditingText:NO];
    if (self.isKeyboardViewController && self.keyboardScrollView) {
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
    if (isShowingKeyboard || isJumpingThroughForm) return;
    isShowingKeyboard = YES;
    __weak BLTextViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf handleKeyboardStateChange:YES];
    });
    
    if (self.keyboardScrollView &&
        notification &&
        self.keyboardScrollView.frame.size.height == self.view.frame.size.height)
    {
        originalScrollViewRect = self.keyboardScrollView.frame;
        
        //Keyboard size
        CGRect kbRect;
        NSDictionary *info = [notification userInfo];
        kbRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
//        kbRect.size.height += kBLTextDefaultInputAccessoryViewHeight + 4.f;
//        kbRect.origin.y -= kBLTextDefaultInputAccessoryViewHeight + 4.f;
        
        [self.keyboardScrollView setFrame:CGRectMake(self.keyboardScrollView.frame.origin.x,
                                                     self.keyboardScrollView.frame.origin.y,
                                                     self.keyboardScrollView.frame.size.width,
                                                     self.keyboardScrollView.frame.size.height - kbRect.size.height)];
    }
    
    [self.keyboardScrollView scrollRectToVisible:[self.activeTextElement frame]
                                        animated:YES];
}

- (void)handleKeyboardWillHideNotification:(NSNotification *)notification
{
    if (!isShowingKeyboard || isJumpingThroughForm) return;
    isShowingKeyboard = NO;
    __weak BLTextViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf handleKeyboardStateChange:NO];
    });
    
    [self.keyboardScrollView setFrame:originalScrollViewRect];
    originalScrollViewRect = CGRectZero;
}


#pragma mark - UI Elements

- (id)activeTextElement
{
    if (self.activeTextField) return self.activeTextField;
    return self.activeTextView;
}

- (void)setActiveTextElement:(id)textElement
{
    self.activeTextField = nil;
    self.activeTextView = nil;
    
    if (textElement) {
        if ([textElement isKindOfClass:[UITextField class]]) {
            self.activeTextField = textElement;
        } else if ([textElement isKindOfClass:[UITextView class]]) {
            self.activeTextView = textElement;
        }
        [self setEditingText:YES];
    } else {
        [self setEditingText:NO];
    }
    
    isJumpingThroughForm = NO;
}


#pragma mark - Text Field Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string
{
    if (self.isKeyboardViewController &&
        self.activeTextField &&
        [self.activeTextField isKindOfClass:[BLTextField class]])
    {
        BLTextField *tempTextField = (BLTextField *)self.activeTextField;
        
        //Deleting Text
        if (string.length == 0) {
            if ([tempTextField isKindOfClass:[BLPhoneNumberTextField class]] &&
                [[textField.text substringFromIndex:textField.text.length - 1] isEqualToString:@")"]) 
            {
                [textField setText:[textField.text substringToIndex:textField.text.length - 2]];
            }
            else
            {
                [textField setText:[textField.text substringToIndex:textField.text.length - 1]];
            }
            [tempTextField formatText];
            return NO;
        }
        
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
            else if ([textField isKindOfClass:[BLCPFTextField class]] &&
                     [NSString isNumber:string])
            {
                appendString = YES;
            }
            if (appendString) {
                [textField setText:[textField.text stringByAppendingString:string]];
                [tempTextField formatText];
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
        [self setActiveTextElement:textField];
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
        if (self.shouldUseForms && 
            [self nextTextElementForTextElement:self.activeTextElement])
        {
            isJumpingThroughForm = YES;
        }
    }
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (self.isKeyboardViewController)
    {
        [self storeValidatedTextForTextElement:self.activeTextField];
        [self handleNextTextElement];
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


#pragma mark - Text View Delegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if ([self isKeyboardViewController])
    {
        [textView setInputAccessoryView:[self defaultInputAccessoryView]];
    }
    
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([self isKeyboardViewController]) {
        [self setActiveTextElement:textView];
        
        [self.keyboardScrollView scrollRectToVisible:textView.frame
                                            animated:YES];
    }
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    if (self.shouldUseForms && 
        [self nextTextElementForTextElement:self.activeTextElement])
    {
        isJumpingThroughForm = YES;
    }
    
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (self.isKeyboardViewController)
    {
        [self storeValidatedTextForTextElement:self.activeTextView];
        [self handleNextTextElement];
    }
}


#pragma mark - Keyboard Handling

- (void)handleKeyboardStateChange:(BOOL)isShowingKeyboard
{
    return;
}

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

- (id)nextTextElementForTextElement:(id)textField
{
    if (!self.shouldUseForms) return nil;
    
    NSInteger index = [self.allTextElements indexOfObject:textField] + 1;
    id result = (index < self.allTextElements.count) ? [self.allTextElements objectAtIndex:index] : nil;
    return result;
}

- (void)handleNextTextElement
{
    if (self.useForms) {
        id nextTextElement = [self nextTextElementForTextElement:self.activeTextElement];
        if (nextTextElement) {
            [nextTextElement becomeFirstResponder];
            return;
        }
    }
    [self setActiveTextElement:nil];
}

- (void)keyboardOkPressed:(UIBarButtonItem *)sender
{
    [self.activeTextElement resignFirstResponder];
}


#pragma mark - KVO

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    if ([key isEqualToString:@"keyboardEnabled"] || 
        [key isEqualToString:@"editingText"]) 
    {
        return NO;
    }
    return [super automaticallyNotifiesObserversForKey:key];
}

@end
