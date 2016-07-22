//
//  OSVCamViewController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 09/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVCamViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AVCamPreviewView.h"
#import <CoreLocation/CoreLocation.h>
#import "OSVUtils.h"
#import <SKMaps/SKPositionerService.h>
#import "OSVUserDefaults.h"
#import "OSVLocationManager.h"

#import "OSVSequence.h"

#import "OSVSyncController.h"

#import "UIAlertView+Blocks.h"

#import "OSVReachablityController.h"
#import <GLKit/GLKit.h>
#import "UIColor+OSVColor.h"

#import "OSVVideoRecorder.h"


#import "OSVTipView.h"

#import <SKMaps/SKMaps.h>
#import "OSVDotedPolyline.h"

#import <ImageIO/ImageIO.h>
#import <Accelerate/Accelerate.h>

#import "OSVPersistentManager.h"

#import "OSVLogger.h"

#import "OSVSensorLibManager.h"

#import "NSMutableAttributedString+Additions.h"
#import "NSAttributedString+Additions.h"

@interface OSVCamViewController () <CLLocationManagerDelegate, OSVSensorsManagerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) dispatch_queue_t          sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic) AVCaptureSession          *session;
@property (nonatomic) AVCaptureDeviceInput      *videoDeviceInput;
@property (nonatomic) AVCaptureMovieFileOutput  *movieFileOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput  *videoOutput;

@property (nonatomic, assign) double                    distanceBetweenPhotos;
@property (nonatomic, assign) double                    realDistance;
@property (nonatomic, strong) CLLocation                *lastPhotoLocation;

@property (nonatomic, strong) CLLocation                *currentLocation;

@property (nonatomic, strong) OSVLocationManager        *locationManager;

@property (atomic, assign) NSInteger                currentSequence;
@property (atomic, assign) NSInteger                sequenceIndex;
@property (atomic, assign) NSInteger                videoIndex;
@property (atomic, assign) BOOL                     isValidVideo;

@property (atomic, assign) BOOL                     isSnapping;

@property (weak, nonatomic) IBOutlet UIButton *startCapture;

@property (nonatomic, strong) OSVSyncController *syncController;
@property (nonatomic, strong) OSVVideoRecorder  *videoRecorder;

@property (nonatomic, assign) NSInteger usedMemory;
@property (assign, nonatomic) NSInteger distanceCoverd;

@property (nonatomic, strong) NSDictionary<NSArray *, NSNumber *> *speedIntevals;

@property (assign, nonatomic) NSInteger                 wishedFreeSpace;

@property (weak, nonatomic) IBOutlet UILabel            *debugInfo;

@property (weak, nonatomic) IBOutlet UILabel            *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel            *photosCountLabel;
@property (weak, nonatomic) IBOutlet UILabel            *storageUsedLabel;

@property (weak, nonatomic) IBOutlet UILabel            *obdSpeed;
@property (weak, nonatomic) IBOutlet UIView             *obdStatus;

@property (strong, nonatomic) NSTimer                   *badGPSTimer;
@property (strong, nonatomic) NSTimer                   *timerSign;

@property (assign, nonatomic) BOOL                      hadGPS;
@property (assign, nonatomic) BOOL                      hadOBD;
// this speed is expressed in meters per second
@property (assign, nonatomic) double                    currentOBDSpeed;

@property (weak, nonatomic) IBOutlet SKMapView          *mapView;
@property (strong, nonatomic) OSVDotedPolyline          *doted;

@property (assign, nonatomic) BOOL                      mapFullScreen;

@property (assign, nonatomic) NSTimeInterval            decay;
@property (assign, nonatomic) NSTimeInterval            lastOBDTimestamp;
@property (assign, nonatomic) double                    obdDistance;

@property (nonatomic) OSVSensorLibManager               *sensorLib;

@property (weak, nonatomic) IBOutlet UIImageView        *recognizedSign;
@property (weak, nonatomic) IBOutlet UIButton           *cancelButton;

