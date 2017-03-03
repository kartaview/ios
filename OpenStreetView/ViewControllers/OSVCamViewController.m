//
//  OSVCamViewController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 09/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVCamViewController.h"

#import <Crashlytics/Crashlytics.h>

#import <AVFoundation/AVFoundation.h>
#import "AVCamPreviewView.h"

#import <SKMaps/SKPositionerService.h>
#import "OSVUserDefaults.h"
#import "OSVLocationManager.h"
#import "OSVUtils.h"
#import "UIDevice+Aditions.h"
#import "UIViewController+Additions.h"

#import "OSVSequence.h"

#import "OSVSyncController.h"
#import "OSVUser.h"

#import "UIAlertView+Blocks.h"

#import "OSVReachablityController.h"
#import "UIColor+OSVColor.h"

#import "OSVTipView.h"

#import <SKMaps/SKMaps.h>
#import "OSVDotedPolyline.h"

#import "OSVCameraManager.h"
#import "OSVCameraMapManager.h"

#import "OSVPersistentManager.h"

#import "OSVLogger.h"

#import "NSMutableAttributedString+Additions.h"
#import "NSAttributedString+Additions.h"

#import "OSVTrackMatcher.h"

#import "OSVCameraGamificationManager.h"

#import "OSC-Swift.h"

@interface OSVCamViewController () <UIGestureRecognizerDelegate, OSVCameraManagerDelegate>

// Communicate with the session and other session objects on this queue.
@property (nonatomic) dispatch_queue_t                  sessionQueue;
@property (nonatomic) AVCaptureSession                  *session;
@property (nonatomic) AVCaptureStillImageOutput         *stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput  *videoOutput;

//interface builder elements
@property (weak, nonatomic) IBOutlet UIButton           *startCapture;
@property (weak, nonatomic) IBOutlet UIButton           *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton           *infoButton;
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

@property (strong, nonatomic) SKMapView                 *mapView;
@property (weak, nonatomic) IBOutlet UIView             *mapViewPlaceholder;
//info
@property (strong, nonatomic) OSVTipView                *tipView;
// state values
@property (strong, nonatomic) OSVDotedPolyline          *doted;
@property (assign, nonatomic) BOOL                      mapFullScreen;
@property (assign, nonatomic) BOOL                      hadGPS;
@property (assign, nonatomic) BOOL                      hadOBD;
//controllers/managers
@property (nonatomic, strong) OSVCameraManager          *cameraManager;
@property (nonatomic, strong) OSVCameraMapManager       *mapManager;
//gamification UI responseble
@property (strong, nonatomic) IBOutlet OSVCameraGamificationManager *gamificationManager;

@end

@implementation OSVCamViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [UIViewController attemptRotationToDeviceOrientation];

    self.startCapture.clipsToBounds = YES;
    self.gpsQuality.hidden = YES;
    self.infoView.alpha = 0;
    
    if (![OSVUserDefaults sharedInstance].showMapWhileRecording ||
        ![OSVUserDefaults sharedInstance].enableMap) {
        [self.mapContainer removeFromSuperview];
        [self.mapView removeFromSuperview];
        self.mapContainer = nil;
        self.mapView = nil;
    } else {
        self.mapView = [[SKMapView alloc] initWithFrame:self.mapViewPlaceholder.bounds];
        self.mapManager = [[OSVCameraMapManager alloc] initWithMap:self.mapView];
        [UIViewController addMapView:self.mapView toView:self.mapViewPlaceholder];
    }
    
    self.gamificationManager.delegate = self;
    
    [self.gamificationManager prepareFirstTimeUse];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

    [[OSVLogger sharedInstance] createNewLogFile];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    [self.gamificationManager configureUIForInterfaceOrientation:orientation];
    
	[self animateInfoButton];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.mapView.settings.followUserPosition = YES;
    
    [self.mapView centerOnCurrentPosition];
    [self.mapView animateToZoomLevel:[OSVUserDefaults sharedInstance].zoomLevel];

    self.cameraManager = [[OSVCameraManager alloc] initWithOutput:self.videoOutput
                                                          preview:(AVCaptureVideoPreviewLayer *)self.previewView.layer
                                                     deviceFromat:self.deviceFormat
                                                            queue:self.sessionQueue];
    
    if ((![OSVUserDefaults sharedInstance].showMapWhileRecording ||
        ![OSVUserDefaults sharedInstance].enableMap) &&
        [OSVUserDefaults sharedInstance].useGamification) {
        self.cameraManager.matcher = [OSVTrackMatcher new];
    }
    
    self.cameraManager.delegate = self;
    self.cameraManager.cameraMapManager = self.mapManager;
    self.gamificationManager.cameraManager = self.cameraManager;

    [self.videoOutput setSampleBufferDelegate:self.cameraManager queue:[self sessionQueue]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[OSVLogger sharedInstance] logMessage:@"DidReceiveMemoryWarning" withLevel:LogLevelDEBUG];
    
    NSString *username = [OSVSyncController sharedInstance].tracksController.oscUser.name;
    [Answers logCustomEventWithName:@"didReceiveMemoryWarning" customAttributes:@{@"Show Map"       :   [OSVUserDefaults sharedInstance].showMapWhileRecording? @"YES":@"NO",
                                                                                  @"Resolution"     :   [OSVUserDefaults sharedInstance].videoQuality,
                                                                                  @"PhotoCount"     :   @(self.cameraManager.frameCount),
                                                                                  @"Detect Signs"   :   [OSVUserDefaults sharedInstance].useImageRecognition? @"YES":@"NO",
                                                                                  @"Model"          :   [UIDevice modelString],
                                                                                  @"UserName"       :   username ? username : @"unknown"}];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([sender isKindOfClass:[NSArray class]] && [sender count]) {
		NSArray *array = sender;
		NSNumber *seqID = array[0];
		NSNumber *shouldDissmissAll = @(NO);
		if (array.count > 1) {
			shouldDissmissAll = array[1];
		}
        [[OSVSyncController sharedInstance].tracksController getLocalSequenceWithID:[seqID integerValue] completion:^(OSVSequence *sequence) {
            [[OSVSyncController sharedInstance].tracksController getScoreHistoryForSequenceWithID:sequence.uid completion:^(NSArray *history) {
                sequence.scoreHistory = [history mutableCopy];
                sequence.points = 0;
                for (OSVScoreHistory *sch in history) {
                    sequence.points += sch.points;
                }
                SummaryViewController *vc = segue.destinationViewController;
                vc.sequence = sequence;
                if ([shouldDissmissAll boolValue]) {
                    vc.willDissmiss = ^{
                        [self dismissViewControllerAnimated:YES completion:^{
                            
                        }];
                    };
                }
            }];
        }];
    }
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
    CLLocation *localtion = [[CLLocation alloc] initWithCoordinate:[[OSVLocationManager sharedInstance] currentLocation].coordinate
                                                          altitude:0
                                                horizontalAccuracy:1000
                                                  verticalAccuracy:1000
                                                         timestamp:[NSDate new]];
    [self.cameraManager makeStillCaptureWithLocation:localtion];
}

