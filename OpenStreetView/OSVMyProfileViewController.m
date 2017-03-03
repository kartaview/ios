//
//  OSVMyProfileViewController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 06/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVMyProfileViewController.h"
#import "OSVVideoPlayerViewController.h"

#import "OSVPopTransition.h"

#import "OSVSyncController.h"
#import "OSVServerSequence.h"

#import "UIColor+OSVColor.h"
#import "OSVMyTracksCell.h"
#import "OSVGamificationProfileCell.h"
#import "OSVTrackCell.h"
#import "OSVInfoCell.h"
#import "OSVUser.h"
#import "OSVUtils.h"
#import "OSVUserDefaults.h"
#import "UIAlertView+Blocks.h"

#import "NSAttributedString+Additions.h"

#define kFirstCellHeight  250
#define kSecondCellHeight 90
#define kThirdCellHeight  60

@interface  OSVMyProfileViewController () <UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate>

@property (strong, nonatomic) UIColor *previousBarTintColor;
@property (strong, nonatomic) UIImage *previousShadowImage;
@property (strong, nonatomic) UIImage *previousBackgroundImage;

@property (weak, nonatomic) IBOutlet UIButton                               *userName;
@property (strong, nonatomic) NSMutableArray<OSVServerSequence *>           *datasource;
@property (weak, nonatomic) IBOutlet UITableView                            *tableView;

@property (assign, nonatomic) NSInteger                                     currentPage;

@property (strong, nonatomic) id<OSVUser>                                   currentUser;
@property (assign, nonatomic) NSInteger                                     localRank;

@property (assign, nonatomic) BOOL                                          didShowNoInternet;

@property (assign, nonatomic) BOOL                                          useGamification;

@end

