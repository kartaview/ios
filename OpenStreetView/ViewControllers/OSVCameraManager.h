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

@protocol OSVCameraManagerDelegate <NSObject>

- (void)willStopCapturing;
- (void)shouldDisplayTraficSign:(UIImage *)traficSign;
- (void)didChangeGPSStatus:(UIImage *)gpsStatus;
- (void)didChangeOBDInfo:(double)speed withError:(NSError *)error;
- (void)showOBD:(BOOL)value;
// TODO change naming to something more explicit
- (void)didAddNewLocation:(CLLocation *)location;

- (void)didReceiveUIUpdate;

@end

@interface OSVCameraManager : NSObject

@property (assign, nonatomic) BOOL                          isSnapping;
@property (assign, atomic   ) NSInteger                     frameCount;
@property (assign, nonatomic) NSInteger                     usedMemory;
@property (assign, nonatomic) NSInteger                     distanceCoverd;
@property (weak,   nonatomic) id<OSVCameraManagerDelegate>  delegate;
@property (assign, nonatomic) UIBackgroundTaskIdentifier    backgroundRenderingID;

- (instancetype)initWithOutput:(AVCaptureStillImageOutput *)stillOutput
                       preview:(AVCaptureVideoPreviewLayer *)layer
                  deviceFromat:(AVCaptureDeviceFormat *)deviceFormat
                         queue:(dispatch_queue_t)sessionQueue;

- (void)makeStillCaptureWithLocation:(CLLocation *)location;

- (void)startLowResolutionCapture;
- (void)startHighResolutionCapure;

- (void)stopLowResolutionCapture;
- (void)stopHighResolutionCapture;

- (void)resetValues;

- (void)badGPSHandling;

@end
