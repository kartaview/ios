//
//  OSVAPI+Sequences.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVAPI.h"
#import "OSVUser.h"
#import "OSVBoundingBox.h"

#import "OSVAPIUtils.h"

#import "OSVServerSequence+Convertor.h"

#import "OSVAPISpeedometer.h"

#define kNewSequneceMethod      @"sequence"
#define kLayersMethod           @"nearby-tracks"
#define kMyListSequnceMethod    @"list/my-list"
#define kFinishedUploading      @"sequence/finished-uploading"
#define kSequncesRemoveMethod   @"sequence/remove"
#define kTracksMethod           @"tracks"

@interface OSVAPI ()

@property (nonatomic, strong) NSMutableData         *mutableData;

@property (nonatomic, copy) void (^didFinishUpload)(NSInteger photoId, NSError *_Nullable error);

@property (nonatomic, copy, nullable) void (^uploadProgressBlock)(long long totalBytes, long long totalBytesExpected);

@end

@implementation OSVAPI (Sequences)

#pragma mark - Upload Requests

- (void)requestNewSequenceIdForUser:(nonnull id<OSVUser>)user withSequence:(nonnull OSVSequence *)seq metadata:(NSDictionary *)metaDataDict withProgressBlock:(void (^)(long long tBytes, long long tBExpected))uploadProgressBlock completionBlock:(nullable void (^)(NSInteger sequenceId, NSError * _Nullable error))completionBlock  {
    
    OSVPhoto *photo = nil;
    if (seq.photos.count) {
        photo = seq.photos[0];
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@/", [self.configurator osvBaseURL], [self.configurator osvAPIVerion], kNewSequneceMethod]];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    NSString *access_token      = user.accessToken;
    
    NSData   *metaData          = metaDataDict[@"data"];
    NSNumber *obdInfo           = @(seq.hasOBD?1:0);
    NSString *appVersion        = [self.configurator appVersion];
    NSString *platformVersion   = [self.configurator platformVersion];
    NSString *platformName      = [self.configurator platformName];
    NSString *currentCoordinate = [NSString stringWithFormat:@"%f,%f", photo.photoData.location.coordinate.latitude, photo.photoData.location.coordinate.longitude];
    NSString *uploadSource      = [self.configurator platformName];
    
    NSStringEncoding stringEncoding = NSUTF8StringEncoding;
    NSString *boundaryString    = [OSVAPIUtils generateRandomBoundaryString];
    NSString *value             = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundaryString];
    [urlRequest setValue:value forHTTPHeaderField:@"Content-Type"];
    
    @autoreleasepool {
        [urlRequest setHTTPBody:[OSVAPIUtils multipartFormDataQueryStringFromParameters:NSDictionaryOfVariableBindings(access_token, metaData, obdInfo, platformName, platformVersion, uploadSource, appVersion, currentCoordinate) withEncoding:stringEncoding boundary:boundaryString parametersInfo:@{@"metaData" : metaDataDict[@"metadataMime"]}]];
    }
    [urlRequest setHTTPMethod:@"POST"];
    
    boundaryString = nil;
    
    self.mutableData = [NSMutableData data];
    self.didFinishUpload = completionBlock;
    self.uploadProgressBlock = uploadProgressBlock;
    
    //Each background session needs a unique ID, so get a random number
    NSInteger randomNumber = arc4random() % 1000000;
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[NSString stringWithFormat:@"savedSession.identifier.%ld", (long)randomNumber]];
    config.HTTPMaximumConnectionsPerHost = 1;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:_requestsQueue];
    //Set the session ID in the sending message structure so we can retrieve it from the
    //delegate methods later
    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithStreamedRequest:urlRequest];
    [uploadTask resume];

    [self.speedometer startSpeedCalculationTimer];
};

