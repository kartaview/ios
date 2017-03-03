//
//  OSVDebugViewController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVDebugViewController.h"

#import "OSVUserDefaults.h"
#import "OSVLocationManager.h"
#import <Crashlytics/Crashlytics.h>
#import <AVFoundation/AVFoundation.h>

#import "OSVSequence.h"
#import "OSVPersistentManager.h"
#import "OSVUtils.h"
#import "OSVAPIConfigurator.h"

@interface OSVDebugViewController ()

@property (weak, nonatomic) IBOutlet UILabel            *revisionNumber;
@property (weak, nonatomic) IBOutlet UISwitch           *positionerSwitch;
@property (weak, nonatomic) IBOutlet UIButton           *simulatorButton;
@property (weak, nonatomic) IBOutlet UISwitch           *highDensity;

@property (weak, nonatomic) IBOutlet UIButton           *testEnvironment;
@property (weak, nonatomic) IBOutlet UIButton           *stagingEnvironment;
@property (weak, nonatomic) IBOutlet UIButton           *productionEnvironment;

@property (weak, nonatomic) IBOutlet UISwitch           *hdrSwitch;
@property (weak, nonatomic) IBOutlet UISwitch           *debugLogsOBD;
@property (weak, nonatomic) IBOutlet UISwitch           *debugSLUS;

@property (weak, nonatomic) IBOutlet UITextField        *frameRate;
@property (weak, nonatomic) IBOutlet UITextField        *frameMaxDimension;
@property (weak, nonatomic) IBOutlet UILabel            *frameMaxDimensionLabel;
@property (weak, nonatomic) IBOutlet UILabel            *frameRateLabel;
@property (weak, nonatomic) IBOutlet UILabel            *hqLabel;
@property (weak, nonatomic) IBOutlet UILabel            *bitrateLabel;

@property (weak, nonatomic) IBOutlet UIButton *encodingMediumQ;
@property (weak, nonatomic) IBOutlet UIButton *encodingLowQ;
@property (weak, nonatomic) IBOutlet UIButton *encodingHighQ;
@property (weak, nonatomic) IBOutlet UISwitch *stabilization;
@property (weak, nonatomic) IBOutlet UISwitch *matcherRedering;

@property (weak, nonatomic) IBOutlet UIButton *redGPS;
@property (weak, nonatomic) IBOutlet UIButton *yellowGPS;
@property (weak, nonatomic) IBOutlet UIButton *greenGPS;
@property (weak, nonatomic) IBOutlet UIButton *nonDebugGPS;

@end

@implementation OSVDebugViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //this file is created with a run script and it represents the svn version of the app
    NSString *path = [[NSBundle mainBundle] pathForResource:@"revision" ofType:@"osv"];
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    
    self.revisionNumber.text = [NSString stringWithFormat:@"Revision %@", content];
    self.simulatorButton.hidden = [OSVUserDefaults sharedInstance].realPositions;
    
    self.testEnvironment.selected = [[OSVUserDefaults sharedInstance].environment isEqualToString:[OSVAPIConfigurator testingEnvironment]];
    self.stagingEnvironment.selected = [[OSVUserDefaults sharedInstance].environment isEqualToString:[OSVAPIConfigurator stagingEnvironment]];
    self.productionEnvironment.selected = [[OSVUserDefaults sharedInstance].environment isEqualToString:[OSVAPIConfigurator productionEnvironment]];
    
    self.encodingLowQ.selected = [[OSVUserDefaults sharedInstance].debugEncoding isEqualToString:AVVideoProfileLevelH264BaselineAutoLevel];
    self.encodingHighQ.selected = [[OSVUserDefaults sharedInstance].debugEncoding isEqualToString:AVVideoProfileLevelH264HighAutoLevel];
    self.encodingMediumQ.selected = [[OSVUserDefaults sharedInstance].debugEncoding isEqualToString:AVVideoProfileLevelH264MainAutoLevel];
    
    self.nonDebugGPS.selected = [OSVUserDefaults sharedInstance].debugLocationAccuracy == 0;
    self.greenGPS.selected = [OSVUserDefaults sharedInstance].debugLocationAccuracy == 1;
    self.yellowGPS.selected = [OSVUserDefaults sharedInstance].debugLocationAccuracy == 2;
    self.redGPS.selected = [OSVUserDefaults sharedInstance].debugLocationAccuracy == 3;
    
    [self.hdrSwitch setOn:[OSVUserDefaults sharedInstance].hdrOption animated:NO];
    
    [self.debugLogsOBD setOn:[OSVUserDefaults sharedInstance].debugLogOBD animated:NO];
    [self.debugSLUS setOn:[OSVUserDefaults sharedInstance].debugSLUS animated:NO];
    
    [self.stabilization setOn:[OSVUserDefaults sharedInstance].debugStabilization animated:NO];

    [self.matcherRedering setOn:[OSVUserDefaults sharedInstance].debugMatcher animated:NO];
    
    double value = [OSVUserDefaults sharedInstance].debugFrameRate;
    self.frameRateLabel.text = [NSString stringWithFormat:@"%.f frames/sec when possible", value];
    value = [OSVUserDefaults sharedInstance].debugFrameSize;
    self.frameMaxDimensionLabel.text = [NSString stringWithFormat:@"%.f w x %.f h (landscape)\n %.f w x %.f h (portrait)", value, floorf(value/1.33), floorf(value/1.33), value];
    
    if ([OSVUserDefaults sharedInstance].debugHighDesintyOn) {
        self.hqLabel.text = @"HighDensity ON";
        [self.highDensity setOn:YES];
    } else {
        self.hqLabel.text = @"HighDensity OFF";
        [self.highDensity setOn:NO];
    }
    
    value = [OSVUserDefaults sharedInstance].debugBitRate;
    self.bitrateLabel.text = [NSString stringWithFormat:@"%.1f Mb bitrate", value];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.positionerSwitch setOn:[OSVUserDefaults sharedInstance].realPositions animated:NO];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - UI Actions

