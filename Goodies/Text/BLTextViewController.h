//
//  BLTextViewController.h
//  Text
//
//  Created by André Abou Chami Campana on 23/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLViewController.h"
//Text Fields
#import "BLNameTextField.h"
#import "BLEmailTextField.h"
#import "BLPasswordTextField.h"
#import "BLPhoneNumberTextField.h"
#import "BLPostalCodeTextField.h"
#import "BLCityTextField.h"
#import "BLStateTextField.h"


@interface BLTextViewController : BLViewController <UITextFieldDelegate>

//Setup
- (BOOL)isKeyboardViewController;
@property (nonatomic, getter = shouldUseForms) BOOL useForms;

//States
@property (nonatomic, getter = isKeyboardEnabled) BOOL keyboardEnabled;
@property (nonatomic, getter = isEditingText) BOOL editingText;

//UI Elements
@property (nonatomic, weak) IBOutlet UIScrollView *keyboardScrollView;
@property (nonatomic, strong) IBOutletCollection(UITextField) NSArray *allTextFields;
@property (nonatomic, strong) IBOutletCollection(UIView) NSArray *allTextValidationViews;

//UI Actions
//- (IBAction)nextTextField:(id)sender;
//- (IBAction)previousTextField:(id)sender;
- (void)storeValidatedTextForTextField:(UITextField *)element;

@end