@property (weak, nonatomic) IBOutlet UIView             *infoView;
@property (strong, nonatomic) OSVTipView                *tipView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingMap;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topMap;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomMap;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *trailingMap;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingPreview;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topPreview;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomPreview;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *trailingPreview;
@property (weak, nonatomic) IBOutlet UIView             *mapContainer;
@property (weak, nonatomic) IBOutlet UIView             *topContainer;
@property (weak, nonatomic) IBOutlet UIImageView        *gpsQuality;
@property (weak, nonatomic) IBOutlet UILabel            *sugestionLabel;
@property (weak, nonatomic) IBOutlet UIImageView        *arrow;
@property (weak, nonatomic) IBOutlet UIImageView        *arrow1;

@end

@implementation OSVCamViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.locationManager = [OSVLocationManager sharedInstance];
    [self.locationManager startUpdatingLocation];
    self.syncController = [OSVSyncController sharedInstance];
    [OSVLocationManager sharedInstance].sensorsManager.delegate = self;
    self.backgroundRenderingID = UIBackgroundTaskInvalid;
   
    self.speedIntevals = @{ @[@1,@10] : @5,
                            @[@10, @30] : @10,
                            @[@30, @50] : @15,
                            @[@50, @90] : @20,
                            @[@90, @120] : @25,
                            @[@120, @(NSNotFound)] : @35};

    self.startCapture.clipsToBounds = YES;    
    self.gpsQuality.image = [UIImage imageNamed:@"gPSLow"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidConnectToOBD:) name:@"kOBDDidConnect" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidDisconnectFromOBD:) name:@"kOBDDidDisconnect" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidFailToConnectODB:) name:@"kOBDFailedToConnectInTime" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForgroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    self.infoView.alpha = 0;
    
    [self initSensorLib];
    [UIViewController attemptRotationToDeviceOrientation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    CMVideoDimensions dim = CMVideoFormatDescriptionGetDimensions(self.deviceFormat.formatDescription);
    self.videoRecorder = [[OSVVideoRecorder alloc] initWithVideoSize:dim];
    
    self.distanceBetweenPhotos = [self distanceBetweenPhotosWithLocation:nil nextLocation:nil];

    self.wishedFreeSpace = 500 * 1000 * 1000;
    
    self.debugInfo.hidden = YES;
    
    [self updateUIInfo];
    
    self.mapView.mapScaleView.hidden = YES;
    self.mapView.settings.showCompass = NO;
    self.mapView.settings.displayMode = SKMapDisplayMode2D;
    self.mapView.settings.showStreetNamePopUps = YES;
//use payed SDK
//    self.mapView.settings.osmAttributionPosition = SKAttributionPositionNone;
//    self.mapView.settings.companyAttributionPosition = SKAttributionPositionNone;
    
    [[OSVLocationManager sharedInstance].sensorsManager startUpdatingDeviceMotion];
    self.mapView.clipsToBounds = YES;
    SKCoordinateRegion region;
    region.zoomLevel = 12;
    region.center = [SKPositionerService sharedInstance].currentCoordinate;
    self.mapView.visibleRegion = region;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.mapView.settings.followUserPosition = YES;
    
    [self.mapView centerOnCurrentPosition];
    [self.mapView animateToZoomLevel:17];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[OSVLocationManager sharedInstance].sensorsManager stopUpdatingDeviceMotion];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initSensorLib {
    if ([OSVUserDefaults sharedInstance].useImageRecognition) {
        NSLog(@"merge acuma");
        self.sensorLib = [OSVSensorLibManager sharedInstance];
    }
}

