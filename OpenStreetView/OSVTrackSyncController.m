//
//  OSVTrackSyncController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/02/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVTrackSyncController.h"
#import "OSVAPI.h"
#import "OSVSyncUtils.h"
#import "OSVUtils.h"
#import "OSVAPISerialOperation.h"
#import "OSVPersistentManager.h"
#import "OSVLogger.h"
#import "OSVUserDefaults.h"
#import "OSVVideo.h"
#import "OSVLocalNotificationsController.h"

#import <Crashlytics/Crashlytics.h>

@interface OSVTrackSyncController ()

@property (nonatomic) OSVAPI                    *osvAPI;

@property (nonatomic) NSLock                    *getSequncesLock;
@property (nonatomic) NSLock                    *getTracksLock;

@property (nonatomic) NSLock                    *uploadingLock;

@property (nonatomic) NSOperationQueue          *listSequencesQueue;
@property (nonatomic) NSMutableArray            *listTracksOpetations;

@property (nonatomic) NSOperationQueue          *videoUploadQueue;
@property (nonatomic) NSOperationQueue          *sequncesUploadingQueue;

@property (nonatomic) NSMutableDictionary<__kindof NSString *, __kindof NSOperation *> *imageUploadingOperatios;

@property (strong, nonatomic) NSTimer           *stayAliveTimer;

@end

UIBackgroundTaskIdentifier taskIndentifier;

@implementation OSVTrackSyncController

- (instancetype)initWithOSVAPI:(OSVAPI *)api {
    self = [super init];
    
    if (self) {
        self.osvAPI = api;
        
        self.listSequencesQueue = [NSOperationQueue new];
        self.listSequencesQueue.maxConcurrentOperationCount = 1;
        
        self.videoUploadQueue = [NSOperationQueue new];
        self.videoUploadQueue.maxConcurrentOperationCount = 1;
        
        self.sequncesUploadingQueue = [NSOperationQueue new];
        self.sequncesUploadingQueue.maxConcurrentOperationCount = 1;
        
        self.listTracksOpetations = [NSMutableArray new];
        
        self.getSequncesLock = [NSLock new];
        self.getTracksLock = [NSLock new];
        self.uploadingLock = [NSLock new];
        
        self.imageUploadingOperatios = [NSMutableDictionary dictionary];
        
        self.cache = [OSVTrackCache new];
    }
    
    return self;
}

#pragma mark - Getter methods

- (void)getSerialServerTracksInBoundingBox:(id<OSVBoundingBox>)box
                            withZoom:(double)zoom
               withPartialCompletion:(void (^)(id<OSVSequence> sequence, OSVMetadata *metadata, NSError *error))partComp
                          completion:(void (^)(OSVMetadata *mf))complet {
    __weak typeof(self) welf = self;
    __block int responeses = 0;
    [welf.osvAPI listTracksForUser:self.oscUser atPage:0 inBoundingBox:box withZoom:zoom withCompletionBlock:^(NSArray *sequences, NSError *error, OSVMetadata *metadata) {
//        NSLog(@"___x___  page 0 loaded");
        responeses++;
        
        if (!sequences && !error && !metadata) {
            return;
        }
        
        if (!sequences.count) {
            partComp(nil, metadata, error);
            complet(metadata);
            return;
        }
        
        for (id<OSVSequence> sequence in sequences) {
            partComp(sequence, metadata, error);
        }

        if (metadata.totalPages == responeses) {
            NSLog(@"did send completion00");
            complet(metadata);
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            for (int i = 1; i < metadata.totalPages; i++) {
                [self.osvAPI listTracksForUser:self.oscUser atPage:i inBoundingBox:box withZoom:zoom withCompletionBlock:^(NSArray *sequences, NSError *error, OSVMetadata *metadata) {
//                    NSLog(@"___x___  page %d loaded metadataPageIndex - %ld tp - %ld", i, metadata.pageIndex, totalPages - 1);
                    responeses++;

                    for (id<OSVSequence> sequence in sequences) {
                        partComp(sequence, metadata, error);
                    }
                    
                    if (metadata.totalPages == responeses) {
                        NSLog(@"%p did send completion11 %ld", self, [metadata totalPages]);
                        complet(metadata);
                    }
                }];
            }
        });
    }];
}

