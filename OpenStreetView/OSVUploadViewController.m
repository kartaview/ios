//
//  OSVUploadViewController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 15/01/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVUploadViewController.h"
#import "KAProgressLabel.h"
#import "OSVSyncController.h"
#import "OSVUtils.h"
#import "UIColor+OSVColor.h"
#import "UIAlertView+Blocks.h"
#import "OSVUserDefaults.h"

#import <SKMaps/SKPositionerService.h>
#import "NSAttributedString+Additions.h"
#import "NSMutableAttributedString+Additions.h"
#import "UIColor+OSVColor.h"

@interface OSVUploadViewController ()

@property (weak, nonatomic) IBOutlet KAProgressLabel    *progressView;
@property (weak, nonatomic) IBOutlet UIButton           *stopButton;
@property (weak, nonatomic) IBOutlet UIButton           *pauseButton;

@property (assign, nonatomic) long long                 totalSize;

@property (strong, nonatomic) NSString                  *currentStatus;

@property (assign, nonatomic) NSInteger                 smallFontSize;
@property (assign, nonatomic) NSInteger                 bigFontSize;

@property (assign, nonatomic) double                    latestSpeed;
@property (assign, nonatomic) double                    latestProgress;
@property (assign, nonatomic) double                    latestTotalSize;
@property (strong, nonatomic) OSVMetadata               *latestMetadata;

@property (assign, nonatomic) BOOL                      isPaused;

@property (strong, nonatomic) UILabel                   *status;
@property (weak, nonatomic) IBOutlet UILabel            *time;
@property (weak, nonatomic) IBOutlet UILabel            *speed;


@end

@implementation OSVUploadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishUploadingAll:) name:kDidFinishUploadingAll object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishUploadingPhoto:) name:kDidFinishUploadingPhoto object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveProgress:) name:kDidReceiveProgress object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNewSpeed:) name:@"kDidChangeSpeed" object:nil];
    
    self.progressView.trackWidth = 6;
    self.progressView.borderWidth = 1;
    self.progressView.trackColor = [UIColor hex31333B];
    self.progressView.borderColor = [[UIColor hexBD10E0] colorWithAlphaComponent:0.5];
    self.progressView.progressWidth = self.progressView.trackWidth;
    self.progressView.progressColor = [UIColor hexBD10E0];
    self.progressView.startRoundedCornersWidth = self.progressView.trackWidth * 2;
    self.progressView.endRoundedCornersWidth = self.progressView.trackWidth * 4;
    self.progressView.startDegree = 0;
    self.progressView.endDegree = 0;
    
    [self.pauseButton setTitle:NSLocalizedString(@"Paused", @"") forState:UIControlStateNormal];
    [self.pauseButton setTitle:NSLocalizedString(@"Resume", @"") forState:UIControlStateSelected];
    [self.stopButton setTitle:NSLocalizedString(@"Stop", @"") forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.previousShadowImage = self.navigationController.navigationBar.shadowImage;
    self.previousBarTintColor = self.navigationController.navigationBar.barTintColor;
    self.previousBackgroundImage = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
    
    self.navigationController.navigationBar.barTintColor = [UIColor hex1B1C1F];
    self.navigationController.navigationBar.translucent = NO;
    
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;

    if ([CLLocationManager authorizationStatus] ==  kCLAuthorizationStatusAuthorizedWhenInUse) {
        [[SKPositionerService sharedInstance] cancelLocationUpdate];
    }
    if ([OSVSyncController sharedInstance].tracksController.isPaused) {
        self.isPaused = YES;
        [self resumeUploadSequences];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.barTintColor = self.previousBarTintColor;
    self.navigationController.navigationBar.shadowImage = self.previousShadowImage;
    [self.navigationController.navigationBar setBackgroundImage:self.previousBackgroundImage forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;

    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [[SKPositionerService sharedInstance] startLocationUpdate];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)addRightNavigationItemWithText:(NSString *)text andCount:(NSString *)stringCount {
    
    if (!self.status) {
        CGRect rect = CGRectMake(0, 0, self.view.frame.size.width/1.5, 40);
        self.status = [[UILabel alloc] initWithFrame:rect];
        self.status.textAlignment = NSTextAlignmentRight;
        self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithCustomView:self.status]];
    }
    
    self.status.attributedText = [NSAttributedString combineString:text withSize:22.f color:[UIColor hex6E707B] fontName:@"HelveticaNeue-Light"
                                                  withString:stringCount withSize:22.f color:[UIColor whiteColor] fontName:@"HelveticaNeue-Light"];
}

