//
//  PFFile+BLFile.m
//  Project
//
//  Created by André Abou Chami Campana on 05/12/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "PFFile+BLFile.h"
#import "BLInternet.h"
#import "BLQueuer.h"
#import "BLLogger.h"


#pragma mark - Static Variables
static NSMutableArray *filesToDownload;
static NSInteger downloadIteration;
static NSMutableArray *filesToUpload;
static NSInteger uploadIteration;


#pragma mark - Private Interface
@interface PFFile (BLFileInternal)

//Static
+ (NSMutableArray *)filesToDownload;
+ (void)setFilesToDownload:(NSMutableArray *)array;
+ (NSMutableArray *)filesToUpload;
+ (void)setFilesToUpload:(NSMutableArray *)array;

//Recursive
+ (void)processDownloadsWithTotalFiles:(NSInteger)totalFiles
                             fileBlock:(ParseFileDataBlock)fileBlock
                         progressBlock:(ParseProgressBlock)progressBlock
                    andCompletionBlock:(ParseCompletionBlock)completionBlock;
+ (void)processUploadsWithTotalFiles:(NSInteger)totalFiles
                       progressBlock:(ParseProgressBlock)progressBlock
                  andCompletionBlock:(ParseCompletionBlock)completionBlock;

@end


#pragma mark - Implementations
@implementation PFFile (BLFile)

#pragma mark - Downloading

+ (void)downloadFiles:(NSArray *)files
        withFileBlock:(ParseFileDataBlock)fileBlock
        progressBlock:(ParseProgressBlock)progressBlock
   andCompletionBlock:(ParseCompletionBlock)completionBlock
{
    //Sanity
    if (files.count == 0 || !fileBlock) {
        [PFObject returnToSenderWithResult:NO
                        andCompletionBlock:completionBlock];
        return;
    }
    
    if (![BLInternet doWeHaveInternet])
    {
        [PFObject returnToSenderWithResult:NO
                        andCompletionBlock:completionBlock];
        return;
    }
    
    //Downloading
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    NSTimer *timer = [self startTimeoutOperationWithInterval:files.count * 20
                                                    andBlock:^
    {
        [PFObject returnToSenderWithResult:NO
                        andCompletionBlock:completionBlock];
        [PFFile endBackgroundTask:bgTaskId];
    }];
    
    [self setFilesToDownload:[NSMutableArray arrayWithArray:files]];
    downloadIteration = 0;
    [self processDownloadsWithTotalFiles:files.count
                               fileBlock:fileBlock
                           progressBlock:progressBlock
                      andCompletionBlock:^(BOOL success)
    {
        [PFObject returnToSenderWithResult:success
                        andCompletionBlock:completionBlock];
        [PFFile stopTimeoutOperation:timer];
        [PFFile endBackgroundTask:bgTaskId];
    }];
}

- (void)downloadFileWithFileBlock:(ParseFileDataBlock)fileBlock
                    progressBlock:(ParseProgressBlock)progressBlock
               andCompletionBlock:(ParseCompletionBlock)completionBlock
{
    [PFFile downloadFiles:@[self]
            withFileBlock:fileBlock
            progressBlock:progressBlock
       andCompletionBlock:completionBlock];
}


#pragma mark - Uploading

