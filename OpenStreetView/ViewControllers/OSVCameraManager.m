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

#import "OSVLocationManager.h"
#import <SKMaps/SKMaps.h>

#import "OSVSyncController.h"
#import "OSVUserDefaults.h"
#import "OSVLogger.h"
#import "OSVSyncUtils.h"
#import "OSVUtils.h"

#import "UIAlertView+Blocks.h"

#import <Accelerate/Accelerate.h>

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
@property (nonatomic) OSVVideoRecorder                  *smallVideoRecorder;

@property (strong, nonatomic) AVCaptureDeviceFormat     *deviceFormat;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillOutput;
@property (strong, nonatomic) dispatch_queue_t          sessionQueue;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer*previewLayer;

@property (assign, nonatomic) NSInteger                 wishedFreeSpace;
@property (assign, nonatomic) NSInteger                 currentOBDSpeed;
@property (assign, nonatomic) NSInteger                 realDistance;
@property (assign, nonatomic) BOOL                      hadOBD;
@property (strong, nonatomic) dispatch_source_t         timer;
@property (assign, nonatomic) NSInteger                 stillImageRequests;
@property (assign, nonatomic) NSTimeInterval            previousTimeFrame;

@end

int const MaxStillImageRequests = 8;

@implementation OSVCameraManager

- (instancetype)initWithOutput:(AVCaptureStillImageOutput *)stillOutput
                       preview:(AVCaptureVideoPreviewLayer *)layer
                   deviceFromat:(AVCaptureDeviceFormat *)deviceFormat
                          queue:(dispatch_queue_t)sessionQueue {
    self = [super init];
    if (self) {
        self.sessionQueue = sessionQueue;
        self.deviceFormat = deviceFormat;
        self.stillOutput = stillOutput;
        self.previewLayer = layer;
        self.distanceBetweenPhotos = 0;
        self.wishedFreeSpace = 500 * 1000 * 1000;
        self.backgroundRenderingID = UIBackgroundTaskInvalid;

        self.speedIntevals = @{ @[@1,@10] : @5,
                                @[@10, @30] : @10,
                                @[@30, @50] : @15,
                                @[@50, @90] : @20,
                                @[@90, @120] : @25,
                                @[@120, @(NSNotFound)] : @35};

//      TODO Change the sensor manager to have a location manager
        [[OSVLocationManager sharedInstance] startUpdatingLocation];
        
        [OSVLocationManager sharedInstance].sensorsManager.delegate = self;
        [[OSVLocationManager sharedInstance].sensorsManager startUpdatingDeviceMotion];
        //high res video
        CMVideoDimensions dim = CMVideoFormatDescriptionGetDimensions(self.deviceFormat.formatDescription);
        self.videoRecorder = [[OSVVideoRecorder alloc] initWithVideoSize:dim];
        
        //low res video
        double frameMaxSize = 1024;
        double bitRate = 1500000;
        NSString *encoding = AVVideoProfileLevelH264HighAutoLevel;
#ifdef ENABLED_DEBUG
        frameMaxSize = [OSVUserDefaults sharedInstance].debugFrameSize;
        bitRate = [OSVUserDefaults sharedInstance].debugBitRate*1000000;
        encoding = [OSVUserDefaults sharedInstance].debugEncoding;
#endif
        CMVideoDimensions dimSmall;
        double ratio = frameMaxSize/MAX(dim.width, dim.height);
        dimSmall.height = dim.height * ratio;
        dimSmall.width = dim.width * ratio;

        self.smallVideoRecorder = [[OSVVideoRecorder alloc] initWithVideoSize:dimSmall encoding:encoding bitrate:bitRate];
        
        [self addObservers];
        [self initSensorLib];
    }

    return self;
}

