//
//  OSVUserDefaults.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import <CoreMedia/CMFormatDescription.h>
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

#define k5MPQuality             @"k5MPQuality"
#define k8MPQuality             @"k8MPQuality"
#define k12MPQuality            @"k12MPQuality"

#define kMetricSystem           @"kMetricSystem"
#define kImperialSystem         @"kImperialSystem"

@interface OSVUserDefaults : NSObject

@property (nonatomic, assign) BOOL      automaticUpload;

//if on use wifi & cellular else use only wifi
@property (nonatomic, assign) BOOL      useCellularData;
//distance unit persistence;
@property (nonatomic, assign) NSString  *distanceUnitSystem;
@property (nonatomic, assign) BOOL      automaticDistanceUnitSystem;

@property (nonatomic, strong) NSString  *environment;

@property (nonatomic, assign) BOOL      hdrOption;

@property (nonatomic, assign) BOOL      realPositions;

@property (nonatomic, strong) NSString  *userName;

@property (nonatomic, assign) BOOL      isFreshInstall;

@property (nonatomic, assign) BOOL      isUploading;

@property (nonatomic, assign) NSString  *videoQuality;

@property (nonatomic, assign, readonly) CMVideoDimensions videoQualityDimension;

@property (nonatomic, strong) NSString  *bleDevice;

@property (nonatomic, assign) BOOL      debugLogOBD;
@property (nonatomic, assign) BOOL      debugSLUS;
@property (nonatomic, assign) float     debugFrameRate;
@property (nonatomic, assign) float     debugFrameSize;
@property (nonatomic, assign) float     debugBitRate;
@property (nonatomic, assign) NSString  *debugEncoding;
@property (nonatomic, assign) BOOL      debugHighDesintyOn;

@property (nonatomic, assign) BOOL      useImageRecognition;

+ (instancetype)sharedInstance;
- (void)save;

@end