- (void)getServerTracksInBoundingBox:(id<OSVBoundingBox>)box
                                  withZoom:(double)zoom
                     withPartialCompletion:(void (^)(id<OSVSequence> sequence, OSVMetadata *metadata, NSError *error))partComp
                                completion:(void (^)(OSVMetadata *mf))complet {
    [self cancelGetServerTracks];
    __weak typeof(self) welf = self;
    [self.listTracksOpetations addObject:[welf.osvAPI listTracksForUser:self.oscUser atPage:0 inBoundingBox:box withZoom:zoom withCompletionBlock:^(NSArray *sequences, NSError *error, OSVMetadata *metadata) {
        //        NSLog(@"___x___  page 0 loaded");
        if (!sequences && !error && !metadata) {
            return;
        }
        
        if (!sequences.count) {
            partComp(nil, metadata, error);
            complet(metadata);
            return;
        }
        
        for (id<OSVSequence> sequence in sequences) {
            partComp(sequence, metadata, error);
        }
        NSInteger totalPages = metadata.totalItems / metadata.itemsPerPage + (metadata.totalItems % metadata.itemsPerPage != 0 ? 1 : 0);
        
        if (metadata.isLastPage) {
            NSLog(@"did send completion0");
            complet(metadata);
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            for (int i = 1; i < totalPages; i++) {
                [welf.listTracksOpetations addObject:[welf.osvAPI listTracksForUser:self.oscUser atPage:i inBoundingBox:box withZoom:zoom withCompletionBlock:^(NSArray *sequences, NSError *error, OSVMetadata *metadata) {
                    //                    NSLog(@"___x___  page %d loaded metadataPageIndex - %ld tp - %ld", i, metadata.pageIndex, totalPages - 1);
                    
                    for (id<OSVSequence> sequence in sequences) {
                        partComp(sequence, metadata, error);
                    }
                    
                    if (metadata.isLastPage) {
                        NSLog(@"%p did send completion1 %ld", self, [metadata totalPages]);
                        complet(metadata);
                    }
                }]];
            }
        });
    }]];
}


- (void)getLayersFromLocation:(CLLocationCoordinate2D)coordinate withCompletion:(void (^)(NSArray *, NSError *))completion {
    __weak typeof(self) welf = self;
    [welf.osvAPI getLayersFromLocation:coordinate radius:50 withCompletion:^(NSArray *array, NSError *error) {
        completion(array, error);
    }];
}

- (void)getMyServerSequencesAtPage:(NSInteger)index withCompletion:(void (^)(NSArray *, OSVMetadata *, NSError *))completion {
    if (![self userIsLoggedIn]) {
        completion(nil, [OSVMetadata metadataError], [NSError errorWithDomain:@"OSMAPI" code:1 userInfo:@{@"Authentication":@"UserAutenticationRequired"}]);
        return;
    }
    [self.osvAPI listMySequncesForUser:self.oscUser atPage:index withCompletionBlock:^(NSArray *sequences, NSError *error, OSVMetadata *metadata) {
        if (error) {
            completion(nil, nil, error);
            return;
        }

        completion(sequences, metadata, error);
    }];
}

- (void)getPhotosForTrack:(id<OSVSequence>)seq withCompletionBlock:(void (^)(id<OSVSequence>seq , NSError *error))completion {
    [self.osvAPI listPhotosForUser:self.oscUser withSequence:seq completionBlock:^(NSMutableArray<id<OSVPhoto>> *photos, NSError *error) {
        seq.photos = photos;
        seq.dateAdded = [NSDate dateWithTimeIntervalSince1970:photos.firstObject.photoData.timestamp];
        completion(seq, error);
    }];
}

#pragma mark - Cancel Methods
- (void)cancelGetServerTracks {    
    [self.getTracksLock lock];
    [self.listTracksOpetations makeObjectsPerformSelector:@selector(cancel)];
    self.listTracksOpetations = [NSMutableArray array];
    [self.getTracksLock unlock];
}

- (void)cancelGetServerSequences {
    [self.getSequncesLock lock];
    [self.listSequencesQueue cancelAllOperations];
    self.listSequencesQueue = [[NSOperationQueue alloc] init];
    self.listSequencesQueue.maxConcurrentOperationCount = 1;
    [self.getSequncesLock unlock];
}

