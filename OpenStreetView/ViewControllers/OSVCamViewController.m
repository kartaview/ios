//
//  OSVCamViewController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 09/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVCamViewController.h"

#import <AVFoundation/AVFoundation.h>
#import "AVCamPreviewView.h"

#import <SKMaps/SKPositionerService.h>
#import "OSVUserDefaults.h"
#import "OSVLocationManager.h"
#import "OSVUtils.h"

#import "OSVSequence.h"

#import "OSVSyncController.h"

#import "UIAlertView+Blocks.h"

#import "OSVReachablityController.h"
#import "UIColor+OSVColor.h"

#import "OSVTipView.h"

#import <SKMaps/SKMaps.h>
#import "OSVDotedPolyline.h"

#import "OSVCameraManager.h"

#import "OSVPersistentManager.h"

#import "OSVLogger.h"

#import "NSMutableAttributedString+Additions.h"
#import "NSAttributedString+Additions.h"

@interface OSVCamViewController () <UIGestureRecognizerDelegate, OSVCameraManagerDelegate>

// Communicate with the session and other session objects on this queue.
@property (nonatomic) dispatch_queue_t                  sessionQueue;
@property (nonatomic) AVCaptureSession                  *session;
@property (nonatomic) AVCaptureStillImageOutput         *stillImageOutput;
//interface builder elements
@property (weak, nonatomic) IBOutlet UIButton           *startCapture;
@property (weak, nonatomic) IBOutlet UIButton           *cancelButton;
//OBD
@property (weak, nonatomic) IBOutlet UILabel            *obdSpeed;
@property (weak, nonatomic) IBOutlet UIView             *obdStatus;
//signs
@property (weak, nonatomic) IBOutlet UIImageView        *recognizedSign;
//info labels and container view
@property (weak, nonatomic) IBOutlet UIView             *infoView;
@property (weak, nonatomic) IBOutlet UILabel            *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel            *photosCountLabel;
@property (weak, nonatomic) IBOutlet UILabel            *storageUsedLabel;
@property (weak, nonatomic) IBOutlet UILabel            *sugestionLabel;
//containers/other helper views
@property (weak, nonatomic) IBOutlet UIView             *mapContainer;
@property (weak, nonatomic) IBOutlet UIView             *topContainer;
@property (weak, nonatomic) IBOutlet UIImageView        *gpsQuality;
@property (weak, nonatomic) IBOutlet UIImageView        *arrow;
@property (weak, nonatomic) IBOutlet UIImageView        *arrow1;
//map constraits
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingMap;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topMap;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomMap;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *trailingMap;
//preview constarints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingPreview;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topPreview;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomPreview;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *trailingPreview;
@property (weak, nonatomic) IBOutlet SKMapView          *mapView;
//info
@property (strong, nonatomic) OSVTipView                *tipView;
// state values
@property (strong, nonatomic) OSVDotedPolyline          *doted;
@property (assign, nonatomic) BOOL                      mapFullScreen;
@property (assign, nonatomic) BOOL                      hadGPS;
@property (assign, nonatomic) BOOL                      hadOBD;
//controllers/managers
@property (nonatomic, strong) OSVCameraManager          *cameraManager;

@end

@implementation OSVCamViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [UIViewController attemptRotationToDeviceOrientation];
    
    self.startCapture.clipsToBounds = YES;
    self.gpsQuality.hidden = YES;
    self.infoView.alpha = 0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    self.mapView.mapScaleView.hidden = YES;
    self.mapView.clipsToBounds = YES;
    self.mapView.settings.showCompass = NO;
    self.mapView.settings.displayMode = SKMapDisplayMode2D;
    self.mapView.settings.showStreetNamePopUps = YES;
//    self.mapView.settings.osmAttributionPosition = SKAttributionPositionNone;
//    self.mapView.settings.companyAttributionPosition = SKAttributionPositionNone;
    
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
    
    self.cameraManager = [[OSVCameraManager alloc] initWithOutput:self.stillImageOutput preview:(AVCaptureVideoPreviewLayer *)self.previewView.layer deviceFromat:self.deviceFormat queue:self.sessionQueue];
    self.cameraManager.delegate = self;
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
    [self.cameraManager makeStillCaptureWithLocation:localtion];
}

- (IBAction)didTapStartCapture:(id)sender {
    if (!self.cameraManager.isSnapping) {
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
    
    [self startNavigation];

    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.cameraManager startHighResolutionCapure];
        [self.cameraManager startLowResolutionCapture];
        
        [self updateUIInfo];

        [[OSVLocationManager sharedInstance].sensorsManager startLoggingSensors];
        [[OSVLocationManager sharedInstance].sensorsManager startUpdatingAccelerometer];
        [[OSVLocationManager sharedInstance].sensorsManager startUpdatingGyro];
        [[OSVLocationManager sharedInstance].sensorsManager startUpdatingMagnetometer];
        [[OSVLocationManager sharedInstance].sensorsManager startUpdatingAltitude];
        
        [self updateUIwithState:YES];
    } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [[SKPositionerService sharedInstance] startLocationUpdate];
        [[NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(didChangeAuthorizationStatus:) name:@"didChangeAuthorizationStatus" object:nil];
    } else {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Location Services access", nil) message:NSLocalizedString(@"Please allow access to Location Services from Settings before starting a recording", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    }
}

