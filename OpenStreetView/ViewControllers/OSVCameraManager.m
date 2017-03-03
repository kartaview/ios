
//
//  OSVCameraManager.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 03/08/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVCameraManager.h"
#import <CoreLocation/CoreLocation.h>

#import "OSVVideoRecorder.h"
#import "OSVSensorLibManager.h"

#import "OSVCameraMapManager.h"

#import "OSVLocationManager.h"
#import <SKMaps/SKMaps.h>

#import "OSVSyncController.h"
#import "OSVUserDefaults.h"
#import "OSVLogger.h"
#import "OSVSyncUtils.h"
#import "OSVUtils.h"
#import "OSVLocalNotificationsController.h"

#import "UIAlertView+Blocks.h"

#import <Accelerate/Accelerate.h>
#import <ImageIO/ImageIO.h>

#import "OSC-Swift.h"

#import "OSVTrackMatcher.h"

#define kMediumGPSQuality 40

@interface OSVCameraManager () <CLLocationManagerDelegate, OSVSensorsManagerDelegate>

//timers
@property (strong, nonatomic) NSTimer                               *badGPSTimer;
@property (strong, nonatomic) NSTimer                               *timerSign;
//speed intervals
@property (nonatomic, strong) NSDictionary<NSArray *, NSNumber *>   *speedIntevals;

//recording
@property (nonatomic, strong) CLLocation                *lastPhotoLocation;
@property (nonatomic, strong) CLLocation                *currentLocation;
@property (atomic, assign) NSInteger                    videoIndex;
@property (atomic, assign) BOOL                         isValidVideo;
@property (nonatomic, assign) BOOL                      hadGPS;
@property (nonatomic, assign) double                    distanceBetweenPhotos;
@property (nonatomic, assign) NSInteger                 currentSequence;

//obd stuff
@property (assign, nonatomic) NSTimeInterval            decay;
@property (assign, nonatomic) NSTimeInterval            lastOBDTimestamp;
@property (assign, nonatomic) double                    obdDistance;

@property (nonatomic) OSVSensorLibManager               *sensorLib;

@property (nonatomic) OSVVideoRecorder                  *videoRecorder;

@property (strong, nonatomic) AVCaptureDeviceFormat      *deviceFormat;
@property (strong, nonatomic) AVCaptureVideoDataOutput   *videoOutput;
@property (strong, nonatomic) dispatch_queue_t           sessionQueue;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

@property (assign, nonatomic) NSInteger                 wishedFreeSpace;
@property (assign, nonatomic) NSInteger                 currentOBDSpeed;
@property (assign, nonatomic) NSInteger                 realDistance;

@property (assign, nonatomic) BOOL                      hadOBD;
@property (assign, nonatomic) BOOL                      hasOBD;

@property (assign, nonatomic) BOOL                      shouldMakePhoto;
@property (assign, nonatomic) BOOL                      isBussyRecording;
@property (assign, nonatomic) BOOL                      isBussyDetecting;

@property (assign, nonatomic) NSInteger                 memoryUsedUntilNow;

@property (assign, nonatomic) double                    frequency;
@property (assign, nonatomic) BOOL                      isHighFrequency;

@property (strong, nonatomic) CLLocation                *lastDistanceLocation;

@property (strong, nonatomic) ScoreManager              *scoreManager;

@end

int const MaxStillImageRequests = 5;

@implementation OSVCameraManager

