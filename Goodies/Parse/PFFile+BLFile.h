//
//  PFFile+BLFile.h
//  Project
//
//  Created by André Abou Chami Campana on 05/12/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import <Parse/Parse.h>
#import "PFObject+BLObject.h"


#pragma mark - Type Defs
typedef void (^ParseFileDataBlock) (NSData *data, PFFile *file, NSInteger index);
typedef void (^ParseProgressBlock) (float progress);


#pragma mark - Public Interface
@interface PFFile (BLFile)

//Downloading
+ (void)downloadFiles:(NSArray *)files
        withFileBlock:(ParseFileDataBlock)fileBlock
        progressBlock:(ParseProgressBlock)progressBlock
   andCompletionBlock:(ParseCompletionBlock)completionBlock;
- (void)downloadFileWithFileBlock:(ParseFileDataBlock)fileBlock
                    progressBlock:(ParseProgressBlock)progressBlock
               andCompletionBlock:(ParseCompletionBlock)completionBlock;

//Uploading
+ (void)uploadFiles:(NSArray *)files
  withProgressBlock:(ParseProgressBlock)progressBlock
 andCompletionBlock:(ParseCompletionBlock)completionBlock;
- (void)uploadFileWithProgressBlock:(ParseProgressBlock)progressBlock
                 andCompletionBlock:(ParseCompletionBlock)completionBlock;

@end