- (void)dealloc {
    if (self.timer) {
        dispatch_source_cancel(self.timer);
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public
- (void)startLowResolutionCapture {
    self.previousTimeFrame = 0;
    AVCaptureVideoOrientation orientation = [[self.previewLayer connection] videoOrientation];
    [self.smallVideoRecorder createRecordingWithURL:[self fileNameForLowResTrackID:self.currentSequence videoID:self.videoIndex] orientation:orientation];
    [self lowResolutionCapure];
}

- (void)startHighResolutionCapure {
    self.isSnapping = YES;
    self.backgroundRenderingID = UIBackgroundTaskInvalid;
    
    [[OSVSyncController sharedInstance].logger createNewLogFileForSequenceID:self.currentSequence];
    
    AVCaptureVideoOrientation orientation = [[self.previewLayer connection] videoOrientation];
    
    [self.videoRecorder createRecordingWithURL:[self fileNameForTrackID:self.currentSequence videoID:self.videoIndex] orientation:orientation];
    [OSVLocationManager sharedInstance].delegate = self;
}

- (void)stopLowResolutionCapture {
    if (self.timer) {
        dispatch_source_cancel(self.timer);
    }
    [self.smallVideoRecorder completeRecordingSessionWithBlock:^(BOOL success, NSError *error) {
        NSLog(@"%@", error);
    }];
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
        [OSVSyncUtils removeTrackWithID:self.currentSequence atPath:[OSVSyncController sharedInstance].tracksController.basePathToPhotos];
    }
    
    [OSVLocationManager sharedInstance].delegate = nil;
    self.backgroundRenderingID = UIBackgroundTaskInvalid;
    self.isSnapping = NO;
}

- (void)resetValues {
    self.currentOBDSpeed = -1;
    self.obdDistance = 0;
    self.currentSequence = (NSInteger)[[NSDate new] timeIntervalSince1970];
    self.frameCount = 0;
    self.videoIndex = 0;
    self.distanceCoverd = 0;
    self.usedMemory = 0;
    self.decay = 0;
}

- (void)makeStillCaptureWithLocation:(CLLocation *)photoLocation {
    BOOL shouldMakeStillWithLocation = YES;
#ifdef ENABLED_DEBUG
    shouldMakeStillWithLocation = [OSVUserDefaults sharedInstance].debugHighDesintyOn;
#endif
    
    if (!shouldMakeStillWithLocation) {
        return;
    }
    
    if (!self.isSnapping) {
        return;
    }
    
    if (self.wishedFreeSpace > [OSVUtils freeDiskSpaceBytes]) {
        self.isSnapping = NO;
        [self.delegate willStopCapturing];
        return;
    }
    
    __weak typeof(self) welf = self;
    NSTimeInterval dateLocation = [[NSDate new] timeIntervalSince1970];
    
    dispatch_async([welf sessionQueue], ^{
        if (!welf.isSnapping) {
            return;
        }
        // Update the orientation on the still image output video connection before capturing.
        AVCaptureVideoOrientation orientation = [[welf.previewLayer connection] videoOrientation];
        [[welf.stillOutput connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:orientation];
        
        AVCaptureConnection *connection = [welf.stillOutput connectionWithMediaType:AVMediaTypeVideo];
        
        // Capture a still image.
        [welf.stillOutput captureStillImageAsynchronouslyFromConnection:connection
                                                      completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            
            CVPixelBufferRef pixelsBuffer = CVPixelBufferRetain(CMSampleBufferGetImageBuffer(imageDataSampleBuffer));
            NSLog(@"test works");
            NSInteger rotation = kRotate0DegreesClockwise;
            if (orientation == AVCaptureVideoOrientationPortrait) {
                rotation = kRotate90DegreesClockwise;
            } if (orientation == AVCaptureVideoOrientationLandscapeLeft) {
                rotation = kRotate180DegreesClockwise;
            } else if (orientation == AVCaptureVideoOrientationLandscapeRight) {
                rotation = kRotate0DegreesClockwise;
            }
            
            if (pixelsBuffer) {
                [welf.videoRecorder addPixelBuffer:pixelsBuffer withRotation:rotation completion:^(BOOL success) {
                    welf.isValidVideo = YES;
                    OSVPhoto *photo = [OSVPhoto new];
                    NSLog(@"is dooing stuf");
                    if (success) {
                        NSLog(@"with success");
                        photo.photoData = [OSVPhotoData new];
                        photo.photoData.location = photoLocation;
                        photo.photoData.timestamp = dateLocation;
                        photo.photoData.sequenceIndex = welf.frameCount;
                        photo.photoData.videoIndex = welf.videoIndex;
                        photo.localSequenceId = welf.currentSequence;
                        photo.hasOBD = welf.hadOBD;
                        welf.frameCount++;

                        OSVLogItem *item = [OSVLogItem new];
                        item.photodata = photo.photoData;
                        item.timestamp = photo.photoData.timestamp;

                        [[OSVSyncController sharedInstance].tracksController savePhoto:photo withImageData:nil];
                        [[OSVSyncController sharedInstance].logger logItems:@[item] inFileForSequenceID:welf.currentSequence];
                        welf.distanceCoverd += welf.realDistance;
                        [welf.delegate didReceiveUIUpdate];
                    }

                    if (welf.backgroundRenderingID == UIBackgroundTaskInvalid && photo.photoData.sequenceIndex != 0 && (photo.photoData.sequenceIndex + 1) % 50 == 0) {
                        welf.videoIndex++;
                        [welf.videoRecorder completeRecordingSessionWithBlock:^(BOOL success, NSError *error) {

                            if (!success) {
                                [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Failed to Write Video error:%@", error] withLevel:LogLevelDEBUG];
                            }

                            NSLog(@"before complete %ld", (long)welf.usedMemory);
                            AVCaptureVideoOrientation orientation = [[welf.previewLayer connection] videoOrientation];
                            welf.usedMemory += [welf.videoRecorder currentVideoSize];
                            NSLog(@"after complete %ld", (long)welf.usedMemory);
                            
                            [welf.videoRecorder createRecordingWithURL:[welf fileNameForTrackID:welf.currentSequence videoID:welf.videoIndex] orientation:orientation];
                            welf.isValidVideo = NO;
                        }];
                    }
                }];
            }
            
            CVPixelBufferRelease(pixelsBuffer);
        }];
    });
}

- (void)lowResolutionCapure {
    float interval = 0.1;
#ifdef ENABLED_DEBUG
    interval = 1.0/[OSVUserDefaults sharedInstance].debugFrameRate;
#endif
    
    self.stillImageRequests = 0;
    
    dispatch_queue_t timerQueue = dispatch_queue_create("timer queue",DISPATCH_QUEUE_SERIAL);
    // Create dispatch source that submits the event handler block based on a timer.
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                        0, // unused
                                        DISPATCH_TIMER_STRICT,
                                        timerQueue);
    // Set the event handler block for the timer dispatch source.
    dispatch_source_set_event_handler(self.timer, ^{
        // This block will attempt to capture a new still image each time it is called.
        // Captured requested number of images?
        if (self.stillImageRequests >= MaxStillImageRequests) {
            // Don't capture another image if the maximum
            // number of outstanding still image requests has
            // been exceeded.
        } else {
            self.stillImageRequests++;
            AVCaptureConnection *connection = [self.stillOutput connectionWithMediaType:AVMediaTypeVideo];
            
            [self.stillOutput captureStillImageAsynchronouslyFromConnection:connection
                                                               completionHandler:^(CMSampleBufferRef sampleBuffer, NSError *error) {
                 self.stillImageRequests--;

                 if (error) {
                     NSLog(@"erorare");
                 } else if (sampleBuffer) {
                     NSLog(@"working");
                     
                     NSTimeInterval curretTimeFrame = [[NSDate new] timeIntervalSince1970];
                     if (self.previousTimeFrame == 0) {
                         self.previousTimeFrame = curretTimeFrame;
                     }
                     
                     NSTimeInterval dif = curretTimeFrame - self.previousTimeFrame;
                     self.previousTimeFrame = curretTimeFrame;
                     
                     AVCaptureVideoOrientation orientation = [[self.previewLayer connection] videoOrientation];
                     NSInteger rotation = kRotate0DegreesClockwise;
                     if (orientation == AVCaptureVideoOrientationPortrait) {
                         rotation = kRotate90DegreesClockwise;
                     } if (orientation == AVCaptureVideoOrientationLandscapeLeft) {
                         rotation = kRotate180DegreesClockwise;
                     } else if (orientation == AVCaptureVideoOrientationLandscapeRight) {
                         rotation = kRotate0DegreesClockwise;
                     }
                     
                     if (![OSVUserDefaults sharedInstance].useImageRecognition) {
                         CVPixelBufferRef pixelsBuffer = CVPixelBufferRetain(CMSampleBufferGetImageBuffer(sampleBuffer));

                         [self.smallVideoRecorder addPixelBuffer:pixelsBuffer
                                                    withRotation:rotation
                                                    withDuration:CMTimeMake(dif*1000, 1000)
                                                      completion:^(BOOL success) {
                             NSLog(@"adding  stuff %d", success);
                         }];
                         CVPixelBufferRelease(pixelsBuffer);
                     } else {
                         [self.sensorLib speedLimitsFromSampleBuffer:sampleBuffer
                                                      withCompletion:^(NSArray *detections, CVImageBufferRef pixelsBuffer) {
                                                          
                              [self.smallVideoRecorder addPixelBuffer:pixelsBuffer
                                                         withRotation:rotation
                                                         withDuration:CMTimeMake(dif*1000, 1000)
                                                           completion:^(BOOL success) {
                                  NSLog(@"adding  stuff %d", success);
                              }];
                              
                              UIImage *image = [self.sensorLib imageForSpeedLimit:detections.firstObject];
                              if (image) {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      [self.delegate shouldDisplayTraficSign:image];
                                  });
                              }
                        }];
                     }
                 }
                }];
            }
    });
    
    // Set timer start time and interval.
    dispatch_source_set_timer(self.timer,
                              dispatch_time(DISPATCH_TIME_NOW, 0), // start time
                              interval * NSEC_PER_SEC, // interval
                              0.001 * NSEC_PER_SEC); // leeway
    dispatch_resume(self.timer);
}