- (void)snapShotAtLocation:(CLLocation *)photoLocation {
    if (!self.isSnapping) {
        return;
    }
    
    if (self.wishedFreeSpace > [OSVUtils freeDiskSpaceBytes]) {
        self.isSnapping = NO;
        [UIAlertView showWithTitle:@"" message:NSLocalizedString(@"Minimum reserved disk space reached. The recording will stop now.", @"") style:UIAlertViewStyleDefault cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            [self stopSequence];
        }];
        return;
    }
    
    __weak typeof(self) welf = self;
    NSTimeInterval dateLocation = [[NSDate new] timeIntervalSince1970];
    
    dispatch_async([self sessionQueue], ^{
        if (!self.isSnapping) {
            return;
        }
        // Update the orientation on the still image output video connection before capturing.
        AVCaptureVideoOrientation orientation = [[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] videoOrientation];
        [[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:orientation];
        
        AVCaptureConnection *connection = [[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo];
                
        // Capture a still image.
        [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
            CVPixelBufferRef pixelsBuffer = CVPixelBufferRetain(CMSampleBufferGetImageBuffer(imageDataSampleBuffer));
            
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
                    self.isValidVideo = YES;
                    OSVPhoto *photo = [OSVPhoto new];
                    NSLog(@"is dooing stuf");
                    if (success) {
                        NSLog(@"with success");
                        photo.photoData = [OSVPhotoData new];
                        photo.photoData.location = photoLocation;
                        photo.photoData.timestamp = dateLocation;
                        photo.photoData.sequenceIndex = welf.sequenceIndex;
                        photo.photoData.videoIndex = welf.videoIndex;
                        photo.localSequenceId = welf.currentSequence;
                        photo.hasOBD = welf.hadOBD;
                        welf.sequenceIndex++;

                        OSVLogItem *item = [OSVLogItem new];
                        item.photodata = photo.photoData;
                        item.timestamp = photo.photoData.timestamp;
                        
                        [welf.syncController.tracksController savePhoto:photo withImageData:nil];
                        [welf.syncController.logger logItems:@[item] inFileForSequenceID:welf.currentSequence];
                        welf.distanceCoverd += welf.realDistance;
                        [welf updateUIInfo];
                    }
                    
                    if (self.backgroundRenderingID == UIBackgroundTaskInvalid && photo.photoData.sequenceIndex != 0 && (photo.photoData.sequenceIndex + 1) % 50 == 0) {
                        welf.videoIndex++;
                        [welf.videoRecorder completeRecordingSessionWithBlock:^(BOOL success, NSError *error) {
                            
                            if (!success) {
                                [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Failed to Write Video error:%@", error] withLevel:LogLevelDEBUG];
                            }
                            
                            NSLog(@"before complete %ld", (long)welf.usedMemory);
                            AVCaptureVideoOrientation orientation = [[(AVCaptureVideoPreviewLayer *)[[welf previewView] layer] connection] videoOrientation];
                            welf.usedMemory += [welf.videoRecorder currentVideoSize];
                            NSLog(@"after complete %ld", (long)welf.usedMemory);
                            
                            [welf.videoRecorder createRecordingWithURL:[welf fileNameForTrackID:welf.currentSequence videoID:welf.videoIndex] orientation:orientation];
                            self.isValidVideo = NO;
                        }];
                    }
                }];
            }
            
            CVPixelBufferRelease(pixelsBuffer);
        }];
    });
}