@implementation OSVMyProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentPage = 0;
    if ([OSVUserDefaults sharedInstance].useGamification) {
        self.datasource = [NSMutableArray arrayWithArray:@[@"", @"", @""]];
    } else {
        self.datasource = [NSMutableArray arrayWithArray:@[@"", @""]];
    }
    
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
    self.navigationController.delegate = self;

    self.navigationController.navigationBar.shadowImage = [UIImage new];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
	
	
	if (self.currentUser.fullName) {
		NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Hey %@", @""), self.currentUser.fullName];
		[self.userName setTitle:title forState:UIControlStateNormal];
	} else {
		NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Hey -", @"")];
		[self.userName setTitle:title forState:UIControlStateNormal];
	}
	    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor hex1B1C1F];
    
    self.useGamification = [OSVUserDefaults sharedInstance].useGamification;
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
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datasource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    BOOL isGamificationON = [OSVUserDefaults sharedInstance].useGamification;
    
    if (isGamificationON && indexPath.row == 0) {
        cell = [self configureGamificationInfoCell:indexPath];
        
    } else if ((isGamificationON && indexPath.row == 1) ||
               (!isGamificationON && indexPath.row == 0)) {
        cell = [self configureUserInfoCell:indexPath];
        
    } else if ((isGamificationON && indexPath.row == 2) ||
               (!isGamificationON && indexPath.row == 1)) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"titleCell"];
        
    } else {
    
        OSVServerSequence *track = self.datasource[indexPath.row];

        OSVTrackCell *trackCell = [tableView dequeueReusableCellWithIdentifier:@"trackCell"];
        [[OSVSyncController sharedInstance].tracksController loadPreviewForTrack:track
																   intoImageView:trackCell.previewImage
																  withCompletion:^(UIImage *image, NSError *error) {
            float x = image.size.height / image.size.width;
            if (fabs(x - 4.0/3.0) > 0.1 && fabs(x - 3.0/4.0) > 0.1) {
                trackCell.previewImage.contentMode = UIViewContentModeScaleAspectFill;
            } else {
                trackCell.previewImage.contentMode = UIViewContentModeScaleAspectFit;
            }
        }];
        
        if (!track.location ||
            ![track.location isKindOfClass:[NSString class]] ||
            [track.location isEqualToString:@""]) {
            trackCell.locationLabel.text = @"-";
        } else {
            NSArray *array = [track.location componentsSeparatedByString:@","];
            NSString *street;
            NSString *broadLocation;
            
            if (array.count) {
                street = array[0];
                broadLocation = [track.location stringByReplacingOccurrencesOfString:street withString:@""];
                trackCell.locationLabel.attributedText = [NSAttributedString combineString:street
                                                     withSize:12.f
                                                        color:[UIColor whiteColor]
                                                     fontName:@"HelveticaNeue"
                                                   withString:broadLocation withSize:12.f
                                                        color:[UIColor colorWithHex:0x6e707b]
                                                     fontName:@"HelveticaNeue"];

            } else {
                trackCell.locationLabel.text = [NSString stringWithFormat:@"%@", track.location];
            }
        }
        
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
        
        NSString *pointsString = [@(track.points) stringValue];
        if (track.points > 9999) {
            pointsString = [NSString  stringWithFormat:@"%ldK", track.points/1000];
        }
        
        NSRange range = NSMakeRange(0, [pointsString length]);
        NSMutableAttributedString *attSpace = [[NSMutableAttributedString alloc] initWithString:pointsString];
        [attSpace addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:range];
        [attSpace addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue" size:16.f] range:range];
        
        range = NSMakeRange(0, [@"\n" length]);
        NSMutableAttributedString *att1 = [[NSMutableAttributedString alloc] initWithString:@"\n"];
        [att1 addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:range];
        [att1 addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue" size:1.f] range:range];
        
        NSString *ptsString = NSLocalizedString(@"pts", @"");
        range = NSMakeRange(0, [ptsString length]);
        NSMutableAttributedString *att2 = [[NSMutableAttributedString alloc] initWithString:ptsString];
        [att2 addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:range];
        [att2 addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue" size:10.f] range:range];
        
        [attSpace appendAttributedString:att1];
        [attSpace appendAttributedString:att2];
        
        trackCell.pointsLabel.attributedText = attSpace;
        trackCell.pointsLabel.hidden = !self.useGamification;
        trackCell.pointsImage.hidden = !self.useGamification;
        
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
    if ((indexPath.row > 2 && self.useGamification)||
        (!self.useGamification && indexPath.row > 1)) {
        [self performSegueWithIdentifier:@"showPlayer" sender:indexPath];
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isGamificationON = self.useGamification;

    if (isGamificationON && indexPath.row == 0) {
        return kFirstCellHeight;
    } else if ((isGamificationON && indexPath.row == 1) ||
               (!isGamificationON && indexPath.row == 0)) {
        return kSecondCellHeight;
    } else if ((isGamificationON && indexPath.row == 2) ||
              (!isGamificationON && indexPath.row == 1)) {
        return kThirdCellHeight;
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
    
    if (!self.tableView.visibleCells.count) {
        return;
    }
    
    BOOL isGamificationON = self.useGamification;
    
    if (isGamificationON && scrollView.contentOffset.y < 10) {
        OSVGamificationProfileCell *cell = self.tableView.visibleCells[0];
        cell.rankLabel.alpha = 1;
        cell.rankLabel.superview.alpha = 1;
        cell.rankTextLabel.alpha = 1;
        cell.scoreTextLabel.alpha = 1;
        cell.scoreLabel.alpha = 1;
        cell.progressView.alpha = 1;
        cell.progressLabel.alpha = 1;
        cell.nextLevelPoints.alpha = 1;
        
        float rawr = self.tableView.contentOffset.y;
        cell.frame = CGRectMake(cell.frame.origin.x, rawr, cell.frame.size.width, kFirstCellHeight-rawr);
        float scale = 1.0f + fabs(scrollView.contentOffset.y) / scrollView.frame.size.width;
        
        //Cap the scaling between zero and 1
        scale = MAX(0.0f, scale * scale);

        cell.progressLabel.transform = CGAffineTransformMakeScale(scale, scale);
        
    } else if ((!isGamificationON && scrollView.contentOffset.y < 10) ||
               (isGamificationON && scrollView.contentOffset.y < kFirstCellHeight)) {
        
        OSVInfoCell *infoCell;
        if (isGamificationON) {
            OSVGamificationProfileCell *cell = self.tableView.visibleCells[0];
            float ratio = scrollView.contentOffset.y/(kFirstCellHeight/1.8);
            cell.rankLabel.alpha = 0.8 - ratio;
            cell.rankLabel.superview.alpha = 0.8 - ratio;
            cell.rankTextLabel.alpha = 0.8 - ratio;
            cell.scoreTextLabel.alpha = 0.8 - ratio;
            cell.scoreLabel.alpha = 0.8 - ratio;
            cell.progressView.alpha = 0.8 - ratio;
            cell.progressLabel.alpha = 0.8 - ratio;
            cell.nextLevelPoints.alpha = 0.8 - ratio;
            
            infoCell = self.tableView.visibleCells[1];
            float rawr = self.tableView.contentOffset.y;
            cell.frame = CGRectMake(cell.frame.origin.x, rawr, cell.frame.size.width, kFirstCellHeight-rawr);
            
            float scale = 1.0f + fabs(scrollView.contentOffset.y) / scrollView.frame.size.width;
            
            //Cap the scaling between zero and 1
            scale = MAX(0.0f, 1.0 / (scale * scale));
            
            cell.progressLabel.transform = CGAffineTransformMakeScale(scale, scale);
        } else {
            infoCell = self.tableView.visibleCells[0];
        }
        
        infoCell.distanceInfo.alpha = 1;
        infoCell.tracksInfo.alpha = 1;
        infoCell.OBDInfo.alpha = 1;
        infoCell.imagesInfo.alpha = 1;
        
    } else if (((isGamificationON && scrollView.contentOffset.y < kFirstCellHeight + kSecondCellHeight)||
               (!isGamificationON && scrollView.contentOffset.y < kFirstCellHeight) )
               && [self.tableView.visibleCells[0] isKindOfClass:[OSVInfoCell class]]) {
        
        OSVInfoCell *infoCell = self.tableView.visibleCells[0];
        infoCell.distanceInfo.alpha = 0.9 - (scrollView.contentOffset.y - infoCell.frame.origin.y)/46;
        infoCell.tracksInfo.alpha = 0.9 - (scrollView.contentOffset.y - infoCell.frame.origin.y)/46;
        infoCell.OBDInfo.alpha = 0.9 - (scrollView.contentOffset.y - infoCell.frame.origin.y)/46;
        infoCell.imagesInfo.alpha = 0.9 - (scrollView.contentOffset.y - infoCell.frame.origin.y)/46;
    }
}

#pragma mark - Private 

- (void)loadCurrentPageShowReset:(BOOL)reset {
    [[OSVSyncController sharedInstance].tracksController getMyServerSequencesAtPage:self.currentPage
																	 withCompletion:^(NSArray<OSVServerSequence *> *tracks, OSVMetadata *metadata, NSError *error) {
        
        if (error && !self.didShowNoInternet) {
            self.didShowNoInternet = YES;
            [UIAlertView showWithTitle:NSLocalizedString(@"No internet connection", @"") message:NSLocalizedString(@"", @"") cancelButtonTitle:NSLocalizedString(@"Ok", @"") otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                [self.navigationController popViewControllerAnimated:YES];
            }];
        }
        
        if (reset) {
            NSMutableArray *mutableArray;
            if (self.useGamification) {
                mutableArray = [@[@"", @"", @""] mutableCopy];
            } else {
                mutableArray = [@[@"", @""] mutableCopy];
            }
            
            [mutableArray addObjectsFromArray:tracks];
            
            self.datasource = mutableArray;
        } else {
            [self.datasource addObjectsFromArray:tracks];
        }
        
        if (tracks.count) {
            [self.tableView setScrollEnabled:YES];
        }
        
        if (metadata.totalItems >= self.datasource.count) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    }];
}

#pragma mark - Navigation Controler Delegate

- (nullable id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                            animationControllerForOperation:(UINavigationControllerOperation)operation
                                                         fromViewController:(UIViewController *)fromVC
                                                           toViewController:(UIViewController *)toVC {
    if ([toVC isKindOfClass:NSClassFromString(@"OSVMapViewController")]) {
        return [[OSVPopTransition alloc] initWithoutAnimatingSource:YES];
    }
    
    return nil;
}

#pragma mark - TableView Cell Creation

- (UITableViewCell *)configureGamificationInfoCell:(NSIndexPath *)indexPath {
    OSVGamificationProfileCell *mycell = [self.tableView dequeueReusableCellWithIdentifier:@"topGameCell"];
    
    mycell.rankTextLabel.text = NSLocalizedString(@"Rank", @"");
    mycell.scoreTextLabel.text = NSLocalizedString(@"Score", @"");
    
    mycell.rankLabel.text = @"-";
    mycell.didTapRank = ^(id view) {
        [self performSegueWithIdentifier:@"showLeaderboardRank" sender:self];
    };
    
    NSInteger levelProgress = self.currentUser.gameInfo.levelPoints;
    NSInteger levelTotalPoints = self.currentUser.gameInfo.totalLevelPoints;
    NSInteger userTotalPoints = self.currentUser.gameInfo.totalPoints;
    NSInteger currentLevelDiference = levelTotalPoints - (userTotalPoints - levelProgress);
    if (levelProgress && levelTotalPoints) {
        [mycell.progressView setProgress:((double)levelProgress)/((double)currentLevelDiference)
                                  timing:TPPropertyAnimationTimingEaseOut
                                duration:1
                                   delay:0];
        mycell.nextLevelPoints.text = [NSString stringWithFormat:@"%@ points to next level", [OSVUtils pointsFormatedFromPoints:levelTotalPoints - userTotalPoints]];
    } else {
        mycell.nextLevelPoints.text = [NSString stringWithFormat:@"- points to next level"];
    }
    
    if (userTotalPoints) {
        mycell.scoreLabel.text = [OSVUtils pointsFormatedFromPoints:userTotalPoints];
    }
    
    NSString *levelTitle = NSLocalizedString(@"LEVEL\n", @"");
    NSString *level = self.currentUser.gameInfo.level ? [NSString stringWithFormat:@"%ld", self.currentUser.gameInfo.level] : @"-";
    NSAttributedString *progress = [NSAttributedString combineString:levelTitle
                                                            withSize:12.f
                                                               color:[UIColor whiteColor]
                                                            fontName:@"HelveticaNeue"
                                                          withString:level
                                                            withSize:60.f
                                                               color:[UIColor whiteColor]
                                                            fontName:@"HelveticaNeue"];
    mycell.progressLabel.attributedText = progress;
    
    if (self.currentUser) {
        if (self.currentUser.rank) {
            mycell.rankLabel.text = [@(self.currentUser.gameInfo.rank) stringValue];
        }
    } else {
        [[OSVSyncController sharedInstance].tracksController osvUserInfoWithCompletion:^(id<OSVUser> user, NSError *error) {
            if (!error) {
                self.currentUser = user;
				NSString *name = self.currentUser.fullName;
				if (!name) {
					name = self.currentUser.name;
				}
				
				NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Hey %@", @""), name];
				[self.userName setTitle:title forState:UIControlStateNormal];
                [self.tableView reloadData];
            }
        }];
    }
    mycell.progressView.progressColor = [UIColor whiteColor];
    
    return mycell;
}

- (UITableViewCell *)configureUserInfoCell:(NSIndexPath *)indexPath {
    OSVInfoCell *infoCell = [self.tableView dequeueReusableCellWithIdentifier:@"midCell"];
    if ([[OSVUserDefaults sharedInstance].distanceUnitSystem isEqualToString:kMetricSystem]) {
        NSString *metricArray = [OSVUtils metricDistanceFormatter:self.currentUser.totalKM * 1000];
        infoCell.distanceInfo.attributedText = [NSAttributedString combineString:@"Distance: " withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"
                                                                      withString:metricArray withSize:16.f color:[UIColor colorWithHex:0x1b1c1f] fontName:@"HelveticaNeue"];
    } else {
        NSString *imperialArray = [OSVUtils imperialDistanceFormatter:self.currentUser.totalKM * 1000];
        infoCell.distanceInfo.attributedText = [NSAttributedString combineString:@"Distance: " withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"
                                                                      withString:imperialArray withSize:16.f color:[UIColor colorWithHex:0x1b1c1f] fontName:@"HelveticaNeue"];
    }
    infoCell.tracksInfo.attributedText = [NSAttributedString combineString:@"Tracks: " withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"
                                                                withString:[@(self.currentUser.totalTracks) stringValue] withSize:16.f color:[UIColor colorWithHex:0x1b1c1f] fontName:@"HelveticaNeue"];
    
    if ([[OSVUserDefaults sharedInstance].distanceUnitSystem isEqualToString:kMetricSystem]) {
        NSString *metricArray = [OSVUtils metricDistanceFormatter:self.currentUser.obdDistance * 1000];
        infoCell.OBDInfo.attributedText = [NSAttributedString combineString:@"OBD: " withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"
                                                                 withString:metricArray withSize:16.f color:[UIColor colorWithHex:0x1b1c1f] fontName:@"HelveticaNeue"];
        
    } else {
        NSString *imperialArray = [OSVUtils imperialDistanceFormatter:self.currentUser.obdDistance * 1000];
        infoCell.OBDInfo.attributedText = [NSAttributedString combineString:@"OBD: " withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"
                                                                 withString:imperialArray withSize:16.f color:[UIColor colorWithHex:0x1b1c1f] fontName:@"HelveticaNeue"];
        
    }
    
    NSString *imagesString = [NSString stringWithFormat:@"%ld", (long)self.currentUser.totalPhotos];
    infoCell.imagesInfo.attributedText = [NSAttributedString combineString:@"Images: " withSize:12.f color:[UIColor colorWithHex:0x6e707b] fontName:@"HelveticaNeue"
                                                                withString:imagesString withSize:16.f color:[UIColor colorWithHex:0x1b1c1f] fontName:@"HelveticaNeue"];
    
    return infoCell;
}

#undef kFirstCellHeight
#undef kSecondCellHeight
#undef kThirdCellHeight

@end