- (IBAction)didTapStartCapture:(UIButton *)sender {
    if (!self.cameraManager.isRecording) {
        [self startNewSequence];
    } else {
        if (self.cameraManager.score > 10) {
            sender.userInteractionEnabled = NO;
            NSInteger sequenceID = self.cameraManager.currentSequence;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[self performSegueWithIdentifier:@"showSummary" sender:@[@(sequenceID), @(NO)]];
                sender.userInteractionEnabled = YES;
            });
        }
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
            [self.topContainer insertSubview:self.mapViewPlaceholder aboveSubview:self.previewView];
        } else {
            [self.topContainer insertSubview:self.previewView aboveSubview:self.mapViewPlaceholder];
        }
        self.mapFullScreen = !self.mapFullScreen;
        sender.enabled = YES;
    }];
}

- (void)animateFullScreen {
    
    self.topMap.constant = -self.mapContainer.frame.origin.y;
    self.leadingMap.constant = -10;
    self.trailingMap.constant = self.topContainer.frame.size.width - CGRectGetMaxX(self.mapContainer.frame);
	
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
    
    self.mapViewPlaceholder.frame = self.topContainer.frame;
    self.mapView.frame = self.topContainer.bounds;
    
    self.previewView.frame = self.mapContainer.frame;
    self.previewView.layer.cornerRadius = 3;
    self.previewView.clipsToBounds = YES;
}

- (void)animateNormalSize {
    self.leadingMap.constant = 0;
    self.bottomMap.constant = 0;
    self.topMap.constant = 0;
    self.trailingMap.constant = 0;
    self.mapViewPlaceholder.frame = self.mapContainer.frame;
    self.mapView.frame = self.mapContainer.bounds;

    self.topPreview.constant = 0;
    self.leadingPreview.constant = 0;
    self.trailingPreview.constant = 0;
    self.bottomPreview.constant = 0;
    self.previewView.frame = self.topContainer.frame;
    self.previewView.layer.cornerRadius = 0;
    self.previewView.clipsToBounds = NO;
}

- (void)startNewSequence {
    self.hadGPS = NO;
    self.hadOBD = NO;
    
    [self resetValues];

    self.sugestionLabel.hidden = YES;
    self.arrow.hidden = YES;
    self.arrow1.hidden = YES;
    [self.cancelButton setTitle:NSLocalizedString(@"Done", @"") forState:UIControlStateNormal];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.infoView.alpha = 1;
    } completion:^(BOOL finished) {
        self.infoView.alpha = 1;
    }];
    
   self.mapView.settings.followUserPosition = YES;

    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.cameraManager startHighResolutionCapure];
        
        [self updateUIInfo];

        [[OSVSensorsManager sharedInstance] startAllSensors];
                
        self.startCapture.selected = YES;

        [self.gamificationManager expandMultiplier];
        
    } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [[OSVLocationManager sharedInstance] startLocationUpdate];
        [[NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(didChangeAuthorizationStatus:) name:@"didChangeAuthorizationStatus" object:nil];
    } else {
        [UIAlertView showWithTitle:NSLocalizedString(@"No Location Services access", nil) message:NSLocalizedString(@"Please allow access to Location Services from Settings before starting a recording", @"") cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            [self dismissViewControllerAnimated:YES completion:^{
                
            }];
        }];
    }
}