#pragma mark - Actions

- (IBAction)didTapPauseResumeButton:(UIButton *)sender {
    if (sender.selected) {
        [self resumeUploadSequences];
        sender.selected = NO;
    } else {
        [self pauseUploadSequences];
        sender.selected = YES;
    }
}

- (IBAction)didTapStopButton:(id)sender {
    [[OSVSyncController sharedInstance].tracksController cancelUpload];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)didTapBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Uploading notifications

- (void)didFinishUploadingAll:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    
    NSError *error = userInfo[@"error"];
    [self didFinishUploadingAllSequncesWitError:error];
}

- (void)didFinishUploadingPhoto:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    OSVMetadata *meta = userInfo[@"metadata"];
    
    [self didFinishUploadingPhotoWithMetadata:meta];
}

- (void)didReceiveProgress:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    
    self.latestProgress = [userInfo[@"progress"] doubleValue];
    self.latestTotalSize = [userInfo[@"totalSize"] doubleValue];
    self.latestMetadata = userInfo[@"metadata"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // UGLY DIRGTY QUICK FIX!!!!
        if (self.latestTotalSize < self.latestProgress) {
            return;
        }
        [self setProgressWithTotalSize:self.latestTotalSize currentProgress:self.latestProgress];
        [self updateCurrentSeqienceWithMetadata:self.latestMetadata];
    });
}

#pragma mark - Speed notifications

- (void)didReceiveNewSpeed:(NSNotification *)notificaiton {
    NSNumber *speed = notificaiton.userInfo[@"kLatestSpeed"];
    self.latestSpeed = [speed doubleValue];
    
    if (self.isPaused) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.time.text = @"-";
            self.speed.text = @"-";
        });
        return;
    }
    
    if (self.latestTotalSize < self.latestProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.speed.text = [self stringForSpeed:self.latestSpeed];
        });
        return;
    }
    
    double remaining = self.latestTotalSize - self.latestProgress;
    double estimateTime = NSNotFound;
    
    if (self.latestSpeed) {
        estimateTime = remaining / 1024 / self.latestSpeed;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.time.text = [self stringFormSeconds:estimateTime];
        self.speed.text = [self stringForSpeed:self.latestSpeed];
    });
}

#pragma mark - Private

- (void)uploadSequences {
    [[OSVSyncController sharedInstance].tracksController uploadAllSequencesWithCompletion:^(NSError *error) {
    } partialCompletion:^(OSVMetadata *metadata, NSError *error) {
    }];
}

- (void)resumeUploadSequences {
    self.isPaused = NO;
    [self addRightNavigationItemWithText:NSLocalizedString(@"Uploading track ", @"") andCount:@"-"];

    [[OSVSyncController sharedInstance].tracksController resumeUpload];
}

- (void)pauseUploadSequences {
    [self addRightNavigationItemWithText:NSLocalizedString(@"Pause", @"") andCount:@" "];
    self.isPaused = YES;
    [[OSVSyncController sharedInstance].tracksController pauseUpload];
}

- (void)didFinishUploadingPhotoWithMetadata:(OSVMetadata *)metadata {
    self.latestMetadata = metadata;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateCurrentSeqienceWithMetadata:metadata];
    });
}

- (void)updateCurrentSeqienceWithMetadata:(OSVMetadata *)metadata {
    if (self.latestMetadata && !self.latestMetadata.uploadingMetadata) {
        [self addRightNavigationItemWithText:NSLocalizedString(@"Uploading track ", @"") andCount:[NSString stringWithFormat:@"%ld/%ld", (long)self.latestMetadata.index, (long)self.latestMetadata.totalItems]];
    } else if(self.latestMetadata && self.latestMetadata.uploadingMetadata) {
        [self addRightNavigationItemWithText:NSLocalizedString(@"Uploading metadata", @"") andCount:@" "];
    }
}

