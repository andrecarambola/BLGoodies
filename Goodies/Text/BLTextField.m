//
//  BLTextField.m
//  Text
//
//  Created by André Abou Chami Campana on 24/05/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLTextField.h"


@interface BLTextField ()
{
    BOOL _isInitializing;
}

@end


@implementation BLTextField

#pragma mark - Setup

- (id)init
{
    _isInitializing = YES;
    if (self = [super init]) [self setup];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    _isInitializing = YES;
    if (self = [super initWithCoder:aDecoder]) [self setup];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    _isInitializing = YES;
    if (self = [super initWithFrame:frame]) [self setup];
    return self;
}

- (void)setup
{
    //Initial State
    [self setEnabled:YES];
    
    //Validation
    _isValid = YES;
    _maxNumberOfCharacters = NSIntegerMax;
    _minNumberOfCharacters = 0;
    [self setRightViewMode:UITextFieldViewModeNever];
    
    _isInitializing = NO;
}


#pragma mark - Validation

- (void)setIsValid:(BOOL)isValid
{
    [self willChangeValueForKey:@"isValid"];
    _isValid = isValid;
    if (!_isInitializing) [self setRightViewMode:(isValid) ? UITextFieldViewModeNever : UITextFieldViewModeUnlessEditing];
    [self didChangeValueForKey:@"isValid"];
}

- (void)checkValidText
{
    [self setIsValid:(self.text.length >= self.minNumberOfCharacters &&
                      self.text.length <= self.maxNumberOfCharacters)];
}


#pragma mark - KVO

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    if ([key isEqualToString:@"isValid"]) 
    {
        return NO;
    }
    return [super automaticallyNotifiesObserversForKey:key];
}

@end