#pragma mark - Location Manager

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)newLocation {
    self.currentLocation = [newLocation firstObject];
    SKPosition matchedPosition = [SKPositionerService sharedInstance].currentMatchedPosition;
    CLLocation *matchedLocation = [[CLLocation alloc] initWithLatitude:matchedPosition.latY longitude:matchedPosition.lonX];

    if (!self.doted) {
        self.doted = [OSVDotedPolyline new];
        self.doted.strokeColor = [UIColor hex007AFF];
        self.doted.coordinates = @[matchedLocation];
        [self.mapView addPolyline:self.doted];
    } else {
        NSMutableArray *array = [NSMutableArray arrayWithArray:self.doted.coordinates];
        [array addObject:matchedLocation];

        self.doted.coordinates = array;
        [self.mapView addPolyline:self.doted];
    }
    
    OSVLogItem *item = [OSVLogItem new];
    item.location = self.currentLocation;
    [[OSVSyncController sharedInstance].logger logItems:@[item] inFileForSequenceID:0];
    
    if (self.currentLocation.horizontalAccuracy < 0) {
        [self badGPSHandling];
    } else {
        if (self.currentLocation.horizontalAccuracy <= 15) {
            self.gpsQuality.image = [UIImage imageNamed:@"gPSOK"];
            self.hadGPS = YES;
            [self.badGPSTimer invalidate];
            self.badGPSTimer = nil;
        } else if (self.currentLocation.horizontalAccuracy <= 40) {
            self.gpsQuality.image = [UIImage imageNamed:@"gPSMedium"];
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

    self.debugInfo.text = [NSString stringWithFormat:@"distance:%ld m \n speed:%f km/h", (long)self.distanceBetweenPhotos, self.currentLocation.speed * 3.6];
    
    if (self.distanceBetweenPhotos > 0 && distance >= self.distanceBetweenPhotos) {
        self.realDistance = distance;
        if (self.currentOBDSpeed < 0) {
            self.lastPhotoLocation = self.currentLocation;
            [self snapShotAtLocation:self.currentLocation];
            NSLog(@"made snap with normal");
        }
    }
}

- (void)badGPSHandling {
    self.gpsQuality.image = [UIImage imageNamed:@"gPSLow"];

    if (self.hadOBD && !(self.currentOBDSpeed < 0)) {
        return;
    }

    if (self.hadGPS && !self.badGPSTimer) {
        self.badGPSTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self
                                                          selector:@selector(badGPSShapshot) userInfo:nil
                                                           repeats:YES];
    }
}

- (void)badGPSShapshot {
    NSLog(@"made snap with bad");
    if (!self.lastPhotoLocation) {
        CLLocation *localtion = [[CLLocation alloc] initWithCoordinate:[[SKPositionerService sharedInstance] currentCoordinate] altitude:0 horizontalAccuracy:1000 verticalAccuracy:0 timestamp:[NSDate new]];
        [self snapShotAtLocation:localtion];
    } else {
        [self snapShotAtLocation:[[CLLocation alloc] initWithCoordinate:self.lastPhotoLocation.coordinate altitude:0 horizontalAccuracy:1000 verticalAccuracy:0 timestamp:[NSDate new]]];
    }
}

#pragma mark - AVVideoCameraOutputDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
//    if ([OSVUserDefaults sharedInstance].useImageRecognition) {
//        [self.sensorLib speedLimitsFromSampleBuffer:sampleBuffer withCompletion:^(NSArray *detections) {
//            UIImage *image = [self.sensorLib imageForSpeedLimit:detections.firstObject];
//            if (image) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self startDecayForSign];
//                    self.recognizedSign.image = image;
//                });
//            }
//        }];
//    }
}

- (void)startDecayForSign {
    [self.timerSign invalidate];
    self.timerSign = nil;
    self.timerSign = [NSTimer scheduledTimerWithTimeInterval:2 target:self
                                                    selector:@selector(shouldRemoveCurrentSign)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void)shouldRemoveCurrentSign {
    [self.timerSign invalidate];
    self.timerSign = nil;
    self.recognizedSign.image = nil;
}

#pragma mark - Actions

- (IBAction)didTapTipsView:(id)sender {
    self.tipView.backgroundColor = [UIColor grayColor];
    self.tipView.frame = self.view.frame;
    [self.view addSubview:self.tipView];
}

- (IBAction)didTapOnPreview:(UITapGestureRecognizer *)tapRecognizer {
    CGPoint point = [tapRecognizer locationInView:tapRecognizer.view];
    CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)self.previewView.layer captureDevicePointOfInterestForPoint:point];
    [self animateFocusAtPoint:point withGesture:tapRecognizer];
    
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

