//
//  BLParseResultsController.m
//  Project
//
//  Created by André Abou Chami Campana on 12/11/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLParseResultsController.h"
#import "BLLogger.h"
#import "BLQueuer.h"


#pragma mark - Functions

void AddUniqueSection(NSMutableDictionary *content,
                      id sectionData)
{
    NSString *newSection;
    if ([sectionData isKindOfClass:[NSString class]]) {
        newSection = sectionData;
    } else if ([sectionData isKindOfClass:[NSNumber class]]) {
        newSection = [sectionData stringValue];
    } else if ([sectionData isKindOfClass:[NSDate class]]) {
        newSection = [sectionData description];
    } else if ([sectionData isKindOfClass:[PFObject class]]) {
        newSection = [sectionData parseClassName];
    } else if ([sectionData isKindOfClass:[NSArray class]]) {
        newSection = NSStringFromClass([NSArray class]);
    }
    BOOL shouldAdd = YES;
    for (NSString *section in content.allKeys) {
        if ([section isEqualToString:newSection]) {
            shouldAdd = NO;
            break;
        }
    }
    if (shouldAdd) [content setObject:[NSMutableArray array]
                               forKey:newSection];
}

void AddRowToSection(NSMutableDictionary *content,
                     NSString *section,
                     PFObject *row)
{
    NSMutableArray *array = [content objectForKey:section];
    [array addObject:row];
    [content setObject:array
                forKey:section];
}

NSMutableDictionary * SeparatedContentFromResult(NSString *sectionNameKeyPath,
                                                 NSArray *result)
{
    NSMutableDictionary *content = [NSMutableDictionary dictionary];
    
    if (result.count > 0) {
        if (sectionNameKeyPath.length == 0)
        {
            [content setObject:[NSMutableArray array]
                        forKey:[(PFObject *)result.firstObject parseClassName]];
        }
        else if ([sectionNameKeyPath rangeOfString:@"."].location == NSNotFound)
        {
            for (PFObject *object in result) {
                id value = [object objectForKey:sectionNameKeyPath];
                AddUniqueSection(content, value);
                AddRowToSection(content, value, object);
            }
        }
        else
        {
            NSArray *keyPaths = [sectionNameKeyPath componentsSeparatedByString:@"."];
            for (PFObject *object in result) {
                id value = object[keyPaths.firstObject];
                for (int i=1; i<keyPaths.count; ++i) {
                    value = value[keyPaths[i]];
                }
                AddUniqueSection(content, value);
                AddRowToSection(content, value, object);
            }
        }
    }
    
    return content;
}


#pragma mark - Private Interface
@interface BLParseResultsController ()

//Setup
@property (nonatomic, strong) PFQuery *query;
@property (nonatomic, strong) NSString *sectionNameKeyPath;
@property (nonatomic, weak) id<BLParseResultsControllerDelegate> delegate;

//Content
@property (nonatomic, strong) NSMutableDictionary *tempContent;
@property (nonatomic, strong) NSMutableDictionary *content;
@property (nonatomic) NSInteger totalItems;
- (void)processFetchWithResult:(NSArray *)result;

//Aux
- (BOOL)shouldReportToDelegate;

@end


#pragma mark - Implementation
@implementation BLParseResultsController


#pragma mark - Initializer

+ (instancetype)controllerWithQuery:(PFQuery *)query
                 sectionNameKeyPath:(NSString *)keyPath
                        andDelegate:(id<BLParseResultsControllerDelegate>)delegate
{
    NSAssert(query != nil, @"Query should not be nil");
    NSAssert(delegate != nil, @"Delegate should not be nil");
    
    BLParseResultsController *result = [[BLParseResultsController alloc] init];
    [result setQuery:query];
    [result setSectionNameKeyPath:keyPath];
    [result setDelegate:delegate];
    
    return result;
}


#pragma mark - Fetching

- (void)fetch
{
    __weak BLParseResultsController *weakSelf = self;
    [self startBackgroundTask];
    [self startTimeoutOperationWithBlock:^
    {
        [[weakSelf query] cancel];
        [weakSelf stopTimeoutOperation];
    }];
    [self.query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
        if (error) {
            ParseLog(@"%@",error);
            [weakSelf stopTimeoutOperation];
            [weakSelf endBackgroundTask];
        } else {
            [BLQueuer enqueueConcurrentOperationWithBlock:^
            {
                [weakSelf processFetchWithResult:objects];
                
                [weakSelf stopTimeoutOperation];
                [weakSelf endBackgroundTask];
            }];
        }
    }];
}


#pragma mark - Content

- (NSArray *)fetchedContent
{
    NSMutableArray *tempResult = [NSMutableArray array];
    for (id key in self.content.allKeys) {
        [tempResult addObjectsFromArray:[self.content objectForKey:key]];
    }
    return [NSArray arrayWithArray:tempResult];
}

- (NSInteger)numberOfSections
{
    return self.content.allKeys.count;
}

- (NSString *)sectionAtIndex:(NSInteger)index
{
    if (index < 0 || index >= self.content.allKeys.count) return nil;
    return [self.content.allKeys objectAtIndex:index];
}

- (NSUInteger)numberOfRowsInSection:(NSInteger)section
{
    if (section < 0 || section >= self.numberOfSections) return NSNotFound;
    return [(NSArray *)[self.content objectForKey:[self.content.allKeys objectAtIndex:section]] count];
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath) return nil;
    return [(NSArray *)[self.content objectForKey:[self.content.allKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
}

- (NSMutableDictionary *)content
{
    if (!_content) _content = [NSMutableDictionary dictionary];
    return _content;
}

- (void)processFetchWithResult:(NSArray *)result
{
    //WE ARE IN THE BACKGROUND
    
    __weak BLParseResultsController *weakSelf = self;
    
    if (!result) result = [NSArray array];
    
    //Begin changes
    if ([self shouldReportToDelegate]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[weakSelf delegate] controllerWillChangeContent:weakSelf];
        });
    }
    
    //Calculating total items
    [self setTotalItems:result.count];
    
    //Organizing Temp Content
    [self setTempContent:SeparatedContentFromResult(self.sectionNameKeyPath, result)];
    
    //Organizing Changes
#warning implement change analysis
    
    //Traversing Current Content
    for (int i=0; i<self.content.allKeys.count; ++i)
    {
        if ([self shouldReportToDelegate]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[weakSelf delegate] controller:weakSelf
                        didChangeSectionAtIndex:i
                                  forChangeType:blResultsControllerChangeDelete];
            });
        }
    }
    //Traversing Temp Content
    for (int i=0; i<self.tempContent.allKeys.count; ++i)
    {
        if ([self shouldReportToDelegate]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[weakSelf delegate] controller:weakSelf
                        didChangeSectionAtIndex:i
                                  forChangeType:blResultsControllerChangeInsert];
            });
        }
    }
    
    //Saving content
    [self setContent:self.tempContent];
    [self setTempContent:nil];
    
    //End changes
    if ([self shouldReportToDelegate]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[weakSelf delegate] controllerDidChangeContent:weakSelf];
        });
    }
}


#pragma mark - Aux

- (BOOL)shouldReportToDelegate
{
    return self.delegate != nil;
}

@end