- (void)cancelUploadForPhoto:(OSVPhoto *)photo {
    [self.uploadingLock lock];
    NSOperation *op = self.imageUploadingOperatios[photo.imageName];
    [op cancel];
    [self.imageUploadingOperatios removeObjectForKey:photo.imageName];
    [self.uploadingLock unlock];
}

- (void)cancelUpload {
    [self.uploadingLock lock];
    
    [self.videoUploadQueue cancelAllOperations];
    [self.sequncesUploadingQueue cancelAllOperations];
    //ulgly fix
    self.videoUploadQueue = [NSOperationQueue new];
    self.videoUploadQueue.maxConcurrentOperationCount = 1;
    
    self.sequncesUploadingQueue = [NSOperationQueue new];
    self.sequncesUploadingQueue.maxConcurrentOperationCount = 1;
    
    [self.imageUploadingOperatios removeAllObjects];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [[OSVLogger sharedInstance] logMessage:@"Canceled upload: Aplication will sleep" withLevel:LogLevelDEBUG];
    [OSVUserDefaults sharedInstance].isUploading = NO;
    [self.stayAliveTimer invalidate];
    self.stayAliveTimer = nil;
    
    [self.uploadingLock unlock];
}

- (void)pauseUpload {
    [self.uploadingLock lock];
    [self.videoUploadQueue setSuspended:YES];
    [self.videoUploadQueue.operations makeObjectsPerformSelector:@selector(shouldSuspend)];
    [self.uploadingLock unlock];
}

- (void)resumeUpload {
    [self.uploadingLock lock];
    [self.videoUploadQueue setSuspended:NO];
    [self.videoUploadQueue.operations makeObjectsPerformSelector:@selector(shouldResume)];
    [self.uploadingLock unlock];
    
    [self callEveryTwentySeconds];
    [OSVUserDefaults sharedInstance].isUploading = YES;
    [self.stayAliveTimer invalidate];
    self.stayAliveTimer = nil;
    self.stayAliveTimer = [NSTimer scheduledTimerWithTimeInterval:20.0
                                                           target:self
                                                         selector:@selector(callEveryTwentySeconds)
                                                         userInfo:nil
                                                          repeats:YES];
}

- (void)resumeUploadWithBackgroundTask:(UIBackgroundTaskIdentifier)taskID {
    [self.uploadingLock lock];
    [self.videoUploadQueue setSuspended:NO];
    [self.uploadingLock unlock];
    taskIndentifier = taskID;
}

#pragma mark - Upload Methods