- (void)stopSequence {
    self.hadGPS = NO;
    self.hadOBD = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.infoView.alpha = 0;
    } completion:^(BOOL finished) {
        self.infoView.alpha = 0;
    }];
    
    [self.cameraManager stopHighResolutionCapture];
    
    [[OSVSensorsManager sharedInstance] stopAllSensors];
    
    self.startCapture.selected = NO;
    
    [self resetValues];

    [self.gamificationManager stopRecording];
}

- (void)resetValues {
    [self.cameraManager resetValues];
    
    [self updateUIInfo];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"will change to Orient:%ld", orientation] withLevel:LogLevelDEBUG];

    [self.gamificationManager configureUIForDeviceOrientation:orientation];
       
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {        
        if (self.mapFullScreen) {
            [self animateFullScreen];
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {

    }];
}

- (IBAction)didTapBackButton:(id)sender {
    [self.gamificationManager willDissmiss];
    
    if (self.cameraManager.score > 10) {
        NSInteger sequenceID = self.cameraManager.currentSequence;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self performSegueWithIdentifier:@"showSummary" sender:@[@(sequenceID),@(YES)]];
        });
        [self stopSequence];
    } else {
        [self stopSequence];
        [self dismissViewControllerAnimated:YES
                                 completion:^{}];
    }
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - Override

- (void)setDeviceAuthorized:(BOOL)deviceAuthorized {
    super.deviceAuthorized = deviceAuthorized;

    if (deviceAuthorized) {
        SKCoordinateRegion region;
        region.zoomLevel = [OSVUserDefaults sharedInstance].zoomLevel;
        region.center = [OSVLocationManager sharedInstance].currentLocation.coordinate;
        self.mapView.visibleRegion = region;
    }
}

#pragma mark - Private

- (OSVTipView *)tipView {
    if (!_tipView) {
        _tipView = [[[NSBundle mainBundle] loadNibNamed:@"OSVTipView" owner:self options:nil] objectAtIndex:0];
        [_tipView configureViews];
    }
    
    return _tipView;
}

- (void)updateUIInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
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
        [self.gamificationManager updateUIInfo];
    });
}

- (void)didChangeAuthorizationStatus:(NSNotification *)notification {
    NSNumber *status = notification.userInfo[@"status"];
    CLAuthorizationStatus stat = (CLAuthorizationStatus)[status integerValue];
    if (stat != kCLAuthorizationStatusNotDetermined) {
        if (stat != kCLAuthorizationStatusAuthorizedWhenInUse) {
            [[[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"Please allow access to Location Services before starting a recording", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", @"") otherButtonTitles:nil] show];
        } else {
            [self startNewSequence];
        }
    }
}

- (void)animateInfoButton {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[UIView animateWithDuration:0.15 animations:^{
			self.infoButton.transform = CGAffineTransformMakeScale(1.2, 1.2);
		} completion:^(BOOL finished) {
		[UIView animateWithDuration:0.2 animations:^{
			self.infoButton.transform = CGAffineTransformIdentity;
		} completion:^(BOOL finished) {
		[UIView animateWithDuration:0.15 animations:^{
			self.infoButton.transform = CGAffineTransformMakeScale(1.15, 1.15);
		} completion:^(BOOL finished) {
		[UIView animateWithDuration:0.5
							  delay:0.0
			 usingSpringWithDamping:0.15
			  initialSpringVelocity:0.2
							options:UIViewAnimationOptionCurveLinear
						 animations:^{
			self.infoButton.transform = CGAffineTransformIdentity;
		} completion:^(BOOL finished) {}]; }]; }]; }];
	});
}

#pragma mark - OSVCameraManagerDelegate

- (void)willStopCapturing {
    [UIAlertView showWithTitle:@"" message:NSLocalizedString(@"Minimum reserved disk space reached. The recording will stop now.", @"") style:UIAlertViewStyleDefault cancelButtonTitle:NSLocalizedString(@"Ok", @"") otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
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
        NSString *firstString = [NSString stringWithFormat:@"%.0f", [OSVUtils milesPerHourFromKmPerHour:value]];
        self.obdSpeed.attributedText = [NSAttributedString combineString:firstString withSize:16.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                              withString:@"\nmph" withSize:10.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"];
    }
}

- (void)hideOBD:(BOOL)value {
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