- (void)finishUploadingSequenceWithID:(NSInteger)uid forUser:(id<OSVUser>)user withCompletionBlock:(void (^)(NSError *error))completionBlock {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@/", [self.configurator osvBaseURL], [self.configurator osvAPIVerion], kFinishedUploading]];

    NSNumber *sequenceId        = @(uid);
    NSString *access_token      = user.accessToken;
    
    AFHTTPRequestOperation *requestOperation = [OSVAPIUtils requestWithURL:url parameters:NSDictionaryOfVariableBindings(sequenceId, access_token) method:@"POST"];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!operation.isCancelled) {
            completionBlock(nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (!operation.isCancelled) {
            completionBlock(error);
        }
    }];
    [self.requestsQueue addOperation:requestOperation];
}

#pragma mark - List Requests

- (void)listMySequncesForUser:(id<OSVUser>)user atPage:(NSInteger)pageIndex withCompletionBlock:(void (^)(NSArray *, NSError *, OSVMetadata *))completionBlock {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@/", [self.configurator osvBaseURL], [self.configurator osvAPIVerion], kMyListSequnceMethod]];
    
    NSNumber *ipp               = @50;
    NSNumber *page              = @(pageIndex + 1);

    NSString *access_token      = user.accessToken;
    
    AFHTTPRequestOperation *requestOperation = [OSVAPIUtils requestWithURL:url parameters:NSDictionaryOfVariableBindings(page, ipp, access_token) method:@"POST"];
    
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!operation.isCancelled) {
            if (!responseObject) {
                completionBlock(nil, [NSError errorWithDomain:@"OSVAPI" code:1 userInfo:@{@"Response":@"NoResponse"}], [OSVMetadata metadataError]);
                return;
            }
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
            NSArray *array = response[@"currentPageItems"];
            NSMutableArray *sequenceArray = [NSMutableArray array];
            for (NSDictionary *dictionary in array) {
                OSVServerSequence *sequence = [OSVServerSequence sequenceFromDictionary:dictionary];
                [sequenceArray addObject:sequence];
            }
            
            OSVMetadata *meta = [OSVMetadata new];
            NSArray *totalItems = response[@"totalFilteredItems"];
            NSInteger numberOfItems = ((NSNumber *)totalItems.firstObject).integerValue;
            meta.totalItems = numberOfItems;
            meta.pageIndex = pageIndex;
            meta.itemsPerPage = [ipp integerValue];
            meta.index = pageIndex * meta.itemsPerPage;
            
            completionBlock(sequenceArray, nil, meta);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (!operation.isCancelled) {
            completionBlock(nil, error, [OSVMetadata metadataError]);
        }
    }];
    
    [_requestsQueue addOperation:requestOperation];
    
}

- (NSOperation *)listTracksForUser:(id<OSVUser>)user atPage:(NSInteger)pageIndex
                     inBoundingBox:(id<OSVBoundingBox>)box
                          withZoom:(double)zomParam
               withCompletionBlock:(void (^)(NSArray *, NSError *, OSVMetadata *))completionBlock {
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@/", [self.configurator osvBaseURL], [self.configurator osvAPIVerion], kTracksMethod]];
        
    AFHTTPRequestOperation *requestOperation;
    
    NSNumber *ipp               = @300;
    NSNumber *page              = @(pageIndex + 1);
    //adding optional bounding box parameter
    if (box) {
        NSString *bbTopLeft = [NSString stringWithFormat:@"%f,%f", box.topLeftCoordinate.latitude, box.topLeftCoordinate.longitude];
        NSString *bbBottomRight = [NSString stringWithFormat:@"%f,%f", box.bottomRightCoordinate.latitude, box.bottomRightCoordinate.longitude];
        NSNumber *zoom = @(zomParam);
        requestOperation = [OSVAPIUtils requestWithURL:url parameters:NSDictionaryOfVariableBindings(bbTopLeft, bbBottomRight, zoom, ipp, page) method:@"POST"];
    }
    
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            if (!operation.isCancelled) {
                if (!responseObject) {
                    completionBlock(nil, [NSError errorWithDomain:@"OSVAPI" code:1 userInfo:@{@"Response":@"NoResponse"}], [OSVMetadata metadataError]);
                    return;
                }
                NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
                NSArray *array = response[@"currentPageItems"];
                
                NSMutableArray *sequenceArray = [NSMutableArray array];
                
                for (NSDictionary *seqDictionary in array) {
                    OSVServerSequence *sequence = [OSVServerSequence trackFromDictionary:seqDictionary];
                    if (sequence) {
                        [sequenceArray addObject:sequence];
                    } else {
                        NSLog(@"removed somethig");
                    }
                    
                }

                dispatch_async(dispatch_get_main_queue() , ^{

                    OSVMetadata *meta = [OSVMetadata new];
                    NSArray *totalItems = response[@"totalFilteredItems"];
                    NSInteger numberOfItems = ((NSNumber *)totalItems.firstObject).integerValue;
                    meta.totalItems = numberOfItems;
                    meta.pageIndex = pageIndex;
                    meta.itemsPerPage = [ipp integerValue];
                    meta.index = 0;

                    completionBlock(sequenceArray, nil, meta);
                });
            } else {
                completionBlock(nil, nil, nil);
            }
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (!operation.isCancelled) {
            completionBlock(nil, error, [OSVMetadata metadataError]);
        } else {
            completionBlock(nil, nil, nil);
        }
    }];
    
    [_requestsQueue addOperation:requestOperation];
    
    return requestOperation;
}