- (void)uploadAllSequencesWithCompletion:(void (^)(NSError *error))completion partialCompletion:(void (^)(OSVMetadata *, NSError *))partialCompletion {
    [[OSVLogger sharedInstance] createNewLogFile];
    
    if (![self userIsLoggedIn]) {
        return;
    }
    
    if (![OSVSyncUtils hasInternetPermissions]) {
        [[OSVLogger sharedInstance] logMessage:@"No internet Permissions, upload ALL: Aplication will sleep" withLevel:LogLevelDEBUG];
        completion([NSError errorWithDomain:@"OSVConnectivity" code:1 userInfo:@{@"Request":@"NotAllowed"}]);
        
        return;
    }
    
    [self callEveryTwentySeconds];
    [OSVUserDefaults sharedInstance].isUploading = YES;
    [self stayAlive];
    
    __block long long totalBytesExpectedToUpload = 0;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        totalBytesExpectedToUpload = [OSVSyncUtils sizeOnDiskForSequencesAtPath:[OSVUtils createOSCBasePath]];
    });

    __weak typeof(self) welf = self;

    [OSVPersistentManager getAllSequencesWithCompletion:^(NSArray *sequences, NSInteger photosCount) {
        OSVMetadata *metadata = [OSVMetadata new];
        metadata.totalItems = sequences.count;
        
        __block NSInteger totalProgress = 0;
        __block long long totalProgressCache = 0;
        
        __block NSInteger successfullSequences = 0;
        
        for (OSVSequence *seq in sequences) {
            if (!(seq.uploadID > 0)) {
                NSDictionary *metaDict = [self metadataForTrack:seq];
                if (!metaDict) {
                    continue;
                }
                
                OSVAPISerialOperation *requestID = [OSVAPISerialOperation new];
                //request sequence ID and upload sequence
                [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"request new sq ID operation:%p", requestID]  withLevel:LogLevelDEBUG];
                
                requestID.asyncTask = ^(OSVAPISerialOperation *wop) {
                    if (wop.isCancelled) {
                        return;
                    }
                    
                    NSString *details = @"[]";
                    if (!seq.points) {
                        NSMutableArray<NSDictionary *> *detailsArray = [NSMutableArray array];
                        NSArray<OSVScoreHistory *> *historyArray = [OSVPersistentManager getScoreHistoryForSequenceWithID:seq.uid];
                        for (OSVScoreHistory *sch in historyArray) {
                            seq.points += sch.points;
                            [detailsArray addObject:[sch jsonDictionary]];
                        }
                        
                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:detailsArray options:NSJSONWritingPrettyPrinted error:nil];
                        details = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    }
                    
                    OSVMetadata *uploadingMeta = [OSVMetadata new];
                    uploadingMeta.uploadingMetadata = YES;

                    [welf.osvAPI requestNewSequenceIdForUser:self.oscUser withSequence:seq metadata:metaDict scoreDetails:details withProgressBlock:^(long long tBytes, long long tBytesExpect) {
                        
                        NSDictionary *progress = @{@"progress" :@(totalProgress + tBytes),
                                                   @"totalSize":@(totalBytesExpectedToUpload),
                                                   @"metadata" :uploadingMeta};
                        [[NSNotificationCenter defaultCenter] postNotificationName:kDidReceiveProgress object:nil userInfo:progress];
                       

                        totalProgressCache = tBytes;
                    } completionBlock:^(NSInteger sequenceId, NSError * _Nullable error) {
                        if (error) {
                            completion(error);
                            
                            totalProgressCache = 0;
                            
                            [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"failed request new sq ID operation:%p withError:%@", wop, error]  withLevel:LogLevelDEBUG];
                            OSVAPISerialOperation *retryOP = [[OSVAPISerialOperation alloc] initWithOperation:wop andMaxRetryNumber:10];
                            [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"retry request new sq ID operation:%p", retryOP]  withLevel:LogLevelDEBUG];
                            [welf.sequncesUploadingQueue addOperation:retryOP];
                            
                            [wop asyncTaskDone];
                        } else {
                            seq.uploadID = sequenceId;
                            
                            totalProgress += totalProgressCache;
                            [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"success request new sq ID operation:%p seqID=%ld", wop, (long)sequenceId]  withLevel:LogLevelDEBUG];

                            [OSVPersistentManager updatePhotosHavingLocalSequenceID:seq.uid withServerID:sequenceId];

                            metadata.index++;
                            
                            [welf uploadVideos:seq withProgress:^(long long tB, long long tBE) {
                                NSDictionary *progress = @{@"progress" :@(totalProgress + tB),
                                                          @"totalSize":@(totalBytesExpectedToUpload),
                                                          @"metadata" :metadata};
                                [[NSNotificationCenter defaultCenter] postNotificationName:kDidReceiveProgress object:nil userInfo:progress];
                                totalProgressCache = tB;
                            } andCompletion:^(NSError *error) {
                                if (error) {
                                    totalProgressCache = 0;
                                    
                                    [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"some error retry request new sq ID operation:%p with error:%@", wop, error]  withLevel:LogLevelDEBUG];

                                    OSVAPISerialOperation *retryOP = [[OSVAPISerialOperation alloc] initWithOperation:wop andMaxRetryNumber:10];
                                    [welf.sequncesUploadingQueue addOperation:retryOP];

                                    completion(error);
                                    [wop asyncTaskDone];
                                } else {
                                    
                                    [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"success uploading videos for seq=%ld operation:%p", (long)sequenceId, wop]  withLevel:LogLevelDEBUG];
                                    [[NSNotificationCenter defaultCenter] postNotificationName:kDidFinishUploadingSequence object:nil userInfo:@{@"sequence" : seq}];
                                    
                                    totalProgress += totalProgressCache;
                                    successfullSequences++;
                                    
                                    partialCompletion(metadata, nil);
                                    [wop asyncTaskDone];
                                }
                            }];
                        }
                    }];
                };
                [welf.sequncesUploadingQueue addOperation:requestID];
            } else {
                OSVAPISerialOperation *uploadSeqOP = [OSVAPISerialOperation new];
                
                [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Uploading videos for seq=%ld operation:%p", (long)seq.uploadID, uploadSeqOP]  withLevel:LogLevelDEBUG];

                uploadSeqOP.asyncTask = ^(OSVAPISerialOperation *wop) {
                    if (wop.isCancelled) {
                        return;
                    }
                    
                    metadata.index++;
                    [welf uploadVideos:seq withProgress:^(long long tB, long long tBE) {
                        NSDictionary *progress = @{@"progress" :@(totalProgress + tB),
                                                   @"totalSize":@(totalBytesExpectedToUpload),
                                                   @"metadata" :metadata};
                        [[NSNotificationCenter defaultCenter] postNotificationName:kDidReceiveProgress object:nil userInfo:progress];
                    } andCompletion:^(NSError *error) {
                        if (error) {
                            completion(error);
                            
                            [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Error Uploading videos operation:%p error:%@", wop, error]  withLevel:LogLevelDEBUG];

                            [wop asyncTaskDone];
                        } else {
                            successfullSequences++;
                            
                            [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"success Uploading videos for Seq=%ld operation:%p", (long)seq.uploadID, wop]  withLevel:LogLevelDEBUG];
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:kDidFinishUploadingSequence object:nil userInfo:@{@"sequence" : seq}];
                            partialCompletion(metadata, nil);
                            [wop asyncTaskDone];
                        }
                    }];
                };
                [welf.sequncesUploadingQueue addOperation:uploadSeqOP];
            }
        }
        
        OSVAPISerialOperation *finishUploadingAll = [OSVAPISerialOperation new];
        
        [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Created finish uploading all operation:%p", finishUploadingAll]  withLevel:LogLevelDEBUG];
        
        finishUploadingAll.asyncTask = ^(OSVAPISerialOperation *wfinishUploadingAll) {
            if (wfinishUploadingAll.isCancelled) {
                return;
            }
            
            if (successfullSequences != metadata.totalItems) {
                [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Not all finished with success finish will retry uploading all operation:%p SuccesNumb:%ld total:%ld", wfinishUploadingAll, (long)successfullSequences, (long)metadata.totalItems]  withLevel:LogLevelDEBUG];
                OSVAPISerialOperation *retryOP = [[OSVAPISerialOperation alloc] initWithOperation:wfinishUploadingAll andMaxRetryNumber:10];
                [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"retry Created finish uploading all operation:%p", retryOP]  withLevel:LogLevelDEBUG];

                [welf.sequncesUploadingQueue addOperation:retryOP];
                
                [wfinishUploadingAll asyncTaskDone];
            } else {
                
                [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
                [[NSNotificationCenter defaultCenter] postNotificationName:kDidFinishUploadingAll object:nil userInfo:@{}];
                
                [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"success finish uploading all operation:%p", wfinishUploadingAll]  withLevel:LogLevelDEBUG];

                [OSVUserDefaults sharedInstance].isUploading = NO;
                [self.stayAliveTimer invalidate];
                self.stayAliveTimer = nil;
                [wfinishUploadingAll asyncTaskDone];
                [OSVLocalNotificationsController removeUploadNotification];

                if (taskIndentifier) {
                    [[UIApplication sharedApplication] endBackgroundTask:taskIndentifier];
                    taskIndentifier = UIBackgroundTaskInvalid;
                }
            }
        };
        
        [self.sequncesUploadingQueue addOperation:finishUploadingAll];
    }];
}