- (IBAction)didLongPressOnPreview:(UILongPressGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:sender.view];
    [self animateFocusAtPoint:point withGesture:sender];
    CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)self.previewView.layer captureDevicePointOfInterestForPoint:point];
    [self focusWithMode:AVCaptureFocusModeLocked exposeWithMode:AVCaptureExposureModeLocked atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

- (IBAction)didTapOnInfoView:(id)sender {
    CLLocation *localtion = [[CLLocation alloc] initWithCoordinate:[[SKPositionerService sharedInstance] currentCoordinate] altitude:0 horizontalAccuracy:0 verticalAccuracy:0 timestamp:[NSDate new]];
    [self snapShotAtLocation:localtion];
}

- (IBAction)didTapStartCapture:(id)sender {
    if (self.wishedFreeSpace > [OSVUtils freeDiskSpaceBytes]) {
        [UIAlertView showWithTitle:@"" message:NSLocalizedString(@"Minimum reserved disk space reached. Free space by uploading your tracks and retry", @"") style:UIAlertViewStyleDefault cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            [self stopSequence];
        }];
        return;
    }
    
    if (!self.isSnapping) {
        [self startNewSequence];
    } else {
        [self stopSequence];
    }
}

- (IBAction)didTapOnMap:(UIGestureRecognizer *)sender {
    sender.enabled = NO;
    [UIView animateWithDuration:0.3 animations:^{
        if (self.mapFullScreen) {
            [self animateNormalSize];
        } else {
            [self animateFullScreen];
        }
    } completion:^(BOOL finished) {
        if (self.mapFullScreen) {
            [self.topContainer insertSubview:self.mapView aboveSubview:self.previewView];
        } else {
            [self.topContainer insertSubview:self.previewView aboveSubview:self.mapView];
        }
        self.mapFullScreen = !self.mapFullScreen;
        sender.enabled = YES;
    }];
}

- (void)animateFullScreen {
    
    self.topMap.constant = -self.mapContainer.frame.origin.y;
    self.leadingMap.constant = -10;
    self.trailingMap.constant = self.view.frame.size.width - CGRectGetMaxX(self.mapContainer.frame);
    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        self.bottomMap.constant = 10;
        
        self.bottomPreview.constant = 10;
        self.topPreview.constant = self.mapContainer.frame.origin.y;
        self.leadingPreview.constant = 10;
        self.trailingPreview.constant = self.view.frame.size.width - CGRectGetMaxX(self.mapContainer.frame);
    } else {
        self.bottomMap.constant = self.topContainer.frame.size.height - CGRectGetMaxY(self.mapContainer.frame);
        
        self.topPreview.constant = 10;
        self.leadingPreview.constant = 10;
        self.bottomPreview.constant = self.topContainer.frame.size.height - CGRectGetMaxY(self.mapContainer.frame);
        self.trailingPreview.constant = self.topContainer.frame.size.width - CGRectGetMaxX(self.mapContainer.frame);
    }
    
    self.mapView.frame = self.topContainer.frame;
    self.previewView.frame = self.mapContainer.frame;
}

- (void)animateNormalSize {
    self.leadingMap.constant = 0;
    self.bottomMap.constant = 0;
    self.topMap.constant = 0;
    self.trailingMap.constant = 0;
    self.mapView.frame = self.mapContainer.frame;

    self.topPreview.constant = 0;
    self.leadingPreview.constant = 0;
    self.trailingPreview.constant = 0;
    self.bottomPreview.constant = 0;
    self.previewView.frame = self.topContainer.frame;
}

