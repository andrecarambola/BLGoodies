//
//  NSFileManager+Goodies.h
//  Project
//
//  Created by André Abou Chami Campana on 17/09/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import <Foundation/Foundation.h>


#pragma mark - Type Defs
typedef NS_ENUM(NSInteger, blFiles) {
    blFileTypeInvalid = 0,
    blThumbnailImage = 12,
    blFullImage = 13,
    blAudioFile = 14,
    blVideoFile = 15,
    blDatabase = 16,
    blTempFile = 17
};

typedef void (^FileCompletionBlock) (BOOL success, NSURL *finalURL);


#pragma mark - Public Interface
@interface NSFileManager (Goodies)

//Getting Paths
+ (NSURL *)urlForFolderWithType:(blFiles)fileType;
+ (NSURL *)urlForFileWithType:(blFiles)fileType
                  andFileName:(NSString *)fileName;

//Saving Files
+ (void)saveData:(NSData *)data
           toURL:(NSURL *)destinationURL
        withType:(blFiles)fileType
        andBlock:(FileCompletionBlock)block;

//Copying Files
+ (void)copyFileFromURL:(NSURL *)originURL
                  toURL:(NSURL *)destinationURL
               withType:(blFiles)fileType
               andBlock:(FileCompletionBlock)block;

//Managing Files
+ (BOOL)excludeFileFromBackupWithURL:(NSURL *)url;

//Deleting Files
+ (void)deleteFileAtURL:(NSURL *)deletionURL
               andBlock:(FileCompletionBlock)block;
+ (void)deleteAllFilesWithType:(blFiles)fileType
                      andBlock:(FileCompletionBlock)block;
+ (void)deleteTempFilesWithBlock:(FileCompletionBlock)block;

@end