- (void)stayAlive {
    [self.stayAliveTimer invalidate];
    self.stayAliveTimer = nil;
    self.stayAliveTimer = [NSTimer scheduledTimerWithTimeInterval:20.0
                                                           target:self
                                                         selector:@selector(callEveryTwentySeconds)
                                                         userInfo:nil
                                                          repeats:YES];
}

- (void)uploadVideos:(OSVSequence *)sequence withProgress:(void (^)(long long tB, long long tBE))uploadProgressBlock andCompletion:(void (^)(NSError *error))completion {
    __weak typeof(self) welf = self;
    __block NSInteger succesfullRequests = 0;
    __block long long totalBytesSentInVideos = 0;
    
    __block long long tbsCache = 0;
    NSArray *videos = sequence.videos.allValues;
    NSArray *sorted = [videos sortedArrayUsingComparator:^NSComparisonResult(OSVVideo *obj1, OSVVideo *obj2) {
        if (obj1.videoIndex < obj2.videoIndex) {
            return NSOrderedAscending;
        } else if (obj1.videoIndex > obj2.videoIndex) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    for (OSVVideo *video in sorted) {
        video.videoPath = [OSVUtils fileNameForVideoWithTrackID:sequence.uid index:video.videoIndex];
        OSVAPISerialOperation *operation = [OSVAPISerialOperation new];
        
        [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"create Upload Video operation:%p", operation]  withLevel:LogLevelDEBUG];

        operation.asyncTask = ^(OSVAPISerialOperation *wOperation) {
            if (wOperation.isCancelled) {
                [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Operation Was canceled: %p", wOperation]  withLevel:LogLevelDEBUG];
                return;
            }
            
            if (!(video.uid > 0)) {
                video.uid = sequence.uploadID;
            }
            //upload video
            wOperation.taskObject = [self.osvAPI uploadVideo:video forUser:self.oscUser withProgressBlock:^(long long totalBytesSent, long long totalBytesExpected) {
                tbsCache = totalBytesSent;
                uploadProgressBlock(totalBytesSentInVideos + tbsCache, totalBytesExpected);
                
                if (wOperation.isCancelled) {
                    [wOperation.taskObject cancel];
                }
            } andCompletionBlock:^(NSInteger videoId, NSError * _Nullable error) {
                if (error && error.code != 613) {
                    
                    tbsCache = 0;
                    [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Upload Video operation:%p error:%@", wOperation, error]  withLevel:LogLevelDEBUG];

                    OSVAPISerialOperation *retryOP = [[OSVAPISerialOperation alloc] initWithOperation:wOperation andMaxRetryNumber:10];
                    [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"created retry Upload Video operation:%p", retryOP]  withLevel:LogLevelDEBUG];
                    [welf.videoUploadQueue addOperation:retryOP];
                    
                    [wOperation asyncTaskDone];
                } else {
                    succesfullRequests++;
                    
                    totalBytesSentInVideos += tbsCache;
                    
                    [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"success Upload Video operation:%p error:%@", wOperation, error]  withLevel:LogLevelDEBUG];

                    if ([OSVSyncUtils removeVideoAtPath:video.videoPath]) {
                        [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"successfuly deleted video operation:%p", wOperation]  withLevel:LogLevelDEBUG];
                        [OSVPersistentManager removePhotosWithVideoIndex:video.videoIndex localSequenceID:sequence.uid];
                    }
                    
                    [wOperation asyncTaskDone];
                }
            }];
            
            wOperation.cancelTaskBlock = ^(OSVAPISerialOperation *wOperation){
                [wOperation.taskObject cancel];
                [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"operation is canceled: %p", wOperation]  withLevel:LogLevelDEBUG];
            };
            
            wOperation.pauseTaskBlock = ^(OSVAPISerialOperation *wOperation){
                [wOperation.taskObject suspend];
                [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"operation is suspended: %p", wOperation]  withLevel:LogLevelDEBUG];
            };
            
            wOperation.resumeTaskBlock = ^(OSVAPISerialOperation *wOperation){
                [wOperation.taskObject resume];
                [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"operation is resume: %p", wOperation]  withLevel:LogLevelDEBUG];
            };
            
            if (!wOperation.taskObject) {
                [wOperation asyncTaskDone];
            }
        };
    
        [self.videoUploadQueue addOperation:operation];
    }
    
    NSInteger localID = sequence.uid;
    NSInteger uploadID = sequence.uploadID;
    NSInteger numberOfVideos = sequence.videos.allKeys.count;
    
    OSVAPISerialOperation *finishedRequest = [OSVAPISerialOperation new];
    [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"created finishSeq operation:%p", finishedRequest]  withLevel:LogLevelDEBUG];

    finishedRequest.asyncTask = ^(OSVAPISerialOperation *wfinishedRequest){
        if (wfinishedRequest.isCancelled) {
            [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Canceled finish %p", wfinishedRequest]  withLevel:LogLevelDEBUG];
            return;
        }
        
        if (succesfullRequests == numberOfVideos) {
            [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"will send finishSeq operation:%p localUID:%ld", wfinishedRequest, (long)localID]  withLevel:LogLevelDEBUG];
            
            [self.osvAPI finishUploadingSequenceWithID:uploadID forUser:self.oscUser withCompletionBlock:^(NSError * _Nullable error) {
                if (!error) {
                    completion(error);
                    [self deleteLocalTrackWithID:localID];
                    [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"finishSeq operation:%p localUID:%ld", wfinishedRequest, (long)localID]  withLevel:LogLevelDEBUG];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [OSVPersistentManager removeSequenceWithID:localID];
                        [wfinishedRequest asyncTaskDone];
                    });
                } else {
                    [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"retry finishSeq operation:%p failde request error:%@", wfinishedRequest, error]  withLevel:LogLevelDEBUG];
                    
                    OSVAPISerialOperation *retryOP = [[OSVAPISerialOperation alloc] initWithOperation:wfinishedRequest andMaxRetryNumber:10];
                    [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"retry finishSeq operation:%p", retryOP]  withLevel:LogLevelDEBUG];
                    
                    [self.videoUploadQueue addOperation:retryOP];
                    
                    [wfinishedRequest asyncTaskDone];
                }
            }];
        } else {
            [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Not all videos uploaded successfuly finishSeq operation:%p successNumb=%ld total=%ld", wfinishedRequest, (long)succesfullRequests, (long)numberOfVideos]  withLevel:LogLevelDEBUG];
            OSVAPISerialOperation *retryOP = [[OSVAPISerialOperation alloc] initWithOperation:wfinishedRequest andMaxRetryNumber:10];
            
            [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"retry finishSeq operation:%p", retryOP]  withLevel:LogLevelDEBUG];
            [self.videoUploadQueue addOperation:retryOP];
            
            [wfinishedRequest asyncTaskDone];
        }
    };
    
    [self.videoUploadQueue addOperation:finishedRequest];
}