- (void)initSensorLib {
    if ([OSVUserDefaults sharedInstance].useImageRecognition) {
        NSLog(@"merge acuma");
        self.sensorLib = [OSVSensorLibManager sharedInstance];
    }
}

- (NSURL *)fileNameForTrackID:(NSInteger)trackUID videoID:(NSInteger)videoUID {
    NSString *folderPathString = [NSString stringWithFormat:@"%@%ld", [OSVSyncController sharedInstance].tracksController.basePathToPhotos, (long)trackUID];
    if (![[NSFileManager defaultManager] fileExistsAtPath:folderPathString]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPathString withIntermediateDirectories:NO attributes:NULL error:NULL];
    }
    
    return [NSURL fileURLWithPath:[folderPathString stringByAppendingString:[NSString stringWithFormat:@"/%ld.mp4", (long)videoUID]]];
}

- (NSURL *)fileNameForLowResTrackID:(NSInteger)trackUID videoID:(NSInteger)videoUID {
    NSString *folderPathString = [NSString stringWithFormat:@"%@%ld", [OSVSyncController sharedInstance].tracksController.basePathToPhotos, (long)trackUID];
    if (![[NSFileManager defaultManager] fileExistsAtPath:folderPathString]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPathString withIntermediateDirectories:NO attributes:NULL error:NULL];
    }
    
    return [NSURL fileURLWithPath:[folderPathString stringByAppendingString:[NSString stringWithFormat:@"/%ld_low.mp4", (long)videoUID]]];
}