- (instancetype)initWithOutput:(AVCaptureVideoDataOutput *)videoOutput
                       preview:(AVCaptureVideoPreviewLayer *)layer
                   deviceFromat:(AVCaptureDeviceFormat *)deviceFormat
                          queue:(dispatch_queue_t)sessionQueue {
    self = [super init];
    if (self) {

        self.sessionQueue = sessionQueue;
        self.deviceFormat = deviceFormat;
        self.videoOutput = videoOutput;
        self.previewLayer = layer;
        self.distanceBetweenPhotos = 0;
        self.wishedFreeSpace = 500 * 1000 * 1000;
        self.backgroundRenderingID = UIBackgroundTaskInvalid;
        self.scoreManager = [ScoreManager new];

        self.speedIntevals = @{ @[@1,@10] : @5,
                                @[@10, @30] : @10,
                                @[@30, @50] : @15,
                                @[@50, @90] : @20,
                                @[@90, @120] : @25,
                                @[@120, @(NSNotFound)] : @35};
        
        if (self.isHighFrequency) {
            self.frequency =  1.0 / [OSVUserDefaults sharedInstance].debugFrameRate;
        } else {
            self.frequency = 3.0;
        }

        [[OSVLocationManager sharedInstance] startLocationUpdate];
        [OSVLocationManager sharedInstance].delegate = self;
        [OSVSensorsManager sharedInstance].delegate = self;
        
        CMVideoDimensions dim = CMVideoFormatDescriptionGetDimensions(self.deviceFormat.formatDescription);
        self.videoRecorder = [[OSVVideoRecorder alloc] initWithVideoSize:dim];

        [self addObservers];
        [self initSensorLib];
       
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public

- (void)startHighResolutionCapure {
    self.isRecording = YES;
    self.backgroundRenderingID = UIBackgroundTaskInvalid;
    self.isHighFrequency =  [OSVUserDefaults sharedInstance].debugHighDesintyOn;
    
    [[OSVLogger sharedInstance] logMessage:@"Start new seq." withLevel:LogLevelDEBUG];

    [[OSVSyncController sharedInstance].logger createNewLogFileForSequenceID:self.currentSequence];
    
    AVCaptureVideoOrientation orientation = [[self.previewLayer connection] videoOrientation];
    
    [self.videoRecorder createRecordingWithURL:[OSVUtils fileNameForTrackID:self.currentSequence videoID:self.videoIndex]
                                   orientation:orientation];
    [self.scoreManager startHistorySessionForSequenceID:self.currentSequence];
}

- (void)stopHighResolutionCapture {
    
    [self.badGPSTimer invalidate];
    self.badGPSTimer = nil;
    
    [[OSVSyncController sharedInstance].logger closeLoggFileForSequenceID:self.currentSequence];
    [self.videoRecorder completeRecordingSessionWithBlock:^(BOOL success, NSError *error) {
        if (success) {
            [[OSVLogger sharedInstance] logMessage:@"Video was succesfuly writen." withLevel:LogLevelDEBUG];
        } else {
            [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Failed to Write Video error:%@", error] withLevel:LogLevelDEBUG];
        }
    }];
    
    if (self.frameCount == 0) {
        [OSVSyncUtils removeTrackWithID:self.currentSequence atPath:[OSVUtils createOSCBasePath]];
    } else {
        [OSVLocalNotificationsController scheduleUploadNotification];
    }
    
    self.backgroundRenderingID = UIBackgroundTaskInvalid;
    self.isRecording = NO;
    [self.scoreManager stopHistorySession];
		
//	[[OSVSensorLibManager sharedInstance] read];
}

- (void)resetValues {
    self.currentOBDSpeed = -1;
    self.obdDistance = 0;
    self.currentSequence = (NSInteger)[[NSDate new] timeIntervalSince1970];
    self.frameCount = 0;
    self.videoIndex = 0;
    self.distanceCoverd = 0;
    self.memoryUsedUntilNow = 0;
    self.decay = 0;
}

- (void)makeStillCaptureWithLocation:(CLLocation *)photoLocation {
    
    if ([OSVUserDefaults sharedInstance].debugHighDesintyOn) {
        return;
    }
    
    if (!self.isRecording) {
        return;
    }
    
    if (self.wishedFreeSpace > [OSVUtils freeDiskSpaceBytes]) {
        self.isRecording = NO;
        [self.delegate willStopCapturing];
        return;
    }
    
    self.lastPhotoLocation = photoLocation;
    
    self.shouldMakePhoto = YES;
}

- (double)score {
    return self.scoreManager.score;
}

- (double)multiplier {
    return self.scoreManager.multiplier;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    __weak typeof(self) welf = self;
    
    CLLocation *location = welf.lastPhotoLocation;
    
    if (self.isHighFrequency) {
        location = welf.currentLocation;
    }
    
    if (location.coordinate.latitude == 0.0 || location.coordinate.longitude == 0.0) {
        location = nil;
    }
    
    if (self.isRecording &&
        (self.isHighFrequency || self.shouldMakePhoto) &&
        !self.isBussyRecording &&
        location) {
        
        self.isBussyRecording = YES;
        self.shouldMakePhoto = NO;
        AVCaptureVideoOrientation orientation = [[self.previewLayer connection] videoOrientation];
        NSTimeInterval dateLocation = [[NSDate new] timeIntervalSince1970];
        @autoreleasepool {
            CVPixelBufferRef pixelsBuffer = CVPixelBufferRetain(CMSampleBufferGetImageBuffer(sampleBuffer));
            CFDictionaryRef dictionaryRef = (CFDictionaryRef)CMGetAttachment(sampleBuffer, kCGImagePropertyExifDictionary, NULL);
            NSDictionary *currentListing = (__bridge NSDictionary *) dictionaryRef;

            if (pixelsBuffer) {

                NSInteger rotation = kRotate0DegreesClockwise;
                if (orientation == AVCaptureVideoOrientationPortrait) {
                    rotation = kRotate90DegreesClockwise;
                } if (orientation == AVCaptureVideoOrientationLandscapeLeft) {
                    rotation = kRotate180DegreesClockwise;
                } else if (orientation == AVCaptureVideoOrientationLandscapeRight) {
                    rotation = kRotate0DegreesClockwise;
                }
                
                [welf.videoRecorder addPixelBuffer:pixelsBuffer withRotation:rotation completion:^(BOOL success) {
                    welf.isValidVideo = YES;
                    OSVPhoto *photo = [OSVPhoto new];
                    
                    if (success) {
                        photo.photoData = [OSVPhotoData new];
                        photo.photoData.location = location;
                        photo.photoData.timestamp = dateLocation;
                        photo.photoData.sequenceIndex = welf.frameCount;
                        photo.photoData.videoIndex = welf.videoIndex;
                        photo.localSequenceId = welf.currentSequence;
                        photo.hasOBD = welf.hasOBD;
                        welf.frameCount++;
                        
                        OSVLogItem *item = [OSVLogItem new];
                        item.photodata = photo.photoData;
                        
                        [[OSVSyncController sharedInstance].tracksController savePhoto:photo];
                        [[OSVSyncController sharedInstance].logger logItem:item];
						
//						if (welf.frameCount == 1) {
//							[[OSVSensorLibManager sharedInstance] createNewTrackWithInfo:currentListing trackID:welf.currentSequence];
//						} else {
//							[[OSVSensorLibManager sharedInstance] addPhotoWithInfo:currentListing
//																	withFrameIndex:welf.frameCount];
//						}

                        OSVTrackMatcher *matcher = welf.matcher;
                        if (!welf.matcher) {
                            matcher = welf.cameraMapManager.matcher;
                        }
                        
                        if (matcher.hasCoverage) {
                            OSVPolyline *polyline = [matcher nearestPolylineToLocation:location];
                            [welf.scoreManager madePhotoOnSegment:polyline withOBD:welf.hasOBD];
                            [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"madePhoto - coverage:%ld", polyline.coverage]  withLevel:LogLevelDEBUG];
                        } else {
                            [[OSVLogger sharedInstance] logMessage:@"madePhoto - missing coverage data"  withLevel:LogLevelDEBUG];
                            [welf.scoreManager madePhotoWithOBD:welf.hasOBD];
                        }
                        
                        [welf.delegate didReceiveUIUpdate];
                    }
                    
                    if (welf.backgroundRenderingID == UIBackgroundTaskInvalid && photo.photoData.sequenceIndex != 0 && (photo.photoData.sequenceIndex + 1) % 50 == 0) {
                        welf.videoIndex++;
                        [welf.videoRecorder completeRecordingSessionWithBlock:^(BOOL success, NSError *error) {
                            
                            if (!success) {
                                [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Failed to Write Video error:%@", error] withLevel:LogLevelDEBUG];
                            }
                            
                            AVCaptureVideoOrientation orientation = [[welf.previewLayer connection] videoOrientation];
                            welf.memoryUsedUntilNow += [welf.videoRecorder currentVideoSize];
                            
                            [welf.videoRecorder createRecordingWithURL:[OSVUtils fileNameForTrackID:welf.currentSequence videoID:welf.videoIndex]
                                                           orientation:orientation];
                            welf.isValidVideo = NO;
                            if (self.isHighFrequency) {
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(welf.frequency * NSEC_PER_SEC)), welf.sessionQueue, ^{
                                    welf.isBussyRecording = NO;
                                });
                            } else {
                                welf.isBussyRecording = NO;
                            }
                        }];
                    } else {
                        if (self.isHighFrequency) {
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(welf.frequency * NSEC_PER_SEC)), welf.sessionQueue, ^{
                                welf.isBussyRecording = NO;
                            });
                        } else {
                            welf.isBussyRecording = NO;
                        }
                    }
                }];
            } else {
                if (self.isHighFrequency) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(welf.frequency * NSEC_PER_SEC)), welf.sessionQueue, ^{
                        welf.isBussyRecording = NO;
                    });
                } else {
                    welf.isBussyRecording = NO;
                }
            }
            
            CVPixelBufferRelease(pixelsBuffer);
        }
    }
    
    if (!self.isBussyRecording &&
        [OSVUserDefaults sharedInstance].useImageRecognition &&
        !self.isBussyDetecting) {
        
        self.isBussyDetecting = YES;
        [self.sensorLib speedLimitsFromSampleBuffer:sampleBuffer
                                     withCompletion:^(NSArray *detections, CVImageBufferRef pixelsBuffer) {
                                         
                                         UIImage *image = [welf.sensorLib imageForSpeedLimit:detections.firstObject];
                                         if (image) {
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [welf startDecayForSign];
                                                 [welf.delegate shouldDisplayTraficSign:image];
                                                 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.20 * NSEC_PER_SEC)), welf.sessionQueue, ^{
                                                     welf.isBussyDetecting = NO;
                                                 });
                                             });
                                         } else {
                                             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.20 * NSEC_PER_SEC)), welf.sessionQueue, ^{
                                                 welf.isBussyDetecting = NO;
                                             });
                                         }
                                     }];
    }
}