- (void)finishUploadingEmptySequencesWithCompletionBlock:(void (^)(NSError *error))completionBlock {
	if (![self userIsLoggedIn]) {
		return;
	}
	
    [[OSVLogger sharedInstance] createNewLogFile];
    NSMutableArray *allfolders = [[OSVSyncUtils getFolderNamesAtPath:[OSVUtils createOSCBasePath]] mutableCopy];
    [OSVPersistentManager getAllSequencesWithCompletion:^(NSArray *sequences, NSInteger photosCount) {
        for (OSVSequence *track in sequences) {
            NSString *trackID = [NSString stringWithFormat:@"%ld", (long)track.uid];
            [allfolders removeObject:trackID];
            
            BOOL containsImages = NO;
            [OSVSyncUtils sizeOnDiskForSequence:track atPath:[OSVUtils createOSCBasePath] containsImages:&containsImages];
            if (!containsImages) {
                [[OSVLogger sharedInstance] logMessage:@"DB contains Photos that are not present in videos.This is a bug!" withLevel:LogLevelDEBUG];
                [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Will Finish uploading seqID:%ld", (long)track.uploadID] withLevel:LogLevelDEBUG];
                [self.osvAPI finishUploadingSequenceWithID:track.uploadID forUser:self.oscUser withCompletionBlock:^(NSError * _Nullable error) {
                    if (!error) {
                        [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Success Finish uploading seqID:%ld", (long)track.uploadID] withLevel:LogLevelDEBUG];
                        if (taskIndentifier) {
                            [[UIApplication sharedApplication] endBackgroundTask:taskIndentifier];
                            taskIndentifier = UIBackgroundTaskInvalid;
                        }
                        
                        [self deleteLocalTrackWithID:track.uid];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [OSVPersistentManager removeSequenceWithID:track.uid];
                        });
                    }
                }];
            }
        }

        // remove all folders that do not appare in DB;
        for (NSString *emptyFolderName in allfolders) {
            [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Will try to remove empty folder:%@", emptyFolderName] withLevel:LogLevelDEBUG];
            [OSVSyncUtils removeTrackWithID:[emptyFolderName integerValue] atPath:[OSVUtils createOSCBasePath]];
        }
    }];
}

- (void)getLocalSequencesWithCompletion:(void (^)(NSArray *sequences))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        [OSVPersistentManager getAllSequencesWithCompletion:^(NSArray *sequences, NSInteger photosCount) {
            completion(sequences);
        }];
    });
}

