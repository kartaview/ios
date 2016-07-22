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

#import "OSVMainViewController.h"
#import "OSVSyncController.h"
#import "OSVSettingsViewController.h"
#import "OSVLayersViewController.h"

#import "OSVLogger.h"

#define kMainViewController                            (OSVMainViewController *)[UIApplication sharedApplication].delegate.window.rootViewController

@interface OSVMapViewController () <CLLocationManagerDelegate, SKMapViewDelegate>

@property (strong, nonatomic) OSVSyncController     *syncController;

@property (assign, nonatomic) BOOL                  hasFirstLocation;

@end

@implementation OSVMapViewController


- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mapView.settings.showCurrentPosition = NO;
    self.mapView.mapScaleView.hidden = YES;
    
    self.syncController = [OSVSyncController sharedInstance];

    self.mapController = [OSVBasicMapController new];
    self.mapController.viewController = self;
    
    self.sequenceMapController = [OSVSequenceMapController new];
    self.sequenceMapController.viewController = self;
   
    SKMapViewStyle *mapViewStyle = [SKMapViewStyle mapViewStyle];
    mapViewStyle.resourcesFolderName = @"GrayscaleStyle";
    mapViewStyle.styleFileName = @"grayscalestyle.json";
    [SKMapView setMapStyle:mapViewStyle];
    
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
    
    if ([CLLocationManager authorizationStatus] !=  kCLAuthorizationStatusNotDetermined) {
        if ([OSVUserDefaults sharedInstance].realPositions) {
            [[SKPositionerService sharedInstance] setPositionerMode:SKPositionerModeRealPositions];
        }
    } else {
        SKCoordinateRegion region;
        region.zoomLevel = 3.5;
        region.center =  CLLocationCoordinate2DMake(44.272544, -103.022256);
        [self.mapView setVisibleRegion:region];
    }
    
    if (![OSVUserDefaults sharedInstance].realPositions) {
        [[SKPositionerService sharedInstance] setPositionerMode:SKPositionerModePositionSimulation];
    }
    
    [OSVLocationManager sharedInstance].delegate = self;

    self.mapView.delegate = self;
    
    self.controller = self.mapController;
    
    [self.controller willChangeUIControllerFrom:self.controller animated:NO];
    self.actIndicator.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.controller reloadVisibleTracks];
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.controller didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Actions

- (IBAction)didTapRightButton:(id)sender {
    [self.sequenceMapController didTapRightButton];
}

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
    if (![OSVUserDefaults sharedInstance].realPositions) {
        [[SKPositionerService sharedInstance] reportGPSLocation:[newLocation firstObject]];
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

    UIStoryboard *storyBoard = self.storyboard;
    UIViewController *targetViewController = [storyBoard instantiateViewControllerWithIdentifier:@"cameraViewController"];

    [self.navigationController pushViewController:targetViewController animated:NO];
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
    }
}

@end
