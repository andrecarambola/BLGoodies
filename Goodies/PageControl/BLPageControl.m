//
//  BLPageControl.m
//  PageControl
//
//  Created by André Abou Chami Campana on 13/06/14.
//  Copyright (c) 2014 BaffiLab. All rights reserved.
//

#import "BLPageControl.h"


@interface BLPageControl ()
{
    BOOL _isInitializing;
}

//Setup
- (void)setup;

//Images
@property (nonatomic, strong) NSMutableDictionary *imagesDictionary;
@property (nonatomic, strong) NSMutableArray *imageViews;
- (UIImageView *)createImageViewAtYPosition:(CGFloat)yPosition;

//UI Elements
@property (nonatomic, weak) UIView *imageViewsContainer;
@property (nonatomic, strong) NSMutableArray *touchViews;
- (void)checkTouchViews;

//UI Actions
- (void)leftPageChangeTapped:(UITapGestureRecognizer *)tap;
- (void)rightPageChangeTapped:(UITapGestureRecognizer *)tap;

@end


@implementation BLPageControl

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
    _numberOfPages = 0;
    _currentPage = 0;
    _imagesDictionary = [NSMutableDictionary dictionary];
    _imageViews = [NSMutableArray array];
    _touchViews = [NSMutableArray array];
    _hidesForSinglePage = YES;
    [self setOpaque:YES];
    [self setBackgroundColor:[UIColor clearColor]];
    
#warning set default images
    
    _isInitializing = NO;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    if (!_isInitializing) {
        [self setNumberOfPages:self.numberOfPages];
    }
}


#pragma mark - Page Navigation

- (void)setNumberOfPages:(NSInteger)numberOfPages
{
    [self willChangeValueForKey:@"numberOfPages"];
    if (!_isInitializing) {
        int threshold = (_hidesForSinglePage) ? 1 : 0;
        if (numberOfPages <= threshold) {
            [self setImageViewsContainer:nil];
        } else {
            CGRect containerRect = CGRectMake(0.f,
                                              0.f,
                                              0.f,
                                              self.frame.size.height);
            CGFloat yPosition = 0.f;
            for (int i=0; i<numberOfPages; ++i) {
                UIImageView *imageView = [self createImageViewAtYPosition:yPosition];
                yPosition += imageView.frame.size.width;
                [self.imageViews addObject:imageView];
                containerRect.size.width += imageView.frame.size.width;
            }
            containerRect.origin.y = (self.frame.size.width / 2.f) - (containerRect.size.width / 2.f);
            UIView *containerView = [[UIView alloc] initWithFrame:containerRect];
            [self setImageViewsContainer:containerView];
        }
        [self checkTouchViews];
    }
    _numberOfPages = numberOfPages;
    [self didChangeValueForKey:@"numberOfPages"];
}

- (void)setCurrentPage:(NSInteger)currentPage
{
    if (currentPage < 0 || currentPage >= self.imageViews.count) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"%@: currentPage out of bounds",NSStringFromClass([BLPageControl class])];
        return;
    }
    
    [self willChangeValueForKey:@"currentPage"];
    if (!_isInitializing) {
        UIImageView *imageView = [self.imageViews objectAtIndex:currentPage];
        for (UIImageView *tempImageView in self.imageViews) {
            [tempImageView setHighlighted:(tempImageView == imageView)];
        }
    }
    _currentPage = currentPage;
    [self didChangeValueForKey:@"currentPage"];
}

- (void)setHidesForSinglePage:(BOOL)hidesForSinglePage
{
    [self willChangeValueForKey:@"hidesForSinglePage"];
    _hidesForSinglePage = hidesForSinglePage;
    [self setNumberOfPages:self.numberOfPages];
    
    [self didChangeValueForKey:@"hidesForSinglePage"];
}


#pragma mark - Updating the Page Display

- (UIImage *)imageForPageState:(UIControlState)pageState
{
    UIImage *result = [self.imagesDictionary objectForKey:@(pageState)];
    return result;
}