- (void)getLocalSequenceWithID:(NSInteger)uid
                    completion:(void (^)(OSVSequence *seq))completion {
    completion([OSVPersistentManager getSequenceWithID:uid]);
}

- (void)getScoreHistoryForSequenceWithID:(NSInteger)uid
                              completion:(void (^)(NSArray *history))completion {
    id scoreHistory = [OSVPersistentManager getScoreHistoryForSequenceWithID:uid];
    
    
    completion(scoreHistory);
}

- (void)storeScoreHistory:(OSVScoreHistory *)history {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [OSVPersistentManager storeScoreHistory:history];
    });
}

- (BOOL)isUploading {
    return self.imageUploadingOperatios.allKeys.count > 0 && !self.videoUploadQueue.suspended;
}

- (BOOL)isPaused {
    return self.videoUploadQueue.suspended;
}

#pragma mark - Delete methods

- (void)deleteSequence:(id<OSVSequence>)sequence withCompletionBlock:(void (^)(NSError *error))completionBlock {
    if ([sequence isKindOfClass:[OSVServerSequence class]]) {
        [self.osvAPI deleteSequence:sequence forUser:self.oscUser withCompletionBlock:completionBlock];
    } else {
        for (OSVPhoto *photo in sequence.photos) {
            [OSVPersistentManager removePhoto:photo];
        }
        [self deleteLocalTrackWithID:sequence.uid];
        completionBlock(nil);
    }
}

