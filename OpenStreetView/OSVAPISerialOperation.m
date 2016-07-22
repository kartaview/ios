//
//  OSVAPISerialOperation.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVAPISerialOperation.h"

@interface OSVAPISerialOperation ()

@property (nonatomic, assign) BOOL executingOperation;
@property (nonatomic, assign) BOOL finishedOperation;

@property (nonatomic, assign) NSInteger retryNumber;

@end

@implementation OSVAPISerialOperation

- (instancetype)initWithOperation:(OSVAPISerialOperation *)operation andMaxRetryNumber:(NSInteger)max {
    self = [super init];
    if (self) {
        self.retryNumber = operation.retryNumber + 1;
//        if (max > self.retryNumber) {
//        //retry
//        } else {
//        //stop retrying
//        }
        self.asyncTask = [operation.asyncTask copy];
        self.cancelTaskBlock = [operation.cancelTaskBlock copy];
        self.resumeTaskBlock = [operation.resumeTaskBlock copy];
        self.pauseTaskBlock = [operation.pauseTaskBlock copy];
        self.taskObject = operation.taskObject;
    }
    
    return self;
}

- (void)start {
    if (!self.asyncTask) {
        [self asyncTaskDone];
        return;
    }
    
    if (self.cancelled) {
        [self asyncTaskDone];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    self.executingOperation = YES;
    [self didChangeValueForKey:@"isExecuting"];
    __weak typeof(self) welf = self;
    
    self.asyncTask(welf);
}

- (BOOL)isAsynchronous {
    return YES;
}

- (BOOL)isExecuting {
    return self.executingOperation;
}

- (BOOL)isFinished {
    return self.finishedOperation;
}

- (void)cancel {
    [super cancel];
    if (self.cancelTaskBlock) {
        __weak typeof(self) welf = self;
        self.cancelTaskBlock(welf);
    }
}

- (void)shouldSuspend {
    if (self.pauseTaskBlock) {
        __weak typeof(self) welf = self;
        self.pauseTaskBlock(welf);
    }
}

- (void)shouldResume {
    if (self.resumeTaskBlock) {
        __weak typeof(self) welf = self;
        self.resumeTaskBlock(welf);
    }
}

- (void)asyncTaskDone {
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];

    self.executingOperation = NO;
    self.finishedOperation = YES;
    
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
}

@end

