//
//  OSVCameraManager.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 03/08/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@class CLLocation;
@class OSVCameraMapManager;
@class OSVTrackMatcher;

@protocol OSVCameraManagerDelegate <NSObject>

- (void)willStopCapturing;
- (void)shouldDisplayTraficSign:(UIImage *)traficSign;
- (void)didChangeGPSStatus:(UIImage *)gpsStatus;
- (void)didChangeOBDInfo:(double)speed withError:(NSError *)error;
- (void)hideOBD:(BOOL)value;
// TODO change naming to something more explicit
- (void)didAddNewLocation:(CLLocation *)location;

- (void)didReceiveUIUpdate;

@end

@interface OSVCameraManager : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (assign, nonatomic) BOOL                          isRecording;
@property (assign, atomic   ) NSInteger                     frameCount;
@property (assign, nonatomic, readonly) NSInteger           usedMemory;
@property (assign, nonatomic) NSInteger                     distanceCoverd;
@property (weak,   nonatomic) id<OSVCameraManagerDelegate>  delegate;
@property (assign, nonatomic) UIBackgroundTaskIdentifier    backgroundRenderingID;
@property (weak,   nonatomic) OSVCameraMapManager           *cameraMapManager;
@property (nonatomic, strong) OSVTrackMatcher               *matcher;
@property (nonatomic, assign, readonly) NSInteger           currentSequence;


- (instancetype)initWithOutput:(AVCaptureVideoDataOutput *)stillOutput
                       preview:(AVCaptureVideoPreviewLayer *)layer
                  deviceFromat:(AVCaptureDeviceFormat *)deviceFormat
                         queue:(dispatch_queue_t)sessionQueue;

- (void)makeStillCaptureWithLocation:(CLLocation *)location;

- (void)startHighResolutionCapure;

- (void)stopHighResolutionCapture;

- (void)resetValues;

- (void)badGPSHandling;

- (double)score;
- (double)multiplier;
- (BOOL)hasCoverage;

@end
