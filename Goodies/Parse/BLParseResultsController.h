//
//  BLParseResultsController.h
//  Project
//
//  Created by André Abou Chami Campana on 12/11/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLObject.h"
#import <Parse/Parse.h>


#pragma mark - Classes
@class BLParseResultsController;


#pragma mark - Type Defs
typedef NS_ENUM(NSInteger, blResultsControllerChangeType) {
    blResultsControllerChangeInsert,
    blResultsControllerChangeDelete,
    blResultsControllerChangeUpdate
};


#pragma mark - Protocols
@protocol BLParseResultsControllerDelegate <NSObject>

- (void)controllerWillChangeContent:(BLParseResultsController *)controller;
- (void)controller:(BLParseResultsController *)controller didChangeSectionAtIndex:(NSUInteger)sectionIndex
     forChangeType:(blResultsControllerChangeType)changeType;
- (void)controller:(BLParseResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(blResultsControllerChangeType)changeType
      newIndexPath:(NSIndexPath *)indexPath;
- (void)controllerDidChangeContent:(BLParseResultsController *)controller;

@end


#pragma mark - Public Interface
@interface BLParseResultsController : BLObject

//Initializer
+ (instancetype)controllerWithQuery:(PFQuery *)query
                 sectionNameKeyPath:(NSString *)keyPath
                        andDelegate:(id<BLParseResultsControllerDelegate>)delegate;

//Setup
@property (nonatomic, readonly) PFQuery *query;
@property (nonatomic, readonly) NSString *sectionNameKeyPath;
- (id<BLParseResultsControllerDelegate>)delegate;

//Fetching
- (void)fetch;

//Content
@property (nonatomic, readonly) NSArray *fetchedContent;
- (NSInteger)numberOfSections;
- (NSString *)sectionAtIndex:(NSInteger)index;
- (NSUInteger)numberOfRowsInSection:(NSInteger)section;
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

@end
