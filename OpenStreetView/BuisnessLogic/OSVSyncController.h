//
//  OSVSyncController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 11/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OSVPhoto.h"
#import "OSVSequence.h"
#import "OSVMetadata.h"
#import "OSVBoundingBox.h"

#import "OSVTrackSyncController.h"
#import "OSVPhotoSyncController.h"

#import "OSVSyncUtils.h"

typedef enum {
    OSVReachabilityStatusNotReachable,
    OSVReachabilityStatusWiFi,
    OSVReachabilityStatusCellular
}OSVReachabilityStatus;

@interface OSVSyncController : NSObject

@property (nonatomic, copy) void                (^didChangeReachabliyStatus)(OSVReachabilityStatus status);

@property (nonatomic) OSVTrackSyncController    *tracksController;
@property (nonatomic) OSVTrackLogger            *logger;

+ (instancetype)sharedInstance;

+ (BOOL)isUploading;

+ (long long)sizeOnDiskForSequences;
+ (long long)sizeOnDiskForSequence:(id<OSVSequence>)sequence;

+ (BOOL)hasSequencesToUpload;

@end