- (void)resetValues {
    [self.cameraManager resetValues];
    
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
    [self.cameraManager stopHighResolutionCapture];
    [self.cameraManager stopLowResolutionCapture];
    
    [[OSVLocationManager sharedInstance].sensorsManager stopLoggingSensors];
    [[OSVLocationManager sharedInstance].sensorsManager stopUpdatingAccelerometer];
    [[OSVLocationManager sharedInstance].sensorsManager stopUpdatingGyro];
    [[OSVLocationManager sharedInstance].sensorsManager stopUpdatingMagnetometer];
    [[OSVLocationManager sharedInstance].sensorsManager stopUpdatingAltitude];
    
    
    [self updateUIwithState:NO];
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"didFinishCreatingSequence" object:nil userInfo:@{@"sequenceID":@(self.currentSequence)}];
    
    if ([OSVUserDefaults sharedInstance].automaticUpload && ([OSVReachablityController hasWiFiAccess] || ([OSVReachablityController hasCellularAcces] && [OSVUserDefaults sharedInstance].useCellularData))) {
//        //TODO upload current sequence to server.
    }
    
    [self resetValues];
}

- (void)updateUIwithState:(BOOL)value {
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
    if ([[OSVUserDefaults sharedInstance].distanceUnitSystem isEqualToString:kMetricSystem]) {
        NSArray *metricArray = [OSVUtils metricDistanceArray:self.cameraManager.distanceCoverd];
        self.distanceLabel.attributedText = [NSAttributedString combineString:metricArray[0] withSize:16.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                                   withString:metricArray[1] withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"];
    } else {
        NSArray *imperialArray = [OSVUtils imperialDistanceArray:self.cameraManager.distanceCoverd];
        self.distanceLabel.attributedText = [NSAttributedString combineString:imperialArray[0] withSize:16.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                                   withString:imperialArray[1] withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"];
    }

    self.photosCountLabel.attributedText = [NSAttributedString combineString:[@(self.cameraManager.frameCount) stringValue] withSize:16.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                                  withString:@" IMG" withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"];
    
    NSArray *memoryArray = [OSVUtils arrayFormatedFromByteCount:self.cameraManager.usedMemory];
    self.storageUsedLabel.attributedText = [NSAttributedString combineString:memoryArray[0] withSize:16.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                        withString:memoryArray[1] withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"];
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

#pragma mark - OSVCameraManagerDelegate

- (void)willStopCapturing {
    [UIAlertView showWithTitle:@"" message:NSLocalizedString(@"Minimum reserved disk space reached. The recording will stop now.", @"") style:UIAlertViewStyleDefault cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
        [self stopSequence];
    }];
}

- (void)shouldDisplayTraficSign:(UIImage *)traficSign {
    if (traficSign) {
        self.recognizedSign.hidden = NO;
        self.recognizedSign.image = traficSign;
    } else {
        self.recognizedSign.hidden = YES;
    }
}

- (void)didChangeGPSStatus:(UIImage *)gpsStatus {
    self.gpsQuality.hidden = NO;
    self.gpsQuality.image = gpsStatus;
}

- (void)didChangeOBDInfo:(double)value withError:(NSError *)error {
    self.obdStatus.hidden = NO;
    if (error) {
        self.obdSpeed.text = [NSString stringWithFormat:@"-"];
        return;
    }
    
    if ([[OSVUserDefaults sharedInstance].distanceUnitSystem isEqualToString:kMetricSystem]) {
        self.obdSpeed.attributedText = [NSAttributedString combineString:[@(value) stringValue] withSize:16.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                              withString:@"\nkm/h" withSize:10.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"];
    } else {
        self.obdSpeed.attributedText = [NSAttributedString combineString:[@([OSVUtils milesPerHourFromKmPerHour:value]) stringValue] withSize:16.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                              withString:@"\nmph" withSize:10.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"];
    }
}

- (void)showOBD:(BOOL)value {
    self.obdStatus.hidden = value;
}

- (void)didAddNewLocation:(CLLocation *)location {
    if (!self.doted) {
        self.doted = [OSVDotedPolyline new];
        self.doted.strokeColor = [UIColor hex007AFF];
        self.doted.coordinates = @[location];
        [self.mapView addPolyline:self.doted];
    } else {
        NSMutableArray *array = [NSMutableArray arrayWithArray:self.doted.coordinates];
        [array addObject:location];

        self.doted.coordinates = array;
        [self.mapView addPolyline:self.doted];
    }
}

- (void)didReceiveUIUpdate {
    [self updateUIInfo];
}

@end
