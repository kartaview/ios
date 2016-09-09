//
//  OSVTrackSyncController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/02/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVPhotoSyncController.h"
#import "OSVSequence.h"
#import "OSVMetadata.h"
#import "OSVBoundingBox.h"
#import "OSVTrackCache.h"
#import "OSVTrackLogger.h"

@class OSVAPI;

@interface OSVTrackSyncController : OSVPhotoSyncController

@property (nonatomic) OSVTrackCache     *cache;

//Upload sequences
- (void)uploadAllSequencesWithCompletion:(void (^)(NSError *error))completion
                       partialCompletion:(void (^)(OSVMetadata *, NSError *))partialCompletion;

//Get Sequences
//local
- (void)getLocalSequencesWithCompletion:(void (^)(NSArray *sequences))completion;
- (void)getLocalSequenceWithID:(NSInteger)uid completion:(void (^)(OSVSequence *seq))completion;
//tracks
- (void)getServerTracksInBoundingBox:(id<OSVBoundingBox>)box
                            withZoom:(double)zoom
               withPartialCompletion:(void (^)(id<OSVSequence> sequence, OSVMetadata *metadata, NSError *error))partComp;

//server
- (void)cancelGetServerSequences;


- (void)getMyServerSequencesAtPage:(NSInteger)index
                    withCompletion:(void (^)(NSArray *, OSVMetadata *, NSError *))completion;

- (void)getPhotosForTrack:(id<OSVSequence>)seq
      withCompletionBlock:(void (^)(id<OSVSequence>seq , NSError *error))completion;

- (void)getLayersFromLocation:(CLLocationCoordinate2D)coordinate
               withCompletion:(void (^)(NSArray *, NSError *))completion;

//Delete methods
- (void)deleteSequence:(id<OSVSequence>)sequence
   withCompletionBlock:(void (^)(NSError *error))completionBlock;

- (void)deleteLocalTrackWithID:(NSInteger)uid;
- (void)finishUploadingEmptySequencesWithCompletionBlock:(void (^)(NSError *error))completionBlock;

//upload controll
- (void)cancelUploadForPhoto:(OSVPhoto *)photo;

- (void)cancelUpload;
- (void)pauseUpload;
- (void)resumeUpload;
- (void)resumeUploadWithBackgroundTask:(UIBackgroundTaskIdentifier)taskID;

- (BOOL)isUploading;
- (BOOL)isPaused;

@end
