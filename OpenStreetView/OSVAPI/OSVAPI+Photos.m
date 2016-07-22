//
//  OSVAPI+Photos.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVAPI.h"
#import "OSVUser.h"
#import "OSVAPIUtils.h"
#import "OSVServerPhoto+Convertor.h"
#import "OSVAPISpeedometer.h"

#import "OSVUserDefaults.h"

#define kUploadPhotoMethod      @"photo"
#define kPhotoRemoveMethod      @"photo/remove"
#define kListPhotosMethod       @"sequence/photo-list"
#define kGetImageMethod         @""

@interface OSVAPI () 

@property (nonatomic, strong) NSMutableData *mutableData;

@property (nonatomic, copy) void (^didFinishUpload)(NSInteger photoId, NSError *_Nullable error);
@property (nonatomic, copy) void (^uploadProgressBlock)(long long totalBytesSent, long long totalBytesExpected);

@end

@implementation OSVAPI (Photos)

- (NSURL *)imageURLForPhoto:(OSVServerPhoto *)photo {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [self.configurator osvBaseURL], photo.imageName]];
}

- (NSURL *)thumbnailURLForPhoto:(OSVServerPhoto *)photo {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [self.configurator osvBaseURL], photo.thumbnailName]];
}

- (NSURL *)previewURLForTrack:(OSVServerSequence *)track {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [self.configurator osvBaseURL], track.previewImage]];
}


- (void)uploadPhoto:(OSVPhoto *)photoObject withProgressBlock:(void (^)(long long totalBytesSent, long long totalBytesExpected))uploadProgressBlock andCompletionBlock:(void (^)(NSInteger photoId, NSError *error))completionBlock {
    NSAssert(photoObject.serverSequenceId, @"the server sequence id is missing");
    @autoreleasepool {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@/", [self.configurator osvBaseURL], [self.configurator osvAPIVerion], kUploadPhotoMethod]];
        
        NSString *coordinate = [NSString stringWithFormat:@"%f,%f", photoObject.photoData.location.coordinate.latitude, photoObject.photoData.location.coordinate.longitude];
        NSNumber *sequenceId = @(photoObject.serverSequenceId);
        NSNumber *sequenceIndex = @(photoObject.photoData.sequenceIndex);
        NSString *headers = [NSString stringWithFormat:@"%f", photoObject.photoData.location.course];
        NSString *gpsAccuracy = [NSString stringWithFormat:@"%f", photoObject.photoData.location.horizontalAccuracy];
        NSData *photo = nil;
        
        if (photoObject.imageData) {
            photo = photoObject.imageData;
        } else {
            photo = UIImageJPEGRepresentation(photoObject.image, 1.0);
        }
        
        NSMutableURLRequest *urlrequest = [[NSMutableURLRequest alloc] initWithURL:url];
        
        NSStringEncoding stringEncoding = NSUTF8StringEncoding;
        NSString *boundaryString = [OSVAPIUtils generateRandomBoundaryString];
        NSString *value = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundaryString];
        [urlrequest setValue:value forHTTPHeaderField:@"Content-Type"];
        @autoreleasepool {
            [urlrequest setHTTPBody:[OSVAPIUtils multipartFormDataQueryStringFromParameters:NSDictionaryOfVariableBindings(coordinate, sequenceId, sequenceIndex, photo, headers, gpsAccuracy) withEncoding:stringEncoding boundary:boundaryString parametersInfo:@{@"photo":@{@"contentType":@"image/jpeg", @"format":@"jpeg"}}]];
        }
        [urlrequest setHTTPMethod:@"POST"];
        
        boundaryString = nil;
        
        self.mutableData = [NSMutableData data];
        self.didFinishUpload = completionBlock;
        self.uploadProgressBlock = uploadProgressBlock;
      
        //Prepare upload request
        
        //Each background session needs a unique ID, so get a random number
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[NSString stringWithFormat:@"savedSession.identifier.%f", [[NSDate date] timeIntervalSince1970]]];
        config.HTTPMaximumConnectionsPerHost = 1;
        config.allowsCellularAccess = [OSVUserDefaults sharedInstance].useCellularData;
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:_requestsQueue];
        
        //Set the session ID in the sending message structure so we can retrieve it from the
        //delegate methods later
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithStreamedRequest:urlrequest];
        [uploadTask resume];
        [self.speedometer startSpeedCalculationTimer];
    }
}