#pragma mark - Location Manager

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)newLocationArray {
    [self computeGPSQualityForLocation:[newLocationArray firstObject]];

    if (!self.isRecording) {
        OSVTrackMatcher *matcher = self.matcher;
        if (!self.matcher) {
            matcher = self.cameraMapManager.matcher;
        }
        
        if (matcher.hasCoverage) {
            OSVPolyline *poly = [matcher nearestPolylineToLocation:[newLocationArray firstObject]];
            [self.scoreManager updateMultiplierOnSegment:poly withOBD:self.hasOBD];
            [self.delegate didReceiveUIUpdate];
        }

        return;
    }
    
    self.currentLocation = [newLocationArray firstObject];
    [self computeDistanceWithLocation:[newLocationArray firstObject]];
    
    CLLocation *matchedLocation = [OSVLocationManager sharedInstance].currentMatchedPosition;
    
    [self.delegate didAddNewLocation:matchedLocation];

    OSVLogItem *item = [OSVLogItem new];
    item.location = self.currentLocation;
    [[OSVSyncController sharedInstance].logger logItem:item];
    
    if (!self.lastPhotoLocation || (self.lastPhotoLocation.coordinate.latitude == 0 && self.lastPhotoLocation.coordinate.longitude == 0)) {
        self.lastPhotoLocation = self.currentLocation;
    }
    
    double distance = [self.lastPhotoLocation distanceFromLocation:self.currentLocation];
    
    self.distanceBetweenPhotos = [self distanceBetweenPhotosWithLocation:self.lastPhotoLocation
                                                            nextLocation:self.currentLocation];
    
    if (self.distanceBetweenPhotos > 0 && distance >= self.distanceBetweenPhotos) {
        if (self.currentOBDSpeed < 0) {
            self.lastPhotoLocation = self.currentLocation;
            [self makeStillCaptureWithLocation:self.currentLocation];
        }
    }
    
    [self.matcher getTracks];
}