- (void)setImage:(UIImage *)image
    forPageState:(UIControlState)pageState
{
    if (!image) {
        [self.imagesDictionary removeObjectForKey:@(pageState)];
        return;
    }
    [self.imagesDictionary setObject:image
                              forKey:@(pageState)];
    for (UIImageView *imageView in self.imageViews) {
        if (pageState == UIControlStateNormal) {
            [imageView setImage:image];
        } else if (pageState == UIControlStateHighlighted) {
            [imageView setHighlightedImage:image];
        }
    }
}


#pragma mark - Images

- (UIImageView *)createImageViewAtYPosition:(CGFloat)yPosition
{
    CGRect imageRect = CGRectMake(0.f,
                                  yPosition,
                                  self.frame.size.height,
                                  self.frame.size.height);
    UIImageView *result = [[UIImageView alloc] initWithFrame:imageRect];
    [result setImage:[self imageForPageState:UIControlStateNormal]];
    [result setHighlightedImage:[self imageForPageState:UIControlStateHighlighted]];
    [result setClipsToBounds:YES];
    [result setContentMode:UIViewContentModeScaleAspectFit];
    [result setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin];
    return result;
}


#pragma mark - UI Elements

- (void)setImageViewsContainer:(UIView *)imageViewsContainer
{
    [_imageViewsContainer removeFromSuperview];
    _imageViewsContainer = imageViewsContainer;
    if (imageViewsContainer) {
        [imageViewsContainer setOpaque:NO];
        [imageViewsContainer setBackgroundColor:[UIColor clearColor]];
        for (UIImageView *imageView in self.imageViews) {
            [imageViewsContainer addSubview:imageView];
        }
        [imageViewsContainer setAutoresizesSubviews:NO];
        [imageViewsContainer setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight];
        [self insertSubview:imageViewsContainer
                    atIndex:0];
        [self setCurrentPage:self.currentPage];
    }
}

- (void)checkTouchViews
{
    if (!self.imageViewsContainer) {
        for (UIView *view in self.touchViews) {
            [view removeFromSuperview];
        }
        [self setTouchViews:[NSMutableArray array]];
    } else if (self.touchViews.count == 0) {
        UIView *leftTouch = [[UIView alloc] initWithFrame:CGRectMake(0.f,
                                                                     0.f,
                                                                     self.frame.size.width / 2.f,
                                                                     self.frame.size.height)];
        [leftTouch setOpaque:NO];
        [leftTouch setBackgroundColor:[UIColor clearColor]];
        [leftTouch setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin];
        UITapGestureRecognizer *leftTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(leftPageChangeTapped:)];
        [leftTouch addGestureRecognizer:leftTap];
        [self.touchViews addObject:leftTouch];
        UIView *rightTouch = [[UIView alloc] initWithFrame:CGRectMake(0.f,
                                                                      self.frame.size.width / 2.f,
                                                                      self.frame.size.width / 2.f,
                                                                      self.frame.size.height)];
        [rightTouch setOpaque:NO];
        [rightTouch setBackgroundColor:[UIColor clearColor]];
        [rightTouch setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        UITapGestureRecognizer *rightTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                   action:@selector(rightPageChangeTapped:)];
        [rightTouch addGestureRecognizer:rightTap];
        [self.touchViews addObject:rightTouch];
        for (UIView *view in self.touchViews) {
            [self addSubview:view];
        }
    }
}


#pragma mark - UI Actions

- (void)leftPageChangeTapped:(UITapGestureRecognizer *)tap
{
    if (tap.state == UIGestureRecognizerStateRecognized) {
        if (self.currentPage == 0) return;
        [self setCurrentPage:--self.currentPage];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void)rightPageChangeTapped:(UITapGestureRecognizer *)tap
{
    if (tap.state == UIGestureRecognizerStateRecognized) {
        if (self.currentPage == self.imageViews.count - 1) return;
        [self setCurrentPage:++self.currentPage];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

@end
