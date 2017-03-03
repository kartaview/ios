//
//  OSVLeaderboardViewController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 16/11/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVLeaderboardViewController.h"
#import "OSVSyncController.h"
#import "OSVUser.h"

#import "OSVRankHeaderCell.h"
#import "OSVRankCell.h"
#import "UIColor+OSVColor.h"
#import "OSVUtils.h"
#import "OSVUnderlineButton.h"

#import "OSVSyncController.h"

@interface OSVLeaderboardViewController ()

@property (strong, nonatomic) UIColor *previousBarTintColor;
@property (strong, nonatomic) UIImage *previousShadowImage;
@property (strong, nonatomic) UIImage *previousBackgroundImage;

@property (nonatomic, strong) NSArray<OSVUser *>    *datasource;
@property (weak, nonatomic) IBOutlet UITableView    *tableView;
@property (nonatomic, strong) NSArray<UIColor *>    *tableViewColors;

@property (weak, nonatomic) IBOutlet OSVUnderlineButton *usRegionButton;
@property (weak, nonatomic) IBOutlet OSVUnderlineButton *allWorldRegionButton;

@property (weak, nonatomic) IBOutlet UIButton           *leaderboardTitle;
@property (weak, nonatomic) IBOutlet UILabel            *timePeriodTitle;

@property (strong, nonatomic) NSArray<NSString *>       *timePeriods;
@property (assign, nonatomic) NSInteger                 timePeriodIndex;
@property (weak, nonatomic) IBOutlet UILabel            *allWorldNoLogin;

@property (strong, nonatomic) id<OSVUser>               currentUser;
@end

@implementation OSVLeaderboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableViewColors = @[[UIColor whiteColor], [UIColor colorWithHex:0xf8f8fa]];
    self.timePeriodIndex = 0;
    self.timePeriods = @[NSLocalizedString(@"All Time", @""),
                         NSLocalizedString(@"This Month", @""),
                         NSLocalizedString(@"This Week", @""),
                         NSLocalizedString(@"Today", @"")];
    self.timePeriodTitle.text = self.timePeriods[self.timePeriodIndex];

    
    self.allWorldRegionButton.backgroundColor = [UIColor colorWithHex:0x1daa63];
    self.allWorldRegionButton.selected = YES;
    self.currentUser = [OSVSyncController sharedInstance].tracksController.oscUser;
    
    self.usRegionButton.backgroundColor = [UIColor colorWithHex:0x1daa63];
    
    if (![OSVSyncController sharedInstance].tracksController.userIsLoggedIn) {
        self.allWorldRegionButton.selected = NO;
        self.allWorldRegionButton.userInteractionEnabled = NO;
        [self.allWorldRegionButton setTitle:@"" forState:UIControlStateNormal];
        
        self.usRegionButton.selected = NO;
        self.usRegionButton.userInteractionEnabled = NO;
        [self.usRegionButton setTitle:@"" forState:UIControlStateNormal];

        self.allWorldNoLogin.hidden = NO;
    }
    
    [self reloadGameLeaderboard];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
    self.previousBarTintColor = self.navigationController.navigationBar.barTintColor;
    self.previousShadowImage = self.navigationController.navigationBar.shadowImage;
    self.previousBackgroundImage = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithHex:0x1daa63];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];

    [self.leaderboardTitle setTitle:NSLocalizedString(@"Leaderboard", @"") forState:UIControlStateNormal];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.barTintColor = self.previousBarTintColor;
    self.navigationController.navigationBar.shadowImage = self.previousShadowImage;
    [self.navigationController.navigationBar setBackgroundImage:self.previousBackgroundImage forBarMetrics:UIBarMetricsDefault];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datasource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OSVRankCell *rankCell = [tableView dequeueReusableCellWithIdentifier:@"rankCell"];
    rankCell.rank.text = [@(indexPath.row + 1) stringValue];
    rankCell.name.text = self.datasource[indexPath.row].name;
    rankCell.points.text = [NSString stringWithFormat:@"%@", [OSVUtils pointsFormatedFromPoints:(NSInteger)self.datasource[indexPath.row].gameInfo.totalPoints]];
    
    BOOL isLoggedin = [self.currentUser.name isEqualToString:self.datasource[indexPath.row].name];
    if (isLoggedin) {
        rankCell.rank.textColor = [UIColor whiteColor];
        rankCell.name.textColor = [UIColor whiteColor];
        rankCell.points.textColor = [UIColor whiteColor];
        rankCell.backgroundColor = [UIColor colorWithHex:0x1daa63];
    } else {
        rankCell.rank.textColor = [UIColor blackColor];
        rankCell.name.textColor = [UIColor blackColor];
        rankCell.points.textColor = [UIColor blackColor];
        rankCell.backgroundColor = self.tableViewColors[indexPath.row % self.tableViewColors.count];
    }
    
    return rankCell;
}