- (void)computeGPSQualityForLocation:(CLLocation *)newLocation {
    if (newLocation.horizontalAccuracy < 0) {
        [self badGPSHandling];
    } else {
        if (newLocation.horizontalAccuracy <= 15) {
            [self.delegate didChangeGPSStatus:[UIImage imageNamed:@"gPSOK"]];
            self.hadGPS = YES;
            [self.badGPSTimer invalidate];
            self.badGPSTimer = nil;
        } else if (newLocation.horizontalAccuracy <= kMediumGPSQuality) {
            [self.delegate didChangeGPSStatus:[UIImage imageNamed:@"gPSMedium"]];
            self.hadGPS = YES;
            [self.badGPSTimer invalidate];
            self.badGPSTimer = nil;
        } else {
            [self badGPSHandling];
        }
    }
}

- (void)badGPSHandling {
    [self.delegate didChangeGPSStatus:[UIImage imageNamed:@"gPSLow"]];
    
    if (!self.isRecording &&
        self.hadOBD &&
        !(self.currentOBDSpeed < 0)) {
        return;
    }
    
    if (self.hadGPS && !self.badGPSTimer) {
        self.badGPSTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self
                                                          selector:@selector(badGPSShapshot) userInfo:nil
                                                           repeats:YES];
    }
}