- (NSURL *)fileNameForTrackID:(NSInteger)trackUID videoID:(NSInteger)videoUID {
    NSString *folderPathString = [NSString stringWithFormat:@"%@%ld", [OSVSyncController sharedInstance].tracksController.basePathToPhotos, (long)trackUID];
    if (![[NSFileManager defaultManager] fileExistsAtPath:folderPathString]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPathString withIntermediateDirectories:NO attributes:NULL error:NULL];
    }
    
    return [NSURL fileURLWithPath:[folderPathString stringByAppendingString:[NSString stringWithFormat:@"/%ld.mp4", (long)videoUID]]];
}

- (void)startNewSequence {
    self.hadGPS = NO;
    self.hadOBD = NO;
    
    [self resetValues];

    self.sugestionLabel.hidden = YES;
    self.arrow.hidden = YES;
    self.arrow1.hidden = YES;
    [[OSVLogger sharedInstance] createNewLogFile];
    [self.cancelButton setTitle:NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.infoView.alpha = 1;
    } completion:^(BOOL finished) {
        self.infoView.alpha = 1;
    }];
    
    self.backgroundRenderingID = UIBackgroundTaskInvalid;
    
    [self startNavigation];

    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        
        [self.syncController.logger createNewLogFileForSequenceID:self.currentSequence];
        
        AVCaptureVideoOrientation orientation = [[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] videoOrientation];

        [self.videoRecorder createRecordingWithURL:[self fileNameForTrackID:self.currentSequence videoID:self.videoIndex] orientation:orientation];
        [self updateUIInfo];

        [[OSVLocationManager sharedInstance].sensorsManager startLoggingSensors];
        [[OSVLocationManager sharedInstance].sensorsManager startUpdatingAccelerometer];
        [[OSVLocationManager sharedInstance].sensorsManager startUpdatingGyro];
        [[OSVLocationManager sharedInstance].sensorsManager startUpdatingMagnetometer];
        [[OSVLocationManager sharedInstance].sensorsManager startUpdatingAltitude];
        
        [self updateUIwithState:YES];
        self.locationManager.delegate = self;
    } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [[SKPositionerService sharedInstance] startLocationUpdate];
        [[NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(didChangeAuthorizationStatus:) name:@"didChangeAuthorizationStatus" object:nil];
    } else {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Location Services access", nil) message:NSLocalizedString(@"Please allow access to Location Services from Settings before starting a recording", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    }
}

- (void)resetValues {
    self.currentOBDSpeed = -1;
    self.obdDistance = 0;
    self.currentSequence = (NSInteger)[[NSDate new] timeIntervalSince1970];
    self.sequenceIndex = 0;
    self.videoIndex = 0;
    self.distanceCoverd = 0;
    self.usedMemory = 0;
    self.decay = 0;
    
    [self updateUIInfo];
}

- (void)startNavigation {
    self.mapView.settings.followUserPosition = YES;

    [SKPositionerService sharedInstance].positionerMode = SKPositionerModeRealPositions;
    SKNavigationSettings *navSettings = [SKNavigationSettings new];
    navSettings.showStreetNamePopUpsOnRoute = YES;
    navSettings.navigationType = SKNavigationTypeReal;
    navSettings.transportMode = SKTransportCar;
    
    [[SKRoutingService sharedInstance] startNavigationWithSettings:navSettings];
}