- (IBAction)didTouchConnectToSimulator:(id)sender {

}

- (IBAction)didChangePositionerType:(UISwitch *)sender {
    [OSVUserDefaults sharedInstance].realPositions = sender.on;
    [OSVLocationManager sharedInstance].realPositions = sender.on;
    [[OSVUserDefaults sharedInstance] save];
    self.simulatorButton.hidden = [OSVUserDefaults sharedInstance].realPositions;
}

- (IBAction)didPressCloseButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didPressDissmiss {
    [self.presentedViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (IBAction)didTouchEnvironmentButton:(UIButton *)sender {
    sender.selected = YES;

    if (sender == self.testEnvironment) {
        self.stagingEnvironment.selected = NO;
        self.productionEnvironment.selected = NO;
        [OSVUserDefaults sharedInstance].environment = [OSVAPIConfigurator testingEnvironment];
    } else if (sender == self.stagingEnvironment) {
        self.testEnvironment.selected = NO;
        self.productionEnvironment.selected = NO;
        [OSVUserDefaults sharedInstance].environment = [OSVAPIConfigurator stagingEnvironment];
    } else if (sender == self.productionEnvironment) {
        self.testEnvironment.selected = NO;
        self.stagingEnvironment.selected = NO;
        [OSVUserDefaults sharedInstance].environment = [OSVAPIConfigurator productionEnvironment];
    }
	
	[[OSVUserDefaults sharedInstance] save];
}

- (IBAction)didTouchEncodingButton:(UIButton *)sender {
    sender.selected = YES;
    
    if (sender == self.encodingHighQ) {
        self.encodingMediumQ.selected = NO;
        self.encodingLowQ.selected = NO;
        [OSVUserDefaults sharedInstance].debugEncoding = AVVideoProfileLevelH264HighAutoLevel;
    } else if (sender == self.encodingLowQ){
        self.encodingMediumQ.selected = NO;
        self.encodingHighQ.selected = NO;
        [OSVUserDefaults sharedInstance].debugEncoding = AVVideoProfileLevelH264BaselineAutoLevel;
    } else if (sender == self.encodingMediumQ){
        self.encodingHighQ.selected = NO;
        self.encodingLowQ.selected = NO;
        [OSVUserDefaults sharedInstance].debugEncoding = AVVideoProfileLevelH264MainAutoLevel;
    }
}

- (IBAction)didTouchGPSQualityButton:(UIButton *)sender {
    sender.selected = YES;
    
    if (sender == self.nonDebugGPS) {
        self.greenGPS.selected = NO;
        self.yellowGPS.selected = NO;
        self.redGPS.selected = NO;
        [OSVUserDefaults sharedInstance].debugLocationAccuracy = 0;
    } else if (sender == self.greenGPS) {
        self.nonDebugGPS.selected = NO;
        self.yellowGPS.selected = NO;
        self.redGPS.selected = NO;
        [OSVUserDefaults sharedInstance].debugLocationAccuracy = 1;
    } else if (sender == self.yellowGPS) {
        self.greenGPS.selected = NO;
        self.nonDebugGPS.selected = NO;
        self.redGPS.selected = NO;
        [OSVUserDefaults sharedInstance].debugLocationAccuracy = 2;
    } else if (sender == self.redGPS) {
        self.greenGPS.selected = NO;
        self.yellowGPS.selected = NO;
        self.nonDebugGPS.selected = NO;
        [OSVUserDefaults sharedInstance].debugLocationAccuracy = 3;
    }
}

- (IBAction)didChangeHDROption:(UISwitch *)sender {
    [OSVUserDefaults sharedInstance].hdrOption = sender.on;
}

- (IBAction)didTouchCrash:(id)sender {
    [[Crashlytics sharedInstance] crash];
}

- (IBAction)debugLogsOBD:(UISwitch *)sender {
    [OSVUserDefaults sharedInstance].debugLogOBD = sender.on;
    [[OSVUserDefaults sharedInstance] save];
}

- (IBAction)didChangeSLSwitch:(UISwitch *)sender {
    [OSVUserDefaults sharedInstance].debugSLUS = sender.on;
}


- (IBAction)didChangeFrameRate:(UITextField *)sender {
    double value = [sender.text doubleValue];
    [OSVUserDefaults sharedInstance].debugFrameRate = value;
    [[OSVUserDefaults sharedInstance] save];
    self.frameRateLabel.text = [NSString stringWithFormat:@"%.f frames/sec when possible", value];
    [sender resignFirstResponder];
}

- (IBAction)didChangeFrameSize:(UITextField *)sender {
    double value = [sender.text doubleValue];
    [OSVUserDefaults sharedInstance].debugFrameSize = value;
    [[OSVUserDefaults sharedInstance] save];
    
    self.frameMaxDimensionLabel.text = [NSString stringWithFormat:@"%.f w x %.f h (landscape)\n %.f w x %.f h (portrait)", value, floorf(value/1.33), floorf(value/1.33), value];
    
    [sender resignFirstResponder];
}

- (IBAction)didChangeBitRate:(UITextField *)sender {
    double value = [sender.text doubleValue];
    [OSVUserDefaults sharedInstance].debugBitRate = value;
    [[OSVUserDefaults sharedInstance] save];
    
    self.bitrateLabel.text = [NSString stringWithFormat:@"%.1f Mb bitrate", value];

    [sender resignFirstResponder];

}

- (IBAction)didChangeHQSwitch:(UISwitch *)sender {
    [OSVUserDefaults sharedInstance].debugHighDesintyOn = sender.on;
    if (sender.on) {
        self.hqLabel.text = @"HighDensity ON";
    } else {
        self.hqLabel.text = @"HighDensity OFF";
    }
}

- (IBAction)didChangeStabilization:(UISwitch *)sender {
    [OSVUserDefaults sharedInstance].debugStabilization = sender.on;
}

- (IBAction)didChangeMatcherDebug:(UISwitch *)sender {
    [OSVUserDefaults sharedInstance].debugMatcher = sender.on;
    [[OSVUserDefaults sharedInstance] save];
}

- (IBAction)moveTrackFiles:(id)sender {
    NSFileManager * fm = [[NSFileManager alloc] init];
    
    [OSVPersistentManager getAllSequencesWithCompletion:^(NSArray *sequences, NSInteger photosCount) {
        for (OSVSequence *track in sequences) {
            NSString *pathToTrack = [self metadataForTrack:track];
            NSString *pathToMove = [[OSVUtils documentsDirectoryPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%ld_track.txt", (long)track.uid]];
            [fm copyItemAtPath:pathToTrack toPath:pathToMove error:nil];
        }
    }];
}

- (NSString *)metadataForTrack:(OSVSequence *)seq {

    NSString *photoPath = [[OSVUtils createOSCBasePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%ld/track.txt", (long)seq.uid]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:photoPath]) {
        return photoPath;
    }
    
    return nil;
}

@end
