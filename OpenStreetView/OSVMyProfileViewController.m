//
//  OSVMyProfileViewController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 06/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVMyProfileViewController.h"
#import "OSVVideoPlayerViewController.h"

#import "OSVSyncController.h"
#import "OSVServerSequence.h"

#import "UIColor+OSVColor.h"
#import "OSVMyTracksCell.h"
#import "OSVMyProfileCell.h"
#import "OSVTrackCell.h"
#import "OSVInfoCell.h"
#import "OSVUser.h"
#import "OSVUtils.h"
#import "OSVUserDefaults.h"
#import "UIAlertView+Blocks.h"

#import "NSAttributedString+Additions.h"

@interface  OSVMyProfileViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UIColor *previousBarTintColor;
@property (strong, nonatomic) UIImage *previousShadowImage;
@property (strong, nonatomic) UIImage *previousBackgroundImage;

@property (weak, nonatomic) IBOutlet UIButton                               *userName;
@property (strong, nonatomic) NSMutableArray<OSVServerSequence *>           *datasource;
@property (weak, nonatomic) IBOutlet UITableView                            *tableView;

@property (assign, nonatomic) NSInteger                                     currentPage;

@property (strong, nonatomic) id<OSVUser>                                   currentUser;
@property (assign, nonatomic) NSInteger                                     localRank;
@property (assign, nonatomic) NSInteger                                     totalNumberOfTracks;

@property (assign, nonatomic) BOOL                                          didShowNoInternet;

@end