- (void)listPhotosForUser:(id<OSVUser>)user withSequence:(OSVServerSequence *)sequence completionBlock:(void (^)(NSMutableArray * _Nullable, NSError * _Nullable))completionBlock {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@/", [self.configurator osvBaseURL], [self.configurator osvAPIVerion], kListPhotosMethod]];
    
    NSNumber *sequenceId        = @(sequence.uid);
    NSString *externalUserId    = [NSString stringWithFormat:@"%ld", (long)user.userID];
    NSString *access_token      = user.accessToken;
    NSString *userType          = safeString(user.type);
    
    AFHTTPRequestOperation *requestOperation = [OSVAPIUtils requestWithURL:url parameters:NSDictionaryOfVariableBindings(sequenceId, externalUserId, userType, access_token) method:@"POST"];
    
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!operation.isCancelled) {
            if (!responseObject) {
                completionBlock(nil, [NSError errorWithDomain:@"OSVAPI" code:1 userInfo:@{@"Response":@"NoResponse"}]);
                return;
            }
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
            NSDictionary *osv = response[@"osv"];
            NSArray *photos = osv[@"photos"];
            NSMutableArray *photosArray = [NSMutableArray array];

            CLLocationCoordinate2D topLeftLocation = CLLocationCoordinate2DMake(1000, -1000);
            CLLocationCoordinate2D bottomRightLocation = CLLocationCoordinate2DMake(-1000, 1000);

            sequence.length = 0;
            for (NSDictionary *dictionary in photos) {
                OSVServerPhoto *photo = [OSVServerPhoto photoFromDictionary:dictionary];
                
                OSVServerPhoto *lastPhoto = photosArray.lastObject;
                if (lastPhoto && lastPhoto != photo) {
                    sequence.length +=  [photo.photoData.location distanceFromLocation:lastPhoto.photoData.location];
                }
                
                [photosArray addObject:photo];
                
                if (topLeftLocation.latitude > photo.photoData.location.coordinate.latitude) {
                    topLeftLocation.latitude = photo.photoData.location.coordinate.latitude;
                }
                if (topLeftLocation.longitude < photo.photoData.location.coordinate.longitude) {
                    topLeftLocation.longitude = photo.photoData.location.coordinate.longitude;
                }
                
                if (bottomRightLocation.latitude < photo.photoData.location.coordinate.latitude) {
                    bottomRightLocation.latitude = photo.photoData.location.coordinate.latitude;
                }
                
                if (bottomRightLocation.longitude > photo.photoData.location.coordinate.longitude) {
                    bottomRightLocation.longitude = photo.photoData.location.coordinate.longitude;
                }
            }
            
            if (photosArray.count) {
                sequence.topLeftCoordinate = topLeftLocation;
                sequence.bottomRightCoordinate = bottomRightLocation;
            }
            
            completionBlock(photosArray, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (!operation.isCancelled) {
            completionBlock(nil, error);
        }
    }];
    
    [_requestsQueue addOperation:requestOperation];
}

- (void)deletePhoto:(OSVServerPhoto *)photo forUser:(id<OSVUser>)user withCompletionBlock:(void (^)(NSError *error))completionBlock {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@/", [self.configurator osvBaseURL], [self.configurator osvAPIVerion], kPhotoRemoveMethod]];
    
    NSNumber *photoId = @(photo.photoId);
    NSNumber *externalUserId = @(user.userID);
    NSString *userType = safeString(user.type);
    NSString *access_token = user.accessToken;

    AFHTTPRequestOperation *requestOperation = [OSVAPIUtils requestWithURL:url parameters:NSDictionaryOfVariableBindings(photoId, externalUserId, userType, access_token) method:@"POST"];
    
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
