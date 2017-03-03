//
//  OSVAPI+Video.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 13/05/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVAPI.h"
#import "OSVAPIUtils.h"
#import "OSVUserDefaults.h"
#import "OSVVideo.h"
#import "OSVAPISpeedometer.h"
#import "OSVUser.h"

#define kUploadVideoMethod      @"video"

@interface OSVAPI ()

@property (nonatomic, strong) NSMutableData         *mutableData;
@property (nonatomic, copy) void (^didFinishUpload)(NSInteger photoId, NSError *_Nullable error);
@property (nonatomic, copy, nullable) void (^uploadProgressBlock)(long long totalBytes, long long totalBytesExpected);

@end

@implementation OSVAPI (Video)

- (NSURLSessionUploadTask *)uploadVideo:(OSVVideo *)videoObj
                                forUser:(id<OSVUser>)user
                      withProgressBlock:(void (^)(long long totalBytesSent, long long totalBytesExpected))uploadProgressBlock
                     andCompletionBlock:(void (^)(NSInteger videoId, NSError *error))completionBlock {
    @autoreleasepool {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@/", [self.configurator osvBaseURL], [self.configurator osvAPIVerion], kUploadVideoMethod]];
        NSMutableURLRequest *urlrequest = [[NSMutableURLRequest alloc] initWithURL:url];
        
        NSNumber *sequenceId    = @(videoObj.uid);
        NSNumber *sequenceIndex = @(videoObj.videoIndex);
        NSString *access_token  = user.accessToken;
        
        NSStringEncoding stringEncoding = NSUTF8StringEncoding;
        NSString *boundaryString        = [OSVAPIUtils generateRandomBoundaryString];
        NSString *value                 = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundaryString];
        
        [urlrequest setValue:value forHTTPHeaderField:@"Content-Type"];
        
        NSData *video = [NSData dataWithContentsOfFile:videoObj.videoPath];
        if (!video) {
            return nil;
        }
        
        @autoreleasepool {
            [urlrequest setHTTPBody:[OSVAPIUtils multipartFormDataQueryStringFromParameters:NSDictionaryOfVariableBindings(sequenceId, sequenceIndex, video, access_token) withEncoding:stringEncoding boundary:boundaryString parametersInfo:@{@"video":@{@"contentType":@"video/mp4", @"format":@"mp4"}}]];
        }
        [urlrequest setHTTPMethod:@"POST"];
        
        self.mutableData = [NSMutableData data];
        self.didFinishUpload = completionBlock;
        self.uploadProgressBlock = uploadProgressBlock;
        
        boundaryString = nil;
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[NSString stringWithFormat:@"savedSession.identifier.%f", [[NSDate date] timeIntervalSince1970]]];
        config.HTTPMaximumConnectionsPerHost = 1;
        config.allowsCellularAccess = [OSVUserDefaults sharedInstance].useCellularData;
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:_requestsQueue];
        
        //Set the session ID in the sending message structure so we can retrieve it from the
        //delegate methods later
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithStreamedRequest:urlrequest];
        [uploadTask resume];
        
        [self.speedometer startSpeedCalculationTimer];
        
        return uploadTask;
    }
}

@end
