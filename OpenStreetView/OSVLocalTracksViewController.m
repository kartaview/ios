//
//  OSVLocalTracksViewController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 07/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVLocalTracksViewController.h"
#import "OSVSyncController.h"
#import "OSVLocalTrackCell.h"

#import "OSVSequence.h"
#import "OSVPhoto.h"
#import "OSVAPISerialOperation.h"
#import "OSVPersistentManager.h"

#import "OSVUserDefaults.h"
#import "OSVUtils.h"
#import "OSVReachablityController.h"
#import "OSVUploadViewController.h"
#import "OSVVideoPlayerViewController.h"

#import "UIColor+OSVColor.h"
#import "NSAttributedString+Additions.h"

@interface OSVLocalTracksViewController ()

@property (weak, nonatomic) IBOutlet UIButton *tracksCount;
@property (weak, nonatomic) IBOutlet UIButton *viewControllerTitle;

@property (nonatomic, strong) NSMutableArray<OSVSequence *>    *dataSource;

@property (strong, nonatomic) CLGeocoder                    *geocoder;
@property (strong, nonatomic) NSOperationQueue              *reverseGeocodeQueue;
@property (assign, nonatomic) BOOL                          metricSystem;
@property (weak, nonatomic) IBOutlet UITableView            *tableView;
@property (weak, nonatomic) IBOutlet UIButton               *uploadAll;

@end

@implementation OSVLocalTracksViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.geocoder = [CLGeocoder new];
    self.reverseGeocodeQueue = [NSOperationQueue new];
    self.reverseGeocodeQueue.maxConcurrentOperationCount = 1;
    self.metricSystem = [[OSVUserDefaults sharedInstance].distanceUnitSystem isEqualToString:kMetricSystem];

    [self addRightNavigationItemWithText:NSLocalizedString(@"Upload ", @"") andCount:@"-"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[OSVSyncController sharedInstance].tracksController getLocalSequencesWithCompletion:^(NSArray<OSVSequence *> *sequences) {
            self.dataSource = [sequences mutableCopy];
        
            [self addRightNavigationItemWithText:NSLocalizedString(@"Upload ", @"") andCount:[@(self.dataSource.count) stringValue]];
            
            [self.tableView reloadData];
        }];
    });
    [self.uploadAll setTitle:NSLocalizedString(@"UPLOAD ALL", @"") forState:UIControlStateNormal];
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"uploadViewControllerSegueID"] && sender) {
        OSVUploadViewController *uVC = segue.destinationViewController;
        if ([sender boolValue]) {
            [uVC uploadSequences];
        }
    } else if ([segue.identifier isEqualToString:@"videoPlayerSegueID"] && sender) {
        OSVVideoPlayerViewController *videoPlayer = segue.destinationViewController;
        videoPlayer.selectedSequence = sender;
    }
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Private 

- (void)addRightNavigationItemWithText:(NSString *)text andCount:(NSString *)stringCount {
    CGRect rect = CGRectMake(0, 0, self.view.frame.size.width/2, 40);
    UILabel *label = [[UILabel alloc] initWithFrame:rect];
    label.textAlignment = NSTextAlignmentRight;
    label.attributedText = [NSAttributedString combineString:text withSize:22.f color:[UIColor hex1B1C1F] fontName:@"HelveticaNeue-Light"
                                                  withString:stringCount withSize:22.f color:[UIColor hexB7BAC5] fontName:@"HelveticaNeue-Light"];
    
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithCustomView:label]];
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    OSVSequence *sequence = self.dataSource[indexPath.row];
    [self performSegueWithIdentifier:@"videoPlayerSegueID" sender:sequence];
}