- (void)getLayersFromLocation:(CLLocationCoordinate2D)coordinate radius:(double)dist withCompletion:(nullable void (^)(NSArray *_Nullable, NSError *_Nullable))completionBlock {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [self.configurator osvBaseURL], kLayersMethod]];
    
    NSNumber *lat               = @(coordinate.latitude);
    NSNumber *lng               = @(coordinate.longitude);
    NSNumber *distance          = @(dist);
    
    AFHTTPRequestOperation *requestOperation;
    //adding optional bounding box parameter
    requestOperation = [OSVAPIUtils requestWithURL:url parameters:NSDictionaryOfVariableBindings(lat, lng, distance) method:@"POST"];
    
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!operation.isCancelled) {
            if (!responseObject) {
                completionBlock(nil, [NSError errorWithDomain:@"OSVAPI" code:1 userInfo:@{@"Response":@"NoResponse"}]);
                return;
            }
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
            NSDictionary *osvDict = response[@"osv"];
            NSMutableArray *sequenceArray = [NSMutableArray array];
            
            if ([osvDict isKindOfClass:[NSDictionary class]]) {
                NSArray *array = osvDict[@"sequences"];
                
                for (NSDictionary *dictionary in array) {
                    OSVServerSequencePart *sequence = [OSVServerSequence sequenceFormDictionaryPart:dictionary];
                    [sequenceArray addObject:sequence];
                }
            }
            
            completionBlock(sequenceArray, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (!operation.isCancelled) {
            completionBlock(nil, error);
        }
    }];
    
    [_requestsQueue addOperation:requestOperation];

}

#pragma mark - Delete requests

- (void)deleteSequence:(OSVServerSequence *)sequence forUser:(id<OSVUser>)user withCompletionBlock:(void (^)(NSError *error))completionBlock {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@/", [self.configurator osvBaseURL], [self.configurator osvAPIVerion], kSequncesRemoveMethod]];
    
    NSNumber *sequenceId        = @(sequence.uid);

    NSString *access_token      = user.accessToken;
    
    AFHTTPRequestOperation *requestOperation = [OSVAPIUtils requestWithURL:url parameters:NSDictionaryOfVariableBindings(sequenceId, access_token) method:@"POST"];
    
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!operation.isCancelled) {
            if (!responseObject) {
                completionBlock([NSError errorWithDomain:@"OSVAPI" code:1 userInfo:@{@"Response":@"NoResponse"}]);
                return;
            }
            completionBlock(nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (!operation.isCancelled) {
            completionBlock(error);
        }
    }];
    
    [_requestsQueue addOperation:requestOperation];
}

@end