- (NSInteger)usedMemory {
    return _usedMemory + [self.videoRecorder currentVideoSize] + [self.smallVideoRecorder currentVideoSize];
}

#pragma mark - Location Manager

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)newLocation {
    self.currentLocation = [newLocation firstObject];
    SKPosition matchedPosition = [SKPositionerService sharedInstance].currentMatchedPosition;
    CLLocation *matchedLocation = [[CLLocation alloc] initWithLatitude:matchedPosition.latY longitude:matchedPosition.lonX];
    
    [self.delegate didAddNewLocation:matchedLocation];

    
    OSVLogItem *item = [OSVLogItem new];
    item.location = self.currentLocation;
    [[OSVSyncController sharedInstance].logger logItems:@[item] inFileForSequenceID:0];
    
    if (self.currentLocation.horizontalAccuracy < 0) {
        [self badGPSHandling];
    } else {
        if (self.currentLocation.horizontalAccuracy <= 15) {
            [self.delegate didChangeGPSStatus:[UIImage imageNamed:@"gPSOK"]];
            self.hadGPS = YES;
            [self.badGPSTimer invalidate];
            self.badGPSTimer = nil;
        } else if (self.currentLocation.horizontalAccuracy <= 40) {
            [self.delegate didChangeGPSStatus:[UIImage imageNamed:@"gPSMedium"]];
            self.hadGPS = YES;
            [self.badGPSTimer invalidate];
            self.badGPSTimer = nil;
        } else {
            [self badGPSHandling];
        }
    }
    
    if (!self.lastPhotoLocation || (self.lastPhotoLocation.coordinate.latitude == 0 && self.lastPhotoLocation.coordinate.longitude == 0)) {
        self.lastPhotoLocation = self.currentLocation;
    }
    
    double distance = [self.lastPhotoLocation distanceFromLocation:self.currentLocation];
    
    self.distanceBetweenPhotos = [self distanceBetweenPhotosWithLocation:self.lastPhotoLocation nextLocation:self.currentLocation];
    
    if (self.distanceBetweenPhotos > 0 && distance >= self.distanceBetweenPhotos) {
        self.realDistance = distance;
        if (self.currentOBDSpeed < 0) {
            self.lastPhotoLocation = self.currentLocation;
            [self makeStillCaptureWithLocation:self.currentLocation];
            NSLog(@"made snap with normal");
        }
    }
}