- (void)badGPSShapshot {
    if (!self.lastPhotoLocation) {
        CLLocation *localtion = [[CLLocation alloc] initWithCoordinate:[[OSVLocationManager sharedInstance] currentLocation].coordinate
                                                              altitude:0
                                                    horizontalAccuracy:1000
                                                      verticalAccuracy:0
                                                             timestamp:[NSDate new]];
        [self makeStillCaptureWithLocation:localtion];
    } else {
        [self makeStillCaptureWithLocation:[[CLLocation alloc] initWithCoordinate:self.lastPhotoLocation.coordinate
                                                                         altitude:0
                                                               horizontalAccuracy:1000
                                                                 verticalAccuracy:0
                                                                        timestamp:[NSDate new]]];
    }
}

#pragma mark - UIApplication Notifications

- (void)willEnterForgroundNotification:(NSNotification *)notification {
    if (self.isRecording) {
        self.backgroundRenderingID = UIBackgroundTaskInvalid;
        AVCaptureVideoOrientation orientation = [[self.previewLayer connection] videoOrientation];
        [self.videoRecorder createRecordingWithURL:[OSVUtils fileNameForTrackID:self.currentSequence videoID:self.videoIndex]
                                       orientation:orientation];
        self.isValidVideo = NO;
    }
}

- (void)willEnterBackgroundNotification:(NSNotification *)notificaiton {
    if (self.isValidVideo) {
        UIApplication *application = [UIApplication sharedApplication];
        self.backgroundRenderingID = [application beginBackgroundTaskWithName:@"snaptask" expirationHandler:^{
            [application endBackgroundTask:self.backgroundRenderingID];
            self.backgroundRenderingID = UIBackgroundTaskInvalid;
        }];
        
        self.videoIndex++;
        [self.videoRecorder completeRecordingSessionWithBlock:^(BOOL success, NSError *error) {
            
            if (error) {
                [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Failed to Write Video error:%@", error] withLevel:LogLevelDEBUG];
            }
            
            self.memoryUsedUntilNow += [self.videoRecorder currentVideoSize];
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundRenderingID];
        }];
    }
}

#pragma mark - SensorLibManager

- (void)initSensorLib {
    if ([OSVUserDefaults sharedInstance].useImageRecognition) {
        self.sensorLib = [OSVSensorLibManager sharedInstance];
    }
}

#pragma mark - OSVOBDController Notifications

- (void)manager:(OSVSensorsManager *)manager didUpdateOBDData:(OSVOBDData *)data withError:(NSError *)error {
    self.hadOBD = YES;
    self.hasOBD = YES;

    if (!error) {
        [self.badGPSTimer invalidate];
        self.badGPSTimer = nil;

        self.decay = data.timestamp - self.lastOBDTimestamp;
        self.lastOBDTimestamp = data.timestamp;

    // the decay is the time that the car traveled with the previous speed.
        double distance = self.decay * self.currentOBDSpeed;
        self.obdDistance += distance;
        double distanceBetweenPhotos = [self distanceBasedOnSpeed:self.currentOBDSpeed];
        if (distanceBetweenPhotos > 0 && distanceBetweenPhotos <= self.obdDistance) {
            self.lastPhotoLocation = self.currentLocation;
            [self makeStillCaptureWithLocation:self.lastPhotoLocation];
            self.obdDistance = 0.0;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate didChangeOBDInfo:data.speed withError:nil] ;
         });
        self.currentOBDSpeed = data.speed / 3.6;
    } else {
        [self.delegate didChangeOBDInfo:0 withError:error] ;
        self.decay = 0.0;
        self.currentOBDSpeed = -1;
    }
}

- (void)managerDidConnectToOBD:(OSVSensorsManager *)manager {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate hideOBD:NO];
    });
    
    self.hadOBD = YES;
}

- (void)managerDidDisconnectFromOBD:(OSVSensorsManager *)manager {
    if (self.isRecording) {
        [[OSVSensorsManager sharedInstance] reconnectOBD];
    }
    
    self.currentOBDSpeed = -1;
    
    self.hasOBD = NO;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate hideOBD:YES];
    });
}

