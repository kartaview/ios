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

#define kProductionBaseURLOSV           @"http://openstreetview.com"
#define kTstBaseURLOSV                  @"http://tst.open-street-view.skobbler.net"
#define kStagingBaseURLOSV              @"http://staging.open-street-view.skobbler.net"

@interface OSVDebugViewController ()

@property (weak, nonatomic) IBOutlet UILabel            *revisionNumber;
@property (weak, nonatomic) IBOutlet UISwitch           *positionerSwitch;
@property (weak, nonatomic) IBOutlet UIButton           *simulatorButton;

@property (weak, nonatomic) IBOutlet UIButton           *testEnvironment;
@property (weak, nonatomic) IBOutlet UIButton           *stagingEnvironment;
@property (weak, nonatomic) IBOutlet UIButton           *productionEnvironment;

@property (weak, nonatomic) IBOutlet UISwitch           *hdrSwitch;
@property (weak, nonatomic) IBOutlet UISwitch           *debugLogsOBD;
@property (weak, nonatomic) IBOutlet UISwitch           *debugSLUS;

@end

@implementation OSVDebugViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //this file is created with a run script and it represents the svn version of the app
    NSString *path = [[NSBundle mainBundle] pathForResource:@"revision" ofType:@"osv"];
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    
    self.revisionNumber.text = [NSString stringWithFormat:@"Revision %@", content];
    self.simulatorButton.hidden = [OSVUserDefaults sharedInstance].realPositions;
    
    self.testEnvironment.selected = [[OSVUserDefaults sharedInstance].environment isEqualToString:kTstBaseURLOSV];
    self.stagingEnvironment.selected = [[OSVUserDefaults sharedInstance].environment isEqualToString:kStagingBaseURLOSV];
    self.productionEnvironment.selected = [[OSVUserDefaults sharedInstance].environment isEqualToString:kProductionBaseURLOSV];
    
    [self.hdrSwitch setOn:[OSVUserDefaults sharedInstance].hdrOption animated:NO];
    
    [self.debugLogsOBD setOn:[OSVUserDefaults sharedInstance].debugLogOBD animated:NO];
    [self.debugSLUS setOn:[OSVUserDefaults sharedInstance].debugSLUS animated:NO];

    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.positionerSwitch setOn:[OSVUserDefaults sharedInstance].realPositions animated:NO];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
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
        [OSVUserDefaults sharedInstance].environment = kTstBaseURLOSV;
    } else if (sender == self.stagingEnvironment) {
        self.testEnvironment.selected = NO;
        self.productionEnvironment.selected = NO;
        [OSVUserDefaults sharedInstance].environment = kStagingBaseURLOSV;
    } else if (sender == self.productionEnvironment) {
        self.testEnvironment.selected = NO;
        self.stagingEnvironment.selected = NO;
        [OSVUserDefaults sharedInstance].environment = kProductionBaseURLOSV;
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

@end