- (void)didFinishUploadingAllSequncesWitError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.navigationController.viewControllers.firstObject.navigationController.navigationBar.barTintColor = self.previousBarTintColor;
        self.navigationController.viewControllers.firstObject.navigationController.navigationBar.shadowImage = self.previousShadowImage;
        [self.navigationController.viewControllers.firstObject.navigationController.navigationBar setBackgroundImage:self.previousBackgroundImage forBarMetrics:UIBarMetricsDefault];
        self.navigationController.viewControllers.firstObject.navigationController.navigationBar.barStyle = UIBarStyleDefault;
       [self.navigationController popToRootViewControllerAnimated:YES];
    });
}

- (void)setProgressWithTotalSize:(double)totalSize currentProgress:(double)currentProgress {
    NSMutableAttributedString *progressAttributedString;
    if (totalSize) {
        
        NSString *progString =[NSString stringWithFormat:@"%.0f%%", currentProgress/totalSize * 100];
        
        progressAttributedString = [NSMutableAttributedString mutableAttributedStringWithString:progString withSize:80 color:[UIColor whiteColor] fontName:@"HelveticaNeue-UltraLight"];
        NSString *cProgress = [NSString stringWithFormat:@"\n%@ ", [OSVUtils  memoryFormatter:currentProgress]];
        NSAttributedString *curentProgAttributed = [NSAttributedString attributedStringWithString:cProgress withSize:12.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"];
        
        NSString *tSize = [NSString stringWithFormat:@"| %@", [OSVUtils memoryFormatter:totalSize]];
        
        NSAttributedString *totalAttributed = [NSAttributedString attributedStringWithString:tSize withSize:12.f color:[UIColor hex6E707B] fontName:@"HelveticaNeue"];
        
        [progressAttributedString appendAttributedString:curentProgAttributed];
        [progressAttributedString appendAttributedString:totalAttributed];
        [self.progressView setProgress:(currentProgress/totalSize) timing:TPPropertyAnimationTimingLinear duration:1 delay:0];
    } else {
        NSString *progString =[NSString stringWithFormat:@"0%%"];

        progressAttributedString = [NSMutableAttributedString mutableAttributedStringWithString:progString withSize:80 color:[UIColor whiteColor] fontName:@"HelveticaNeue-UltraLight"];
        
        NSString *cProgress = [NSString stringWithFormat:@"\n%@ ", [OSVUtils  memoryFormatter:currentProgress]];
        NSAttributedString *curentProgAttributed = [NSAttributedString attributedStringWithString:cProgress withSize:12.f color:[UIColor whiteColor] fontName:@"HelveticaNeue"];

        NSString *tSize = [NSString stringWithFormat:@"| -"];
        NSAttributedString *totalAttributed = [NSAttributedString attributedStringWithString:tSize withSize:12.f color:[UIColor hex6E707B] fontName:@"HelveticaNeue"];
        
        [progressAttributedString appendAttributedString:curentProgAttributed];
        [progressAttributedString appendAttributedString:totalAttributed];
    }
    
    self.progressView.attributedText = progressAttributedString;
}

//Time
const int kTimeSecondsInMinute = 60;
const int kTimeSecondsInHour = 3600;
const int kTimeSecondsInDay = 86400;

- (NSString *)stringFormSeconds:(NSInteger)seconds {
    //Format the seconds to a nicer format.
    NSUInteger durationInSeconds = seconds;
    NSUInteger durationInHours = durationInSeconds / kTimeSecondsInHour;
    NSUInteger durationInRemainder = durationInSeconds % kTimeSecondsInHour;
    NSUInteger durationInMinutes = durationInRemainder / kTimeSecondsInMinute;
    durationInRemainder = durationInRemainder % kTimeSecondsInMinute;
    
    NSString *finalDurationString = @"";
    if (durationInSeconds > kTimeSecondsInDay*2) {
        //If more than a day , return infinite.
        finalDurationString = @"∞";
    } else {
        finalDurationString = [NSString stringWithFormat:@"%02lu:%02lu:%02lu", (unsigned long)durationInHours, (unsigned long)durationInMinutes, (unsigned long)durationInRemainder];
    }
   
    return finalDurationString;
}

- (NSString *)stringForSpeed:(float)speed {
    NSString *unitString = @"KB";
    if (speed >= 800) {
        speed /= 1024;
        unitString = @"MB";
    }
    
    return [NSString stringWithFormat:@"%.1f %@/s", speed, unitString];
}

@end
