//
//  ViewController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 09/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVMapViewController.h"
#import "OSVLocationManager.h"
#import "OSVUserDefaults.h"
#import "OSVSyncController.h"
#import "OSVUtils.h"

#import "OSVSequenceMapController.h"
#import "OSVBasicMapController.h"
#import "OSVVideoPlayerViewController.h"
#import "UIViewController+Additions.h"

#import "OSVMainViewController.h"
#import "OSVSyncController.h"
#import "OSVSettingsViewController.h"
#import "OSVLayersViewController.h"
#import "OSVRecordTransition.h"
#import "OSVDissmissRecordTransition.h"
#import "OSVPushTransition.h"
#import "OSVPopTransition.h"

#import "OSVLogger.h"

#import "OSVTipView.h"
#import "OSC-Swift.h"

#define kMainViewController                            (OSVMainViewController *)[UIApplication sharedApplication].delegate.window.rootViewController

@interface OSVMapViewController () <CLLocationManagerDelegate, SKMapViewDelegate, UIViewControllerTransitioningDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) OSVSyncController     *syncController;

@property (assign, nonatomic) BOOL                  hasFirstLocation;

@end

@implementation OSVMapViewController


- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([OSVUserDefaults sharedInstance].enableMap) {
        self.mapView = [[SKMapView alloc] initWithFrame:self.mapContainer.bounds];
    }
    [UIViewController addMapView:self.mapView toView:self.mapContainer];
    
    self.mapView.settings.showCurrentPosition = NO;
    self.mapView.mapScaleView.hidden = YES;
    
    self.syncController = [OSVSyncController sharedInstance];

    self.mapController = [OSVBasicMapController new];
    self.mapController.viewController = self;
    
    self.sequenceMapController = [OSVSequenceMapController new];
    self.sequenceMapController.viewController = self;
   
    self.syncController.didChangeReachabliyStatus = ^(OSVReachabilityStatus status) {
        BOOL shouldUseCellular = ((status == OSVReachabilityStatusCellular) && [OSVUserDefaults sharedInstance].useCellularData);

        if ((status == OSVReachabilityStatusWiFi || shouldUseCellular) &&
            [OSVUserDefaults sharedInstance].automaticUpload &&
            ![OSVUserDefaults sharedInstance].isUploading) {

            [[OSVSyncController sharedInstance].tracksController uploadAllSequencesWithCompletion:^(NSError *error) {
            } partialCompletion:^(OSVMetadata *metadata, NSError *error) {
            }];
        }
    };
    
    self.bottomRightButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.bottomRightButton.layer.shadowOffset = CGSizeMake(0, 1);
    self.bottomRightButton.layer.shadowRadius = 1;
    self.bottomRightButton.layer.shadowOpacity = 0.2;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.delegate = self;
    self.mapView.frame = self.mapContainer.bounds;
    if ([CLLocationManager authorizationStatus] !=  kCLAuthorizationStatusNotDetermined) {
        if ([OSVUserDefaults sharedInstance].realPositions &&
            [OSVUserDefaults sharedInstance].enableMap) {
            [OSVLocationManager sharedInstance].positionerMode = SKPositionerModeRealPositions;
        }
    } else {
        SKCoordinateRegion region;
        region.zoomLevel = 3.5;
        region.center =  CLLocationCoordinate2DMake(44.272544, -103.022256);
        [self.mapView setVisibleRegion:region];
    }
    
    if (![OSVUserDefaults sharedInstance].realPositions &&
        [OSVUserDefaults sharedInstance].enableMap) {
        [OSVLocationManager sharedInstance].positionerMode = SKPositionerModePositionSimulation;
    }
    
    [OSVLocationManager sharedInstance].delegate = self;

    self.mapView.delegate = self;
    
    self.controller = self.mapController;
    
    [self.controller willChangeUIControllerFrom:self.controller animated:NO];
    self.actIndicator.hidden = YES;
    
    if ([OSVUserDefaults sharedInstance].isFreshInstall) {

        [OSVUserDefaults sharedInstance].isFreshInstall = NO;
        [[OSVUserDefaults sharedInstance] save];
        
        PortraitViewController *vc = [PortraitViewController new];
        vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        OSVTipView *tipView = [[[NSBundle mainBundle] loadNibNamed:@"OSVTipView" owner:self options:nil] objectAtIndex:0];
        [tipView prepareIntro];
        [tipView configureViews];
        tipView.willDissmiss = ^() {
            [vc dismissViewControllerAnimated:YES completion:^{}];
            return YES;
        };
        
        [self presentViewController:vc animated:NO completion:^{
            [vc.view addSubview:tipView];
        }];
        tipView.frame = self.navigationController.view.frame;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.controller reloadVisibleTracks];
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.mapView clearAllOverlays];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.controller didReceiveMemoryWarning];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

