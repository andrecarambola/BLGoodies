//
//  NSFileManager+Goodies.m
//  Project
//
//  Created by André Abou Chami Campana on 17/09/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "NSFileManager+Goodies.h"
#import "NSObject+Goodies.h"
#import "BLDefines.h"
#import "BLQueuer.h"
#import "NSString+BLText.h"
#import "BLLogger.h"


#pragma mark - Defines
#ifndef kBLFileManagerDefaultFolderName
#define kBLFileManagerDefaultFolderName @"BLFiles"
#endif


#pragma mark - Private Interface
@interface NSFileManager (GoodiesAux)

- (BOOL)shouldExcludeFileTypeFromBackup:(blFiles)fileType;

@end


#pragma mark - Implementation
@implementation NSFileManager (Goodies)

#pragma mark - Getting Paths

+ (NSURL *)urlForFolderWithType:(blFiles)fileType
{
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    
    //Base URL
    NSURL *result;
    switch (fileType) {
        case blThumbnailImage:
        case blFullImage:
        case blAudioFile:
        case blVideoFile:
            result = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory
                                                             inDomains:NSUserDomainMask] lastObject];
            break;
        case blDatabase:
            result = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                             inDomains:NSUserDomainMask] lastObject];
            break;
        case blTempFile:
            result = [NSURL fileURLWithPath:NSTemporaryDirectory()];
            break;
        default:
            return nil;
    }
    
    //Custom URL
    result = [result URLByAppendingPathComponent:kBLFileManagerDefaultFolderName];
    switch (fileType) {
        case blThumbnailImage:
            result = [result URLByAppendingPathComponent:@"Thumbs"];
            break;
        case blFullImage:
            result = [result URLByAppendingPathComponent:@"Images"];
            break;
        case blAudioFile:
            result = [result URLByAppendingPathComponent:@"Audio"];
            break;
        case blVideoFile:
            result = [result URLByAppendingPathComponent:@"Video"];
            break;
        case blDatabase:
            result = [result URLByAppendingPathComponent:@"Database"];
            break;
        case blTempFile:
            result = [result URLByAppendingPathComponent:@"Goodies"];
            break;
        default:
            return nil;
    }
    
    //Creating folder if needed
    if (![[NSFileManager defaultManager] fileExistsAtPath:result.path]) {
        NSError *error;
        if (![[NSFileManager defaultManager] createDirectoryAtURL:result
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error])
        {
            if (error) FileLog(@"%@",error);
            return nil;
        }
        if ([[NSFileManager defaultManager] shouldExcludeFileTypeFromBackup:fileType]) {
            [NSFileManager excludeFileFromBackupWithURL:result];
        }
    }
    
    [self endBackgroundTask:bgTaskId];
    
    return result;
}

+ (NSURL *)urlForFileWithType:(blFiles)fileType
                  andFileName:(NSString *)fileName
{
    NSAssert(fileName.length > 2, @"File name should not be empty");
    NSAssert([fileName rangeOfString:@"."].location != NSNotFound, @"File name should contain file extension");
    
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    
    NSURL *result = [self urlForFolderWithType:fileType];
    fileName = [fileName cleanStringForFileSystem];
    
    [self endBackgroundTask:bgTaskId];
    
    return [result URLByAppendingPathComponent:fileName];
}


#pragma mark - Saving Files

+ (void)saveData:(NSData *)data
           toURL:(NSURL *)destinationURL
        withType:(blFiles)fileType
        andBlock:(FileCompletionBlock)block
{
    NSAssert(data.length > 0, @"Data should not be empty");
    NSAssert(destinationURL.path.length > 0 && [destinationURL scheme], @"Destination URL is not correct");
    NSAssert(fileType != blFileTypeInvalid, @"File type should not be invalid");
    
    //Sanity
    NSURL *tempURL = [self urlForFileWithType:fileType
                                  andFileName:[destinationURL.path lastPathComponent]];
    if (!tempURL || ![tempURL.path isEqualToString:destinationURL.path]) {
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(NO, nil);
            });
        }
        return;
    }
    
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    
    [BLQueuer enqueueConcurrentOperationWithBlock:^
    {
        NSError *error;
        BOOL result = [data writeToURL:destinationURL
                               options:NSDataWritingAtomic
                                 error:&error];
        if (!result && error) FileLog(@"%@",error);
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(result, (result) ? tempURL : nil);
            });
        }
        [NSFileManager endBackgroundTask:bgTaskId];
    }];
}


