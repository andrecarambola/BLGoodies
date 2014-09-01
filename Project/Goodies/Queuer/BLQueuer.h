//
//  BLQueuer.h
//  Goodies
//
//  Created by André Abou Chami Campana on 24/08/14.
//  Copyright (c) 2014 Bell App Lab. All rights reserved.
//

#import "BLObject.h"


@interface BLQueuer : BLObject

+ (void)enqueueConcurrentOperationWithBlock:(void(^)(void))block;
+ (void)enqueueConcurrentOperation:(NSOperation *)operation;

+ (void)enqueueSequentialOperationWithBlock:(void(^)(void))block;
+ (void)enqueueSequentialOperation:(NSOperation *)operation;

@end