+ (void)uploadFiles:(NSArray *)files
  withProgressBlock:(ParseProgressBlock)progressBlock
 andCompletionBlock:(ParseCompletionBlock)completionBlock
{
    //Sanity
    if (files.count == 0) {
        [PFObject returnToSenderWithResult:NO
                        andCompletionBlock:completionBlock];
        return;
    }
    
    //Internet
    if (![BLInternet doWeHaveInternet]) {
        [PFObject returnToSenderWithResult:NO
                        andCompletionBlock:completionBlock];
        return;
    }
    
    //Uploading
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    NSTimer *timer = [self startTimeoutOperationWithInterval:files.count * 20
                                                    andBlock:^
    {
        [PFObject returnToSenderWithResult:NO
                        andCompletionBlock:completionBlock];
        [PFFile endBackgroundTask:bgTaskId];
    }];
    
    [self setFilesToUpload:[NSMutableArray arrayWithArray:files]];
    uploadIteration = 0;
    [self processUploadsWithTotalFiles:files.count
                         progressBlock:progressBlock
                    andCompletionBlock:^(BOOL success)
    {
        [PFObject returnToSenderWithResult:success
                        andCompletionBlock:completionBlock];
        [PFFile stopTimeoutOperation:timer];
        [PFFile endBackgroundTask:bgTaskId];
    }];
}

- (void)uploadFileWithProgressBlock:(ParseProgressBlock)progressBlock
                 andCompletionBlock:(ParseCompletionBlock)completionBlock
{
    [PFFile uploadFiles:@[self]
      withProgressBlock:progressBlock
     andCompletionBlock:completionBlock];
}

@end


@implementation PFFile (BLFileInternal)

#pragma mark - Static

+ (NSMutableArray *)filesToDownload
{
    @synchronized(self)
    {
        return filesToDownload;
    }
}

+ (void)setFilesToDownload:(NSMutableArray *)array
{
    @synchronized(self)
    {
        filesToDownload = array;
    }
}

+ (NSMutableArray *)filesToUpload
{
    @synchronized(self)
    {
        return filesToUpload;
    }
}

+ (void)setFilesToUpload:(NSMutableArray *)array
{
    @synchronized(self)
    {
        filesToUpload = array;
    }
}


#pragma mark - Recursive

+ (void)processDownloadsWithTotalFiles:(NSInteger)totalFiles
                             fileBlock:(ParseFileDataBlock)fileBlock
                         progressBlock:(ParseProgressBlock)progressBlock
                    andCompletionBlock:(ParseCompletionBlock)completionBlock
{
    [BLQueuer enqueueSequentialOperationWithBlock:^
    {
        if ([PFFile filesToDownload].count == 0) {
            [PFFile setFilesToDownload:nil];
            completionBlock(YES);
            return;
        }
        
        PFFile *file = [[PFFile filesToDownload] lastObject];
        [[PFFile filesToDownload] removeLastObject];
        downloadIteration++;
        
        [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error)
        {
            if (error) ParseLog(@"%@",error);
            fileBlock(data, file, totalFiles - downloadIteration);
            [PFFile processDownloadsWithTotalFiles:totalFiles
                                         fileBlock:fileBlock
                                     progressBlock:progressBlock
                                andCompletionBlock:completionBlock];
        }
                             progressBlock:^(int percentDone)
        {
            if (progressBlock) {
                double progress = ((percentDone / 100.f) / totalFiles) * downloadIteration;
                progressBlock(progress);
            }
        }];
    }];
}

+ (void)processUploadsWithTotalFiles:(NSInteger)totalFiles
                       progressBlock:(ParseProgressBlock)progressBlock
                  andCompletionBlock:(ParseCompletionBlock)completionBlock
{
    [BLQueuer enqueueSequentialOperationWithBlock:^
    {
        if ([PFFile filesToUpload].count == 0) {
            [PFFile setFilesToUpload:nil];
            completionBlock(YES);
            return;
        }
        
        PFFile *file = [[PFFile filesToUpload] lastObject];
        [[PFFile filesToUpload] removeLastObject];
        uploadIteration++;
        
        [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
        {
            if (error) ParseLog(@"%@",error);
            [PFFile processUploadsWithTotalFiles:totalFiles
                                   progressBlock:progressBlock
                              andCompletionBlock:completionBlock];
        }
                          progressBlock:^(int percentDone)
        {
            if (progressBlock) {
                double progress = ((percentDone / 100.f) / totalFiles) * uploadIteration;
                progressBlock(progress);
            }
        }];
    }];
}

@end