@implementation OSVMyProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentPage = 0;
    self.datasource = [NSMutableArray arrayWithArray:@[@"", @"", @""]];
    [self loadCurrentPageShowReset:NO];
    [self.tableView setScrollEnabled:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.previousBarTintColor = self.navigationController.navigationBar.barTintColor;
    self.previousShadowImage = self.navigationController.navigationBar.shadowImage;
    self.previousBackgroundImage = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
    
    self.navigationController.navigationBar.barTintColor = [UIColor hex019ED3];
    self.navigationController.navigationBar.translucent = NO;
    
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Hey %@", @""), [OSVSyncController sharedInstance].tracksController.user.name];
    [self.userName setTitle:title forState:UIControlStateNormal];

    self.userName.frame = CGRectInset(self.userName.frame, -40, 0);
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor hex1B1C1F];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.barTintColor = self.previousBarTintColor;
    self.navigationController.navigationBar.shadowImage = self.previousShadowImage;
    [self.navigationController.navigationBar setBackgroundImage:self.previousBackgroundImage forBarMetrics:UIBarMetricsDefault];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showPlayer"]) {
        NSIndexPath *indexPath = sender;
        OSVVideoPlayerViewController *vc = segue.destinationViewController;
        vc.selectedSequence = self.datasource[indexPath.row];
    }
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
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
    UITableViewCell *cell;
    
    if (indexPath.row == 0) {
        OSVMyProfileCell *mycell = [tableView dequeueReusableCellWithIdentifier:@"topCell"];
        
        mycell.globalRankTitle.text = NSLocalizedString(@"Overall ranking", @"");
        mycell.localRankTitle.text = NSLocalizedString(@"This week", @"");
        
        if (self.currentUser) {
            if (self.currentUser.rank) {
                mycell.globalRank.text = [@(self.currentUser.rank) stringValue];
            } else {
                mycell.globalRank.text = @"-";
            }
            
            if (self.currentUser.weekRank) {
                mycell.localRank.text = [@(self.currentUser.weekRank) stringValue];
            } else {
                mycell.localRank.text = @"-";
            }
        } else {
            mycell.globalRank.text = @"-";
            mycell.localRank.text = @"-";
            [[OSVSyncController sharedInstance].tracksController osvUserInfoWithCompletion:^(id<OSVUser> user, NSError *error) {
                if (!error) {
                    self.currentUser = user;
                    [tableView reloadData];
                }
            }];
        }
        
        cell = mycell;
    } else if (indexPath.row == 1) {
        OSVInfoCell *infoCell = [tableView dequeueReusableCellWithIdentifier:@"midCell"];
        if ([[OSVUserDefaults sharedInstance].distanceUnitSystem isEqualToString:kMetricSystem]) {
            NSString *metricArray = [OSVUtils metricDistanceFormatter:self.currentUser.totalKM * 1000];
            infoCell.distanceInfo.attributedText = [NSAttributedString combineString:@"Distance: " withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"
                                                                            withString:metricArray withSize:12.f color:[UIColor colorWithHex:0x1b1c1f] fontName:@"HelveticaNeue"];
        } else {
            NSString *imperialArray = [OSVUtils imperialDistanceFormatter:self.currentUser.totalKM * 1000];
            infoCell.distanceInfo.attributedText = [NSAttributedString combineString:@"Distance: " withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"
                                                                            withString:imperialArray withSize:12.f color:[UIColor colorWithHex:0x1b1c1f] fontName:@"HelveticaNeue"];
        }
        infoCell.tracksInfo.attributedText = [NSAttributedString combineString:@"Tracks: " withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"
                                                          withString:[@(self.totalNumberOfTracks) stringValue] withSize:12.f color:[UIColor colorWithHex:0x1b1c1f] fontName:@"HelveticaNeue"];
        
        if ([[OSVUserDefaults sharedInstance].distanceUnitSystem isEqualToString:kMetricSystem]) {
            NSString *metricArray = [OSVUtils metricDistanceFormatter:self.currentUser.obdDistance * 1000];
            infoCell.OBDInfo.attributedText = [NSAttributedString combineString:@"OBD: " withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"
                                                                     withString:metricArray withSize:12.f color:[UIColor colorWithHex:0x1b1c1f] fontName:@"HelveticaNeue"];

        } else {
            NSString *imperialArray = [OSVUtils imperialDistanceFormatter:self.currentUser.obdDistance * 1000];
            infoCell.OBDInfo.attributedText = [NSAttributedString combineString:@"OBD: " withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"
                                                                     withString:imperialArray withSize:12.f color:[UIColor colorWithHex:0x1b1c1f] fontName:@"HelveticaNeue"];

        }
        
        NSString *imagesString = [NSString stringWithFormat:@"%ld", (long)self.currentUser.totalPhotos];
        infoCell.imagesInfo.attributedText = [NSAttributedString combineString:@"Images: " withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"
                                                                    withString:imagesString withSize:12.f color:[UIColor colorWithHex:0x1b1c1f] fontName:@"HelveticaNeue"];

        cell = infoCell;
        
    } else if (indexPath.row == 2) {
        OSVMyTracksCell *titleCell = [tableView dequeueReusableCellWithIdentifier:@"titleCell"];
        
        cell = titleCell;
    } else {
    
        OSVServerSequence *track = self.datasource[indexPath.row];

        OSVTrackCell *trackCell = [tableView dequeueReusableCellWithIdentifier:@"trackCell"];
        [[OSVSyncController sharedInstance].tracksController loadPreviewForTrack:track intoImageView:trackCell.previewImage withCompletion:^(UIImage *image, NSError *error) {
        }];
        trackCell.locationLabel.text = [NSString stringWithFormat:@"%@", track.location];
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
        
        cell = trackCell;
    }

    if (indexPath.row > self.datasource.count - 2) {
        self.currentPage++;
        [self loadCurrentPageShowReset:NO];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > 2) {
        [self performSegueWithIdentifier:@"showPlayer" sender:indexPath];
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return 156;
    } else if (indexPath.row == 1) {
        return 90;
    } else if (indexPath.row == 2) {
        return 60;
    } else {
        return (tableView.frame.size.width - 24) * 3/4 + 80 ;
    }
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y < 0) {
        self.tableView.backgroundColor = [UIColor hex019ED3];
    } else {
        self.tableView.backgroundColor = [UIColor hex1B1C1F];
    }
}

#pragma mark - Private 

- (void)loadCurrentPageShowReset:(BOOL)reset {
    [[OSVSyncController sharedInstance].tracksController getMyServerSequencesAtPage:self.currentPage withCompletion:^(NSArray<OSVServerSequence *> *tracks, OSVMetadata *metadata, NSError *error) {
        
        if (error && !self.didShowNoInternet) {
            self.didShowNoInternet = YES;
            [UIAlertView showWithTitle:NSLocalizedString(@"No internet connection", @"") message:NSLocalizedString(@"", @"") cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                [self.navigationController popViewControllerAnimated:YES];
            }];
        }
        
        if (reset) {
            self.datasource = [NSMutableArray arrayWithArray:tracks];
        } else {
            [self.datasource addObjectsFromArray:tracks];
        }
        
        if (tracks.count) {
            [self.tableView setScrollEnabled:YES];
        }
        
        self.totalNumberOfTracks = metadata.totalItems;
        if (metadata.totalItems >= self.datasource.count) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    }];
}


@end