- (void)managerDidFailToConnectODB:(OSVSensorsManager *)manager {
    self.currentOBDSpeed = -1;
    
    self.hasOBD = NO;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate hideOBD:YES];
    });
}

#pragma mark - Private

- (void)computeDistanceWithLocation:(CLLocation *)location {
    if (location.horizontalAccuracy < 0) {
        return;
    }
    
    if (!self.lastDistanceLocation || (self.lastDistanceLocation.coordinate.latitude == 0 && self.lastDistanceLocation.coordinate.longitude == 0)) {
        self.lastDistanceLocation = location;
    }
    
    CLLocationDistance distance = [self.lastDistanceLocation distanceFromLocation:location];
    if (distance > 10) {
        self.distanceCoverd += distance;
        self.lastDistanceLocation = location;
    }
}

- (void)shouldRemoveCurrentSign {
    [self.timerSign invalidate];
    self.timerSign = nil;
    [self.delegate shouldDisplayTraficSign:nil];
}

- (void)startDecayForSign {
    [self.timerSign invalidate];
    self.timerSign = nil;
    self.timerSign = [NSTimer scheduledTimerWithTimeInterval:2 target:self
                                                    selector:@selector(shouldRemoveCurrentSign)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (NSInteger)usedMemory {
    return self.memoryUsedUntilNow + [self.videoRecorder currentVideoSize];
}

- (BOOL)hasCoverage {
    return self.cameraMapManager.matcher.hasCoverage || self.matcher.hasCoverage;
}

#pragma mark - Helpers

- (void)didLoadNewTracks {
    if (!self.isRecording) {
        OSVTrackMatcher *matcher = self.matcher;
        if (!self.matcher) {
            matcher = self.cameraMapManager.matcher;
        }
        
        CLLocation *location = [[OSVLocationManager sharedInstance] currentLocation];
        if (matcher.hasCoverage &&
            (location.coordinate.latitude != 0.0 && location.coordinate.longitude != 0.0)) {
            
            OSVPolyline *poly = [matcher nearestPolylineToLocation:location];
            [self.scoreManager updateMultiplierOnSegment:poly withOBD:self.hasOBD];
            [self.delegate didReceiveUIUpdate];
        }
    }
}

- (void)addObservers {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForgroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidConnectToOBD:) name:@"kOBDDidConnect" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidDisconnectFromOBD:) name:@"kOBDDidDisconnect" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidFailToConnectODB:) name:@"kOBDFailedToConnectInTime" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLoadNewTracks) name:@"kdidLoadNewBox" object:nil];

}

/*
 http://jira.telenav.com:8080/browse/OSV-9
 */
- (NSInteger)distanceBetweenPhotosWithLocation:(CLLocation *)start nextLocation:(CLLocation *)destination {
    
    if (start == nil || destination == nil) {
        return 0;
    }
    
    BOOL startInvalid = start.horizontalAccuracy < 0;
    BOOL startLowQuality = start.horizontalAccuracy > kMediumGPSQuality;
    
    BOOL destinationInvalid = destination.horizontalAccuracy < 0;
    BOOL destinationLowQuality = destination.horizontalAccuracy > kMediumGPSQuality;
    
    if ((startInvalid || startLowQuality) && (destinationInvalid || destinationLowQuality)) {
        return 0;
    }
    
    startInvalid = start.speed < 0;
    destinationInvalid = destination.speed < 0;
    
    if (startInvalid && destinationInvalid) {
        return 0;
    }
    
    if (destinationInvalid) {
        return [self distanceBasedOnSpeed:start.speed];
    }
    
    return [self distanceBasedOnSpeed:destination.speed];
}

- (NSInteger)distanceBasedOnSpeed:(CLLocationSpeed)speed {
    double KmPerHourSpeed = speed * 3.6;
    
    NSArray *allIntervals = self.speedIntevals.allKeys;
    
    for (int i = 0; i < allIntervals.count; i++) {
        NSArray *interval = allIntervals[i];
        if ([interval[0] doubleValue] < KmPerHourSpeed && KmPerHourSpeed < [interval[1] doubleValue]) {
            return [self.speedIntevals[interval] integerValue];
        }
    }
    
    return 0;
}

@end