- (void)deleteLocalTrackWithID:(NSInteger)uid {
    if ([OSVSyncUtils removeTrackWithID:uid atPath:[OSVUtils createOSCBasePath]]) {
        [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"deleted folder with success:%ld", (long)uid]  withLevel:LogLevelDEBUG];
    } else {
        [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"failed to delete folder:%ld", (long)uid]  withLevel:LogLevelDEBUG];
    }
}

#pragma mark - Metadata

- (NSDictionary *)metadataForTrack:(OSVSequence *)seq {
    NSDictionary *metadataMime = @{@"contentType" : @"application/x-gzip",
                                    @"format"      : @"gz"};
    NSString *photoPath = [[OSVUtils createOSCBasePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%ld/track.txt.gz", (long)seq.uid]];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:photoPath];

    if (!fileExists) {
        photoPath = [[OSVUtils createOSCBasePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%ld/track.txt", (long)seq.uid]];
        metadataMime = @{@"contentType" : @"text/plain",
                         @"format"      : @"txt"};
        
        fileExists = [[NSFileManager defaultManager] fileExistsAtPath:photoPath];
    }
    
    if (!fileExists) {
        NSArray *properties = [NSArray arrayWithObjects: NSURLLocalizedNameKey, NSURLLocalizedTypeDescriptionKey, nil];
        
        NSArray *arra1y = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL URLWithString:[[OSVUtils createOSCBasePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld", (long)seq.uid]]]
                                                        includingPropertiesForKeys:properties
                                                                           options:(NSDirectoryEnumerationSkipsHiddenFiles)
                                                                             error:nil];
        
        NSMutableString *longString = [@"" mutableCopy];
        
        for (NSString *fileName in arra1y) {
            [longString appendString:[NSString stringWithFormat:@" %@", [fileName lastPathComponent]]];
        }
        
        [Answers logCustomEventWithName:@"fileCrashAvoided" customAttributes:@{@"Files":longString}];
        
        return nil;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:photoPath];
    
    NSDictionary *dictionary = @{ @"metadataMime"   : metadataMime,
                                  @"data"           : data};
    
    return dictionary;
}

- (void)callEveryTwentySeconds {
    [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"will stay alive"]  withLevel:LogLevelDEBUG];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

@end