- (void)badGPSHandling {
    [self.delegate didChangeGPSStatus:[UIImage imageNamed:@"gPSLow"]];
    
    if (self.hadOBD && !(self.currentOBDSpeed < 0)) {
        return;
    }
    
    if (self.hadGPS && !self.badGPSTimer) {
        self.badGPSTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self
                                                          selector:@selector(badGPSShapshot) userInfo:nil
                                                           repeats:YES];
    }
}



- (void)shouldRemoveCurrentSign {
    [self.timerSign invalidate];
    self.timerSign = nil;
    [self.delegate shouldDisplayTraficSign:nil];
}


- (void)badGPSShapshot {
    NSLog(@"made snap with bad");
    if (!self.lastPhotoLocation) {
        CLLocation *localtion = [[CLLocation alloc] initWithCoordinate:[[SKPositionerService sharedInstance] currentCoordinate] altitude:0 horizontalAccuracy:1000 verticalAccuracy:0 timestamp:[NSDate new]];
        [self makeStillCaptureWithLocation:localtion];
    } else {
        [self makeStillCaptureWithLocation:[[CLLocation alloc] initWithCoordinate:self.lastPhotoLocation.coordinate altitude:0 horizontalAccuracy:1000 verticalAccuracy:0 timestamp:[NSDate new]]];
    }
}


- (void)startDecayForSign {
    [self.timerSign invalidate];
    self.timerSign = nil;
    self.timerSign = [NSTimer scheduledTimerWithTimeInterval:2 target:self
                                                    selector:@selector(shouldRemoveCurrentSign)
                                                    userInfo:nil
                                                     repeats:YES];
}

/*
 http://jira.telenav.com:8080/browse/OSV-9
 */
- (NSInteger)distanceBetweenPhotosWithLocation:(CLLocation *)start nextLocation:(CLLocation *)destination {
    
    if (start == nil || destination == nil) {
        return 0;
    }
    
    BOOL startInvalid = start.horizontalAccuracy < 0;
    BOOL startLowQuality = start.horizontalAccuracy > 20;
    
    BOOL destinationInvalid = destination.horizontalAccuracy < 0;
    BOOL destinationLowQuality = destination.horizontalAccuracy > 20;
    
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

#pragma mark - UIApplication Notifications

- (void)willEnterForgroundNotification:(NSNotification *)notification {
    if (self.isSnapping) {
        self.backgroundRenderingID = UIBackgroundTaskInvalid;
        AVCaptureVideoOrientation orientation = [[self.previewLayer connection] videoOrientation];
        [self.videoRecorder createRecordingWithURL:[self fileNameForTrackID:self.currentSequence videoID:self.videoIndex] orientation:orientation];
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
            
            self.usedMemory += [self.videoRecorder currentVideoSize];
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundRenderingID];
        }];
    }
}

#pragma mark - SensorManager

- (void)manager:(OSVSensorsManager *)manager didUpdateOBDData:(OSVOBDData *)data withError:(NSError *)error {
    self.hadOBD = YES;

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

#pragma mark - OSVOBDController Notifications

- (void)managerDidConnectToOBD:(OSVSensorsManager *)manager {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate showOBD:NO];
    });
    
    self.hadOBD = YES;
}

- (void)managerDidDisconnectFromOBD:(OSVSensorsManager *)manager {
    if (self.isSnapping) {
        [[OSVLocationManager sharedInstance].sensorsManager reconnectOBD];
    }
    
    self.currentOBDSpeed = -1;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate showOBD:YES];
    });
}

- (void)managerDidFailToConnectODB:(OSVSensorsManager *)manager {
    self.currentOBDSpeed = -1;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate showOBD:YES];
    });
}

#pragma mark - Private 

- (void)addObservers {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForgroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidConnectToOBD:) name:@"kOBDDidConnect" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidDisconnectFromOBD:) name:@"kOBDDidDisconnect" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidFailToConnectODB:) name:@"kOBDFailedToConnectInTime" object:nil];
}

@end