#pragma mark - Orientation

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Actions

- (IBAction)didTapPositionMe:(id)sender {
    [self.controller didTapBottomRightButton];
}

- (IBAction)didTapBackButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)didTapMenuItem:(id)sender {
    [kMainViewController showLeftViewAnimated:YES completionHandler:^{
    }];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)newLocation {
    if (![OSVUserDefaults sharedInstance].realPositions &&
        [OSVUserDefaults sharedInstance].enableMap) {
        [[OSVLocationManager sharedInstance] reportGPSLocation:[newLocation firstObject]];
    } else {
        if (!self.hasFirstLocation) {
            self.mapView.settings.showCurrentPosition = YES;
            CLLocation *location = [newLocation firstObject];
            SKCoordinateRegion region;
            region.zoomLevel = 14;
            region.center = location.coordinate;
            [self.mapView setVisibleRegion:region];

            self.hasFirstLocation = YES;
        }
    }
}

#pragma mark - SKMapViewDelegate

- (void)mapView:(SKMapView *)mapView didEndRegionChangeToRegion:(SKCoordinateRegion)region {
    SKBoundingBox *box = [SKBoundingBox boundingBoxForRegion:region inMapViewWithSize:self.mapView.frame.size];
    [self.mapController didEndRegionChange:(id<OSVBoundingBox>)box withZoomlevel:region.zoomLevel];
}

- (void)mapView:(SKMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    if (!self.shouldDisplayBack) {
        [self.mapController willChangeUIControllerFrom:self.controller animated:NO];
        self.controller = self.mapController;
    }
    
    [self.mapController didTapAtCoordinate:coordinate];
}

- (IBAction)didTapCameraShow:(id)sender {
    [self.mapView clearAllOverlays];
    [self performSegueWithIdentifier:@"showCamera" sender:self];
}

#pragma mark - Overriden

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [self.mapView clearAllOverlays];

    if ([segue.identifier isEqualToString:@"presentReview"]) {
        OSVVideoPlayerViewController *vc = segue.destinationViewController;
        vc.selectedSequence = self.selectedSequence;
        [vc displayFrameAtIndex:self.sequenceMapController.selectedIndexPath.row];
    } else if([segue.identifier isEqualToString:@"showSettings"]) {
        OSVSettingsViewController *vc = segue.destinationViewController;
        UIButton *title = vc.settingsTitle;
        [title setTitle:NSLocalizedString(@"Settings",@"") forState:UIControlStateNormal];
    } else if ([segue.identifier isEqualToString:@"showLayers"]) {
        OSVLayersViewController *vc = segue.destinationViewController;
        vc.datasource = sender;
    } else if ([segue.identifier isEqualToString:@"showCamera"] ||
               [segue.identifier isEqualToString:@"showMyProfile"] ||
               [segue.identifier isEqualToString:@"showLocalTracks"] ||
               [segue.identifier isEqualToString:@"showLeaderboard"] ||
			   [segue.identifier isEqualToString:@"showLoginController"]) {
        UIViewController *vc = segue.destinationViewController;
        vc.transitioningDelegate = self;
    }
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    if ([presented isKindOfClass:NSClassFromString(@"OSVCamViewController")]) {
        return [OSVRecordTransition new];
    }
    
    return nil;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    if ([dismissed isKindOfClass:NSClassFromString(@"OSVCamViewController")]) {
        [self.controller didTapBottomRightButton];
        return [OSVDissmissRecordTransition new];
    }
    return nil;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                            animationControllerForOperation:(UINavigationControllerOperation)operation
                                                         fromViewController:(UIViewController *)fromVC
                                                           toViewController:(UIViewController *)toVC {
    if ([toVC isKindOfClass:NSClassFromString(@"OSVMyProfileViewController")]||
        [toVC isKindOfClass:NSClassFromString(@"OSVLocalTracksViewController")]||
        [toVC isKindOfClass:NSClassFromString(@"OSVSettingsViewController")]||
        [toVC isKindOfClass:NSClassFromString(@"OSVLeaderboardViewController")] ||
		[NSStringFromClass(toVC.class) containsString:@"LoginViewController"]) {
		
        return [[OSVPushTransition alloc] initWithoutAnimatingSource:YES];
    } else if ([fromVC isKindOfClass:NSClassFromString(@"OSVMyProfileViewController")]||
               [fromVC isKindOfClass:NSClassFromString(@"OSVLocalTracksViewController")]||
               [fromVC isKindOfClass:NSClassFromString(@"OSVSettingsViewController")]||
               [fromVC isKindOfClass:NSClassFromString(@"OSVLeaderboardViewController")] ||
			   [NSStringFromClass(fromVC.class) containsString:@"LoginViewController"]) {
        
        return [[OSVPopTransition alloc] initWithoutAnimatingSource:YES];
    }
    
    return nil;
}



@end
