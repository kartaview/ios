//
//  OSVAPISerialOperation.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OSVAPISerialOperation;

typedef void (^OSVAsyncTaskBlock)(OSVAPISerialOperation *operation);
typedef void (^OSVAsyncCancelBlock)(OSVAPISerialOperation *operation);
typedef void (^OSVAsyncPauseBlock)(OSVAPISerialOperation *operation);
typedef void (^OSVAsyncResumeBlock)(OSVAPISerialOperation *operation);

@interface OSVAPISerialOperation : NSOperation

@property (nonatomic, copy) OSVAsyncTaskBlock       asyncTask;
@property (nonatomic, copy) OSVAsyncCancelBlock     cancelTaskBlock;
@property (nonatomic, copy) OSVAsyncPauseBlock      pauseTaskBlock;
@property (nonatomic, copy) OSVAsyncResumeBlock     resumeTaskBlock;

@property (nonatomic, strong) id                    taskObject;

- (instancetype)initWithOperation:(OSVAPISerialOperation *)operation andMaxRetryNumber:(NSInteger)max;

- (void)asyncTaskDone;

- (void)shouldSuspend;
- (void)shouldResume;

@end
