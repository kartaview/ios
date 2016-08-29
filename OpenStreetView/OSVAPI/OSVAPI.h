//
//  OSVAPI.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 18/09/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSVServerSequence.h"
#import "OSVServerPhoto.h"
#import "OSVSequence.h"
#import "OSVMetadata.h"
#import "AFHTTPRequestOperation.h"
#import "OSVAPIConfigurator.h"
#import "OSVVideo.h"

@protocol OSVUser;
@protocol OSVBoundingBox;
@protocol OSVAPIConfigurator;

@class OSVAPISpeedometer;

@interface OSVAPI : NSObject <NSURLSessionDelegate> {
@private
    NSOperationQueue *_requestsQueue;
    NSOperationQueue *_serialQueue;
}

@property (nonatomic, strong, readonly, nonnull) NSOperationQueue *requestsQueue;
@property (nonatomic, strong, readonly, nonnull) NSOperationQueue *serialQueue;

@property (nonatomic, weak, nullable) id<OSVAPIConfigurator> configurator;
@property (nonatomic, strong, nonnull) OSVAPISpeedometer     *speedometer;

@end

@interface OSVAPI (Login)
//authenticate user
- (void)authenticateUser:(nonnull id<OSVUser>)user
          withCompletion:(nullable void (^)(NSError *_Nullable error))completion;

- (void)getUserInfo:(nonnull id<OSVUser>)user
     withCompletion:(nullable void (^)(id<OSVUser> _Nullable user, NSError *_Nullable error))completion;

@end

@interface OSVAPI (Ranking)

- (void)leaderBoardWithCompletion:(nullable void (^)(NSArray *_Nullable leaderBoard, NSError *_Nullable error))completion;

@end

@interface OSVAPI (Version)

- (void)getApiVersionWithCompletion:(nullable void (^)(double version, NSError *_Nullable error))completion;
- (nonnull NSURL *)getAppLink;

@end

@interface OSVAPI (Photos)

//upload photos
- (void)uploadPhoto:(nonnull OSVPhoto *)photo
  withProgressBlock:(nullable void (^)(long long totalBytes, long long totalBytesExpected))uploadProgress
 andCompletionBlock:(nullable void (^)(NSInteger photoId,  NSError *_Nullable error))completionBlock;

//list photos
- (void)listPhotosForUser:(nonnull id<OSVUser>)user
             withSequence:(nonnull OSVServerSequence *)sequence
          completionBlock:(nullable void (^)(NSMutableArray *_Nullable photos, NSError *_Nullable error))completionBlock;
//delete photo
- (void)deletePhoto:(nonnull OSVServerPhoto *)photo
            forUser:(nonnull id<OSVUser>)user
withCompletionBlock:(nullable void (^)(NSError *_Nullable error))completionBlock;

//get image
- (nonnull NSURL *)imageURLForPhoto:(nonnull OSVServerPhoto *)photo;
- (nonnull NSURL *)thumbnailURLForPhoto:(nonnull OSVServerPhoto *)photo;
- (nonnull NSURL *)previewURLForTrack:(nonnull OSVServerSequence *)track;

@end

@interface OSVAPI (Video)
//upload video
- (nonnull NSURLSessionUploadTask *)uploadVideo:(nonnull OSVVideo *)video
  withProgressBlock:(nullable void (^)(long long totalBytesSent, long long totalBytesExpected))uploadProgressBlock
 andCompletionBlock:(nullable void (^)(NSInteger videoId,  NSError * _Nullable error))completionBlock;

@end

@interface OSVAPI (Sequences)

//start new sequence with sequence
- (void)requestNewSequenceIdForUser:(nonnull id<OSVUser>)user
                       withSequence:(nonnull OSVSequence *)seq
                           metadata:(nonnull NSDictionary *)metaDataDict
                  withProgressBlock:(nullable void (^)(long long totalBytes, long long totalBytesExpected))uploadProgressBlock
                    completionBlock:(nullable void (^)(NSInteger sequenceId, NSError * _Nullable error))completionBlock;
//upload sequence
- (void)uploadSequence:(nonnull OSVSequence *)sequence
               forUser:(nonnull id<OSVUser>)user
   withCompletionBlock:(nullable void (^)(NSError *_Nullable error))completionBlock
     partialCompletion:(nullable void (^)(id<OSVPhoto> _Nullable photo, NSError *_Nullable error))patialCompletion;
//finish upload
- (void)finishUploadingSequenceWithID:(NSInteger)uid
                              forUser:(nonnull id<OSVUser>)user
                  withCompletionBlock:(nullable void (^)(NSError *_Nullable error))completionBlock;
//list track
- (nonnull NSOperation *)listTracksForUser:(nonnull id<OSVUser>)user
                                    atPage:(NSInteger)pageIndex
                             inBoundingBox:(nullable id<OSVBoundingBox>)box
                                  withZoom:(double)zoom
                       withCompletionBlock:(nullable void (^)(NSArray *_Nullable, NSError *_Nullable, OSVMetadata *_Nullable))completionBlock;
//list layers
- (void)getLayersFromLocation:(CLLocationCoordinate2D)coordinate
                       radius:(double)distance
               withCompletion:(nullable void (^)(NSArray *_Nullable, NSError *_Nullable))completion;



//list sequences
- (void)listSequencesForUser:(nonnull id<OSVUser>)user
               inBoundingBox:(nullable id<OSVBoundingBox>)box
  withPartialCompletionBlock:(nonnull void (^)(NSArray *_Nullable sequences, NSError *_Nullable error, OSVMetadata *_Nullable))partialBlock;
//paged list sequences and bounding box
- (void)listSequencesForUser:(nonnull id<OSVUser>)user
                      atPage:(NSInteger)pageIndex
               inBoundingBox:(nullable id<OSVBoundingBox>)box
         withCompletionBlock:(nullable void (^)(NSArray *_Nullable sequences, NSError *_Nullable error, OSVMetadata *_Nonnull metadata))completionBlock;
//paged list sequences
- (void)listMySequncesForUser:(nonnull id<OSVUser>)user
                       atPage:(NSInteger)pageIndex
          withCompletionBlock:(nullable void (^)(NSArray *_Nullable sequences, NSError *_Nullable error, OSVMetadata *_Nonnull metadata))completionBlock;
//delete sequence
- (void)deleteSequence:(nonnull OSVServerSequence *)sequence
               forUser:(nonnull id<OSVUser>)user
   withCompletionBlock:(nullable void (^)(NSError *_Nullable error))completionBlock;

@end