- (void)stopSequence {
    self.hadGPS = NO;
    self.hadOBD = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.infoView.alpha = 0;
    } completion:^(BOOL finished) {
        self.infoView.alpha = 0;
    }];

    [[SKRoutingService sharedInstance] stopNavigation];
    NSLog(@"did finish navigation");
    [self.badGPSTimer invalidate];
    self.badGPSTimer = nil;

    [self.syncController.logger closeLoggFileForSequenceID:self.currentSequence];
    [self.videoRecorder completeRecordingSessionWithBlock:^(BOOL success, NSError *error) {
        if (success) {
            [[OSVLogger sharedInstance] logMessage:@"Video was succesfuly writen." withLevel:LogLevelDEBUG];
        } else {
            [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Failed to Write Video error:%@", error] withLevel:LogLevelDEBUG];
        }
    }];
    
    [[OSVLocationManager sharedInstance].sensorsManager stopLoggingSensors];
    [[OSVLocationManager sharedInstance].sensorsManager stopUpdatingAccelerometer];
    [[OSVLocationManager sharedInstance].sensorsManager stopUpdatingGyro];
    [[OSVLocationManager sharedInstance].sensorsManager stopUpdatingMagnetometer];
    [[OSVLocationManager sharedInstance].sensorsManager stopUpdatingAltitude];
    
    if (self.sequenceIndex == 0) {
        [OSVSyncUtils removeTrackWithID:self.currentSequence atPath:[OSVSyncController sharedInstance].tracksController.basePathToPhotos];
    }
    
    self.backgroundRenderingID = UIBackgroundTaskInvalid;
    
    [self updateUIwithState:NO];
    self.locationManager.delegate = nil;
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"didFinishCreatingSequence" object:nil userInfo:@{@"sequenceID":@(self.currentSequence)}];
    
    if ([OSVUserDefaults sharedInstance].automaticUpload && ([OSVReachablityController hasWiFiAccess] || ([OSVReachablityController hasCellularAcces] && [OSVUserDefaults sharedInstance].useCellularData))) {
//        //TODO upload current sequence to server.
    }
    
    [self resetValues];
}

- (void)updateUIwithState:(BOOL)value {
    self.isSnapping = value;
    self.startCapture.selected = value;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)[[UIDevice currentDevice] orientation]];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {        
        if (self.mapFullScreen) {
            [self animateFullScreen];
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {

    }];
}

