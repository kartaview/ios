//
//  OSVLayersViewController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 18/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVLayersViewController.h"
#import "OSVMyProfileCell.h"
#import "OSVTrackCell.h"
#import "OSVServerSequence.h"
#import "OSVSyncController.h"
#import "NSAttributedString+Additions.h"
#import "OSVUserDefaults.h"
#import "UIColor+OSVColor.h"
#import "OSVUtils.h"

#import "OSVAPISerialOperation.h"
#import "OSVVideoPlayerViewController.h"

@interface OSVLayersViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) CLGeocoder                    *geocoder;
@property (strong, nonatomic) NSOperationQueue              *reverseGeocodeQueue;

@property (strong, nonatomic) UIColor *previousBarTintColor;
@property (strong, nonatomic) UIImage *previousShadowImage;
@property (strong, nonatomic) UIImage *previousBackgroundImage;

@end

@implementation OSVLayersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.geocoder = [CLGeocoder new];
    self.reverseGeocodeQueue = [NSOperationQueue new];
    self.reverseGeocodeQueue.maxConcurrentOperationCount = 1;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    self.previousBarTintColor = self.navigationController.navigationBar.barTintColor;
    self.previousShadowImage = self.navigationController.navigationBar.shadowImage;
    self.previousBackgroundImage = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithHex:0x3b3e47];
    self.navigationController.navigationBar.translucent = NO;
    
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.barTintColor = self.previousBarTintColor;
    self.navigationController.navigationBar.shadowImage = self.previousShadowImage;
    [self.navigationController.navigationBar setBackgroundImage:self.previousBackgroundImage forBarMetrics:UIBarMetricsDefault];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showPlayerLayers"]) {
        OSVVideoPlayerViewController *vc = segue.destinationViewController;
        NSIndexPath *path = sender;
        vc.selectedSequence = self.datasource[path.row];
        OSVServerSequencePart *sq = vc.selectedSequence;
        [vc displayFrameAtIndex:sq.selectedIndex];
    }
}

#pragma mark - Orientation

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datasource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OSVServerSequencePart *track = self.datasource[indexPath.row];
    
    OSVTrackCell *trackCell = [tableView dequeueReusableCellWithIdentifier:@"layerCell"];
    [[OSVSyncController sharedInstance].tracksController loadPreviewForTrack:track intoImageView:trackCell.previewImage withCompletion:^(UIImage *image, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            trackCell.previewImage.image = image;
        });
    }];

    trackCell.photoCountLabel.attributedText = [NSAttributedString combineString:[@(track.photoCount) stringValue] withSize:12.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                                      withString:@" IMG" withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"];
    if ([[OSVUserDefaults sharedInstance].distanceUnitSystem isEqualToString:kMetricSystem]) {
        NSArray *metricArray = [OSVUtils metricDistanceArray:track.length];
        trackCell.distanceLabel.attributedText = [NSAttributedString combineString:metricArray[0] withSize:12.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                                        withString:metricArray[1] withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"];
    } else {
        NSArray *imperialArray = [OSVUtils imperialDistanceArray:track.length];
        trackCell.distanceLabel.attributedText = [NSAttributedString combineString:imperialArray[0] withSize:12.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                                        withString:imperialArray[1] withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"];
    }
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"MM.dd.YY "];
    NSString *dString = [formatter stringFromDate:track.dateAdded];
    [formatter setDateFormat:@"| hh:mm"];
    NSString *hString = [formatter stringFromDate:track.dateAdded];
    
    trackCell.dateLabel.attributedText = [NSAttributedString combineString:dString withSize:12.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"
                                                                withString:hString withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"];
    
    if ((!track.location || [track.location isEqualToString:@""])) {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:track.coordinate.latitude longitude:track.coordinate.longitude] ;
        
        OSVAPISerialOperation *operation = [OSVAPISerialOperation new];
        typeof(operation) woperation = operation;
        
        operation.asyncTask = ^(OSVAPISerialOperation *op) {
            [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray* placemarks, NSError* error) {
                if ([placemarks count] > 0) {
                    CLPlacemark *placemark = placemarks[0];
                    NSArray *lines = placemark.addressDictionary[@"FormattedAddressLines"];
                    NSString *addressString = [lines componentsJoinedByString:@","];
                    track.location = addressString;
                    trackCell.locationLabel.text = addressString;
                }
                [woperation asyncTaskDone];
            }];
        };
        
        [self.reverseGeocodeQueue addOperation:operation];
    } else {
        trackCell.locationLabel.text = [NSString stringWithFormat:@"%@", track.location];
    }
    
    return trackCell;
}

- (IBAction)didtapBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"showPlayerLayers" sender:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (tableView.frame.size.width - 24) * 3/4 + 70;
}

@end