#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OSVLocalTrackCell *cell = [tableView dequeueReusableCellWithIdentifier:@"localTackCell"];
    
    OSVSequence *track = self.dataSource[indexPath.row];
    OSVPhoto    *photo = track.photos.firstObject;
    
    cell.locationLabel.text = [NSString stringWithFormat:@"%@", track.location];
    cell.photoCountLabel.attributedText = [NSAttributedString combineString:[@(track.photos.count) stringValue] withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"
                                                                 withString:@" IMG" withSize:12.f color:[UIColor colorWithHex:0xb7bac5] fontName:@"HelveticaNeue"];
    if ([[OSVUserDefaults sharedInstance].distanceUnitSystem isEqualToString:kMetricSystem]) {
        NSArray *metricArray = [OSVUtils metricDistanceArray:track.length];
        cell.distanceLabel.attributedText = [NSAttributedString combineString:metricArray[0] withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"
                                                                   withString:metricArray[1] withSize:12.f color:[UIColor colorWithHex:0xb7bac5] fontName:@"HelveticaNeue"];
    } else {
        NSArray *imperialArray = [OSVUtils imperialDistanceArray:track.length];
        cell.distanceLabel.attributedText = [NSAttributedString combineString:imperialArray[0] withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"
                                                                   withString:imperialArray[1] withSize:12.f color:[UIColor colorWithHex:0xb7bac5] fontName:@"HelveticaNeue"];
    }
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"MM.dd.YY "];
    NSString *dString = [formatter stringFromDate:track.dateAdded];
    [formatter setDateFormat:@"| hh:mm"];
    NSString *hString = [formatter stringFromDate:track.dateAdded];
    
    cell.dateLabel.attributedText = [NSAttributedString combineString:dString withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"
                                                           withString:hString withSize:12.f color:[UIColor colorWithHex:0xb7bac5] fontName:@"HelveticaNeue"];

    
    if ((!photo.photoData.addressName || [photo.photoData.addressName isEqualToString:@""])) {
        CLLocation *location = photo.photoData.location;
        
        cell.locationLabel.text = @"-";
        OSVAPISerialOperation *operation = [OSVAPISerialOperation new];
        typeof(operation) woperation = operation;
        
        operation.asyncTask = ^(OSVAPISerialOperation *op) {
            [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray* placemarks, NSError* error) {
                if ([placemarks count] > 0) {
                    CLPlacemark *placemark = placemarks[0];
                    NSArray *lines = placemark.addressDictionary[@"FormattedAddressLines"];
                    NSString *addressString = [lines componentsJoinedByString:@","];
                    photo.photoData.addressName = addressString;
                    if ([photo isKindOfClass:[OSVPhoto class]]) {
                        [OSVPersistentManager updatedPhoto:photo withAddress:addressString];
                    }
                    cell.locationLabel.text = addressString;
                }
                [woperation asyncTaskDone];
            }];
        };
        
        [self.reverseGeocodeQueue addOperation:operation];
    } else {
        cell.locationLabel.text = photo.photoData.addressName;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[OSVSyncController sharedInstance].tracksController deleteSequence:self.dataSource[indexPath.row] withCompletionBlock:^(NSError *error) {
            [self.dataSource removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self addRightNavigationItemWithText:NSLocalizedString(@"Upload ", @"") andCount:[@(self.dataSource.count) stringValue]];
            if (self.dataSource.count == 0) {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }];
    }
}

- (IBAction)didTapBackButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)didTapUploadLocalRecordings:(id)sender {
    [self presentUploadControllerAndStartUploading:YES withAllert:YES];
}

- (void)presentUploadControllerAndStartUploading:(BOOL)shouldUpload withAllert:(BOOL)whithAllert {
    if (![OSVSyncController hasSequencesToUpload]) {
        [OSVUserDefaults sharedInstance].isUploading = NO;
        if (whithAllert) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"", @"") message:NSLocalizedString(@"Looks like you don't have any recordings", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", @"") otherButtonTitles:nil] show];
        }
        return;
    }
    if (![OSVSyncUtils hasInternetPermissions]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"", @"") message:NSLocalizedString(@"Please connect to a Wi-Fi or allow uploading on cellular data from settings.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", @"") otherButtonTitles:nil] show];
    } else {
        BOOL reach = [OSVReachablityController checkReachablility];
        BOOL hasServerAccess = [[OSVSyncController sharedInstance].tracksController userIsLoggedIn];
        if (reach && hasServerAccess) {
            [self performSegueWithIdentifier:@"uploadViewControllerSegueID" sender:@(shouldUpload)];
        } else if (reach && !hasServerAccess) {
            [[OSVSyncController sharedInstance].tracksController loginWithCompletion:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self performSegueWithIdentifier:@"uploadViewControllerSegueID" sender:@(shouldUpload)];
                });
            }];
        }
    }
}

@end