#pragma mark - Copying Files

+ (void)copyFileFromURL:(NSURL *)originURL
                  toURL:(NSURL *)destinationURL
               withType:(blFiles)fileType
               andBlock:(FileCompletionBlock)block
{
    NSAssert([originURL scheme], @"Origin URL should not be empty");
    NSAssert([destinationURL scheme], @"Destination URL should not be empty");
    NSAssert(fileType != blFileTypeInvalid, @"File type should not be invalid");
    
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    
    [BLQueuer enqueueConcurrentOperationWithBlock:^
    {
        NSError *error;
        NSData *data = [NSData dataWithContentsOfURL:originURL
                                             options:NSDataReadingUncached
                                               error:&error];
        if (error) FileLog(@"%@",error);
        if (!data) {
            if (block) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block(NO, nil);
                });
                [NSFileManager endBackgroundTask:bgTaskId];
            }
            return;
        }
        
        [NSFileManager saveData:data
                          toURL:destinationURL
                       withType:fileType
                       andBlock:^(BOOL success, NSURL *finalURL)
        {
            if (!success) {
                if (block) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        block(NO, nil);
                    });
                }
                [NSFileManager endBackgroundTask:bgTaskId];
            } else {
                NSURL *tempURL = finalURL;
                [NSFileManager deleteFileAtURL:originURL
                                      andBlock:^(BOOL success, NSURL *finalURL)
                {
                    if (block) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            block(success, tempURL);
                        });
                    }
                    [NSFileManager endBackgroundTask:bgTaskId];
                }];
            }
        }];
    }];
}


#pragma mark - Managing Files

+ (BOOL)excludeFileFromBackupWithURL:(NSURL *)url
{
    //Sanity
    if (url.path.length == 0 || ![url scheme]) return NO;
    
    NSError *error = nil;
    BOOL result = [url setResourceValue:@YES
                                 forKey:NSURLIsExcludedFromBackupKey
                                  error:&error];
    if (!result && error) FileLog(@"%@",error);
    return result;
}


#pragma mark - Deleting Files

+ (void)deleteFileAtURL:(NSURL *)deletionURL
               andBlock:(FileCompletionBlock)block
{
    NSAssert([deletionURL scheme], @"Deletion URL should not be empty");
    
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    
    [BLQueuer enqueueConcurrentOperationWithBlock:^
    {
        NSError *error;
        BOOL result = [[NSFileManager defaultManager] removeItemAtURL:deletionURL
                                                                error:&error];
        if (!result && error) FileLog(@"%@",error);
        
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(result, nil);
            });
        }
        [NSFileManager endBackgroundTask:bgTaskId];
    }];
}

+ (void)deleteAllFilesWithType:(blFiles)fileType
                      andBlock:(FileCompletionBlock)block
{
    NSAssert(fileType != blFileTypeInvalid, @"File type should not be invalid");
    
    UIBackgroundTaskIdentifier bgTaskId = [self startBackgroundTask];
    
    NSURL *url = [self urlForFolderWithType:fileType];
    
    [BLQueuer enqueueConcurrentOperationWithBlock:^
    {
        NSError *error;
        BOOL result = [[NSFileManager defaultManager] removeItemAtURL:url
                                                                error:&error];
        if (!result && error) FileLog(@"%@",error);
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(result, nil);
            });
        }
        [NSFileManager endBackgroundTask:bgTaskId];
    }];
}

+ (void)deleteTempFilesWithBlock:(FileCompletionBlock)block
{
    [self deleteAllFilesWithType:blTempFile
                        andBlock:block];
}

@end