#pragma mark - Actions

- (IBAction)didTapBackButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)didTapAllWorld:(UIButton *)sender {
    sender.selected = YES;
    self.usRegionButton.selected = NO;
    [self reloadGameLeaderboard];
}

- (IBAction)didTapUS:(UIButton *)sender {
    sender.selected = YES;
    self.allWorldRegionButton.selected = NO;
    [self reloadGameLeaderboard];
}

- (IBAction)didTapLeftTime:(id)sender {
    NSInteger prevValue = self.timePeriodIndex;
    
    self.timePeriodIndex = MAX(self.timePeriodIndex - 1, 0);
    self.timePeriodTitle.text = self.timePeriods[self.timePeriodIndex];
    
    if (prevValue != self.timePeriodIndex) {
        [self reloadGameLeaderboard];
    }
}

- (IBAction)didTapRightTime:(id)sender {
    NSInteger prevValue = self.timePeriodIndex;
    
    self.timePeriodIndex = MIN(self.timePeriodIndex + 1, self.timePeriods.count - 1);
    self.timePeriodTitle.text = self.timePeriods[self.timePeriodIndex];
    
    if (prevValue != self.timePeriodIndex) {
        [self reloadGameLeaderboard];
    }
}

#pragma mark - Private 

- (void)reloadGameLeaderboard {
    BOOL allWorldRegion = self.allWorldRegionButton.selected;
    NSString *region = nil;
    
    if (!allWorldRegion && self.currentUser.gameInfo) {
        region = self.currentUser.gameInfo.regionCode;
    }
    
    NSDate *date = nil;
    switch (self.timePeriodIndex) {
        case 1: {
            NSCalendar *cal = [NSCalendar currentCalendar];
            NSDate *now = [NSDate date];
            NSDate *startOfTheMonth;
            NSTimeInterval interval;
            [cal rangeOfUnit:NSCalendarUnitMonth
                   startDate:&startOfTheMonth
                    interval:&interval
                     forDate:now];
            date = startOfTheMonth;
            }
            break;
        case 2: {
            NSCalendar *cal = [NSCalendar currentCalendar];
            NSDate *now = [NSDate date];
            NSDate *startOfTheWeek;
            NSTimeInterval interval;
            [cal rangeOfUnit:NSCalendarUnitWeekOfMonth
                   startDate:&startOfTheWeek
                    interval:&interval 
                     forDate:now];
            date = startOfTheWeek;
            }
            break;
        case 3:
            date = [NSDate new];
            break;
        default:
            
            break;
    }
    
    self.datasource = [NSArray array];
    [self.tableView reloadData];
    
    [[OSVSyncController sharedInstance].tracksController gameLeaderBoardForRegion:region
                                                                         formDate:date
                                                                   withCompletion:^(NSArray<OSVUser> *leaderBoard, NSError *error) {
        self.datasource = leaderBoard;
        NSIndexPath *indexPath = nil;
        NSString *country = nil;
        if (self.currentUser.name) {
            int i = 0;
            for (OSVUser *user in leaderBoard) {
                if ([user.name isEqualToString:self.currentUser.name]) {
                    self.currentUser.gameInfo = user.gameInfo;
                    //the server is buggy we have to check this.
                    if (user.gameInfo.regionCode) {
                        NSString *identifier = [NSLocale localeIdentifierFromComponents:[NSDictionary dictionaryWithObject:user.gameInfo.regionCode forKey:NSLocaleCountryCode]];
                        country = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:identifier];
                        
                        indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                    }
                }
                i++;
            }
        }
                                                                       
        dispatch_async(dispatch_get_main_queue(), ^{
            if (country) {
                [self.usRegionButton setTitle:country forState:UIControlStateNormal];
            }
            
            [self.tableView reloadData];
            if (indexPath) {
                [self.tableView scrollToRowAtIndexPath:indexPath
                                      atScrollPosition:UITableViewScrollPositionMiddle
                                              animated:YES];
            }
        });
    }];
}

@end