- (IBAction)didTapBackButton:(id)sender {
    [self stopSequence];
    [self.navigationController popViewControllerAnimated:NO];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - Private

- (OSVTipView *)tipView {
    if (!_tipView) {
        _tipView = [[[NSBundle mainBundle] loadNibNamed:@"OSVTipView" owner:self options:nil] objectAtIndex:0];
    }
    
    return _tipView;
}

- (void)updateUIInfo {
    self.debugInfo.text = [NSString stringWithFormat:@"distance: %ld \n speed:%f", (long)self.distanceBetweenPhotos, self.currentLocation.speed];
    if ([[OSVUserDefaults sharedInstance].distanceUnitSystem isEqualToString:kMetricSystem]) {
        NSArray *metricArray = [OSVUtils metricDistanceArray:self.distanceCoverd];
        self.distanceLabel.attributedText = [NSAttributedString combineString:metricArray[0] withSize:16.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                                   withString:metricArray[1] withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"];
    } else {
        NSArray *imperialArray = [OSVUtils imperialDistanceArray:self.distanceCoverd];
        self.distanceLabel.attributedText = [NSAttributedString combineString:imperialArray[0] withSize:16.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                                   withString:imperialArray[1] withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"];
    }

    self.photosCountLabel.attributedText = [NSAttributedString combineString:[@(self.sequenceIndex) stringValue] withSize:16.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                                  withString:@" IMG" withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"];
    
    NSArray *memoryArray = [OSVUtils arrayFormatedFromByteCount:(self.usedMemory + [self.videoRecorder currentVideoSize])];
    self.storageUsedLabel.attributedText = [NSAttributedString combineString:memoryArray[0] withSize:16.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                        withString:memoryArray[1] withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"];
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

- (void)didChangeAuthorizationStatus:(NSNotification *)notification {
    NSNumber *status = notification.userInfo[@"status"];
    CLAuthorizationStatus stat = (CLAuthorizationStatus)[status integerValue];
    if (stat != kCLAuthorizationStatusNotDetermined) {
        if (stat != kCLAuthorizationStatusAuthorizedWhenInUse) {
            [[[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"Please allow access to Location Services before starting a recording", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil] show];
        } else {
            [self startNewSequence];
        }
    }
}

- (void)animateFocusAtPoint:(CGPoint)point withGesture:(UIGestureRecognizer *)sender {
    UIView *previousView = self.previewView.focusView;
    if (previousView) {
        [UIView animateWithDuration:0 animations:^{
            previousView.alpha = 0;
        } completion:^(BOOL finished) {
            [previousView removeFromSuperview];
        }];
        previousView = nil;
    }
    
    self.previewView.focusView = nil;
    
    UIView *aview = nil;
    if (!self.previewView.focusView) {
        aview = [[UIView alloc] initWithFrame:CGRectMake(point.x - 35, point.y - 35, 70, 70)];
        aview.center = point;
        aview.layer.borderWidth = 3;
        aview.layer.borderColor = [UIColor whiteColor].CGColor;
        aview.layer.cornerRadius = aview.frame.size.width/2;
        if ([sender isKindOfClass:[UILongPressGestureRecognizer class]]) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake((aview.frame.size.width/2.0)-30, -30, 60, 30)];
            label.text = @"Locked";
            label.textColor = [UIColor hex007AFF];
            aview.layer.borderColor = [UIColor hex007AFF].CGColor;
            [aview addSubview:label];
        }
        [self.previewView addSubview:aview];
        
        self.previewView.focusView = aview;
    }
    
    if (![sender isKindOfClass:[UILongPressGestureRecognizer class]] || ([sender isKindOfClass:[UILongPressGestureRecognizer class]] && sender.state == UIGestureRecognizerStateEnded)) {
        NSLog(@"tap");
        aview.alpha = 1;
        [UIView animateWithDuration:1.5 animations:^{
            aview.alpha = 0;
        } completion:^(BOOL finished) {
            [aview removeFromSuperview];
        }];
    }
}

#pragma mark - SensorManager

- (void)manager:(OSVSensorsManager *)manager didUpdateOBDData:(OSVOBDData *)data withError:(NSError *)error {
        self.obdStatus.hidden = NO;
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
                [self snapShotAtLocation:self.lastPhotoLocation];
                self.obdDistance = 0.0;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([[OSVUserDefaults sharedInstance].distanceUnitSystem isEqualToString:kMetricSystem]) {
                    self.obdSpeed.attributedText = [NSAttributedString combineString:[@(data.speed) stringValue] withSize:16.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                                               withString:@"\nkm/h" withSize:10.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"];
                } else {
                    self.obdSpeed.attributedText = [NSAttributedString combineString:[@([OSVUtils milesPerHourFromKmPerHour:data.speed]) stringValue] withSize:16.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                                          withString:@"\nmph" withSize:10.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"];
                }
             });
            self.currentOBDSpeed = data.speed / 3.6;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.obdSpeed.text = [NSString stringWithFormat:@"-"];
                self.decay = 0.0;
                self.currentOBDSpeed = -1;
            });
        }
}

#pragma mark - OSVOBDController Notifications

- (void)managerDidConnectToOBD:(OSVSensorsManager *)manager {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.obdStatus.hidden = NO;
    });
    
    self.hadOBD = YES;
}

- (void)managerDidDisconnectFromOBD:(OSVSensorsManager *)manager {
    if (self.isSnapping) {
        [[OSVLocationManager sharedInstance].sensorsManager reconnectOBD];
    }
    
    self.currentOBDSpeed = -1;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.obdStatus.hidden = YES;
    });
}

- (void)managerDidFailToConnectODB:(OSVSensorsManager *)manager {
    self.currentOBDSpeed = -1;

    dispatch_async(dispatch_get_main_queue(), ^{
        self.obdStatus.hidden = YES;
    });
}

#pragma mark - UIApplication Notifications 

- (void)willEnterForgroundNotification:(NSNotification *)notification {
    if (self.isSnapping) {
        self.backgroundRenderingID = UIBackgroundTaskInvalid;
        AVCaptureVideoOrientation orientation = [[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] videoOrientation];
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

@end
