//
//  OSVSettingsMenuFactory.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVSettingsMenuFactory.h"
#import "OSVSettingsViewController.h"
#import <UIKit/UIKit.h>
#import "UIAlertView+Blocks.h"
#import "OSVReachablityController.h"
#import "OSVSyncController.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "OSVLocationManager.h"
#import "OSVUserDefaults.h"
#import "OSVTipView.h"

#import "OSVUser.h"

#import <AVFoundation/AVFoundation.h>

#import "UIDevice+Aditions.h"
#import "OSC-Swift.h"

#import <SKMaps/SKMaps.h>
#import <SafariServices/SafariServices.h>

@implementation OSVSettingsMenuFactory

#pragma mark - Menu Factory

+ (NSArray *)settingsMenuWithWiFiOBDStatus:(int)connectionStatus
                                 BLEStatus:(int)bleStat
                          enableSecretMenu:(BOOL)secretMenu {
    
    if (secretMenu) {
        return @[[self settingsSection],
                 [self obdSectionWithWiFiStatus:connectionStatus BLEStatus:bleStat],
                 [self feedbackSection],
                 [self aboutSection],
                 [self debugSection]];
    } else {
        return @[[self settingsSection],
                 [self obdSectionWithWiFiStatus:connectionStatus BLEStatus:bleStat],
                 [self feedbackSection],
                 [self aboutSection]];
    }
}

#pragma mark - Sections Factory

+ (OSVSectionItem *)settingsSection {
    OSVSectionItem *settingsSection = [OSVSectionItem new];
    if (![OSVUserDefaults sharedInstance].enableMap) {
        settingsSection.rowItems = [@[[self wifiItem],
                                      [self autoUploadItem],
                                      [self metricItem],
                                      [self videoQualityItem],
                                      [self enableMapItem],
                                      [self signDetectionItem],
                                      [self gamificationItem]] mutableCopy];
    } else {
        settingsSection.rowItems = [@[[self wifiItem],
                                      [self autoUploadItem],
                                      [self metricItem],
                                      [self videoQualityItem],
                                      [self enableMapItem],
                                      [self showMapItem],
                                      [self signDetectionItem],
                                      [self gamificationItem]] mutableCopy];
    }
    
    settingsSection.title = NSLocalizedString(@"GENERAL", nil);
    
    return settingsSection;
}

+ (OSVSectionItem *)feedbackSection {
    OSVSectionItem *feedbackItem = [OSVSectionItem new];
    feedbackItem.rowItems = [@[[self feedbackItem],
                               [self tipsItem],
                               [self walkthrough]] mutableCopy];
    feedbackItem.title = NSLocalizedString(@"IMPROVE", nil);
    
    return feedbackItem;
}

+ (OSVSectionItem *)aboutSection {
    OSVSectionItem *aboutItem = [OSVSectionItem new];
    aboutItem.rowItems = [@[[self appVersion],
                            [self termsConditions],
                            [self privacyPolicy],
                            [self copyRight]] mutableCopy];
    aboutItem.title = NSLocalizedString(@"ABOUT", nil);
    
    return aboutItem;
}

+ (OSVSectionItem *)obdSectionWithWiFiStatus:(int)connected BLEStatus:(int)connectedBLE {
    OSVSectionItem *section = [OSVSectionItem new];
    if (connected == 0) {
        section.rowItems = [@[[self obdDisconnected]] mutableCopy];
    } else if (connected == 1) {
        section.rowItems = [@[[self obdConnecting]] mutableCopy];
    } else {
        section.rowItems = [@[[self obdConnected]] mutableCopy];
    }
    
    if (connectedBLE == 0) {
        [section.rowItems addObject:[self obdBLEDisconnected]];
    } else if (connectedBLE == 1) {
        [section.rowItems addObject:[self obdConnecting]];
    } else {
        [section.rowItems addObject:[self obdBLEConnected]];
    }
    
    section.title = NSLocalizedString(@"OBD2 CONNECTION", @"");
    
    return section;
}

#pragma mark - Debug Settings Section

+ (OSVSectionItem *)debugSection {
    OSVSectionItem *settingsSection = [OSVSectionItem new];
    settingsSection.rowItems = [@[[self debugItem]]mutableCopy];
    
    return settingsSection;
}

#pragma mark Settins Item Factory

+ (OSVMenuItem *)wifiItem {
    OSVMenuItem *wifi = [OSVMenuItem new];
    wifi.title = NSLocalizedString(@"Upload on cellular data", @"Posibility to use the celullar data for uploading");
    wifi.subtitle = NSLocalizedString(@"When enabled, the app will use cellular data if no Wi-Fi is available.", @"");
    wifi.type = OSVMenuItemSwitch;
    wifi.key = @"useCellularData";
    
    return wifi;
}

+ (OSVMenuItem *)autoUploadItem {
    OSVMenuItem *autoUpload = [OSVMenuItem new];
    autoUpload.title = NSLocalizedString(@"Automatic upload", @"Enable the upload of sequences automaticaly when the conection is appropriate");
    autoUpload.subtitle = NSLocalizedString(@"When enabled, the app will automaticaly upload local recordings when possible.", nil);
    autoUpload.type = OSVMenuItemSwitch;
    autoUpload.key = @"automaticUpload";
    
    return autoUpload;
}

+ (OSVMenuItem *)metricItem {
    OSVSectionItem *resDatasource = [self metricDatasource];
    OSVMenuItem *item = [self metricDictionary][[OSVUserDefaults sharedInstance].distanceUnitSystem];
    
    OSVMenuItem *metric = [OSVMenuItem new];
    metric.title = NSLocalizedString(@"Distance unit", @"Text to desribe that this setting afects the distance mesuring system used");
    metric.subtitle = item.title;
    metric.type = OSVMenuItemDetails;
    
    metric.action = ^(OSVSettingsViewController *sender, OSVSectionItem *item) {
        [sender performSegueWithIdentifier:@"showSettingsDetails" sender:resDatasource];
    };

    return metric;
}

+ (OSVSectionItem *)metricDatasource {
    OSVSectionItem *item = [OSVSectionItem new];
    item.rowItems = [@[[self itemImperial], [self itemMetric]] mutableCopy];
    item.key = @"distanceUnitSystem";
    item.title = NSLocalizedString(@"Distance unit", @"");
    item.action = ^(id vc, id indexPath) {
        [OSVUserDefaults sharedInstance].automaticDistanceUnitSystem = NO;
        [[OSVUserDefaults sharedInstance] save];
    };
    
    return item;
}

+ (NSDictionary *)metricDictionary {
    NSDictionary *distanceUnitDict;
    distanceUnitDict = @{kMetricSystem      : [self itemMetric],
                         kImperialSystem    : [self itemImperial]};
    
    return distanceUnitDict;
}

+ (OSVMenuItem *)itemImperial {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"imperial", @"");
    item.type = OSVMenuItemOption;
    item.key = kImperialSystem;
    
    return item;
}

+ (OSVMenuItem *)itemMetric {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"metric", @"");
    item.type =OSVMenuItemOption;
    item.key = kMetricSystem;
    
    return item;
}

+ (OSVMenuItem *)videoQualityItem {
    OSVSectionItem *resDatasource = [self resolutionDatasource];
    NSDictionary *dict = [self resolutionDictionaryFormArray:resDatasource.rowItems];
    OSVMenuItem *item = dict[[OSVUserDefaults sharedInstance].videoQuality];
    
    OSVMenuItem *video = [OSVMenuItem new];
    video.title = NSLocalizedString(@"Resolution", @"");
    video.subtitle = item.title;
    video.type = OSVMenuItemDetails;
    
    video.action = ^(OSVSettingsViewController *sender, OSVSectionItem *item) {
        [sender performSegueWithIdentifier:@"showSettingsDetails" sender:resDatasource];
    };
    
    return video;
}

+ (OSVSectionItem *)resolutionDatasource {
    OSVSectionItem *item = [OSVSectionItem new];
    item.title = NSLocalizedString(@"Resolution", @"");
    item.key = @"videoQuality";
    
    if ([UIDevice isLessTheniPhone6]) {
        item.rowItems = [@[[self smallerResolution]] mutableCopy];
    } else {
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        AVCaptureDevice *captureDevice = [devices firstObject];
        
        for (AVCaptureDevice *device in devices) {
            if ([device position] == AVCaptureDevicePositionBack) {
                captureDevice = device;
                break;
            }
        }
        
        AVCaptureDeviceFormat *format = [captureDevice.formats lastObject];
        CMVideoDimensions dim = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        BOOL has12MP = NO;
        
        if (dim.width > 3264) {
            has12MP = YES;
        }
        
        if (has12MP) {
            item.rowItems = [@[[self smallerResolution],
                               [self smallResolution],
                               [self mediumResolution],
                               [self highResolution]] mutableCopy];
        } else {
            item.rowItems = [@[[self smallerResolution],
                               [self smallResolution],
                               [self mediumResolution]] mutableCopy];
        }
    }
    
    return item;
}

+ (NSDictionary *)resolutionDictionaryFormArray:(NSArray *)array {
    NSDictionary *resolutionsDictionary;
    if ([UIDevice isLessTheniPhone6]) {
        resolutionsDictionary = @{k2MPQuality : array[0]};
    } else {
        if ([array count] == 4) {
            resolutionsDictionary = @{k2MPQuality : array[0],
                                      k5MPQuality : array[1],
                                      k8MPQuality : array[2],
                                      k12MPQuality: array[3]};
        } else {
            resolutionsDictionary = @{k2MPQuality : array[0],
                                      k5MPQuality : array[1],
                                      k8MPQuality : array[2]};
        }
    }
    
    return resolutionsDictionary;
}

+ (OSVMenuItem *)smallerResolution {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"2 MP", @"");
    item.type = OSVMenuItemOption;
    item.key = k2MPQuality;
    
    return item;
}

+ (OSVMenuItem *)smallResolution {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"5 MP", @"");
    item.type = OSVMenuItemOption;
    item.key = k5MPQuality;
    
    return item;
}

+ (OSVMenuItem *)mediumResolution {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"8 MP", @"");
    item.type = OSVMenuItemOption;
    item.key = k8MPQuality;
    
    return item;
}

+ (OSVMenuItem *)highResolution {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"12 MP", @"");
    item.type = OSVMenuItemOption;
    item.key = k12MPQuality;
    
    return item;
}

+ (OSVMenuItem *)enableMapItem {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"Enable map", @"");
    item.subtitle = NSLocalizedString(@"Maps use more resources and it may decrease performace.", @"");
    item.type = OSVMenuItemSwitch;
    item.key = @"enableMap";
    
    item.action = ^(OSVSettingsViewController *sender, NSNumber *value) {
        if ([OSVUserDefaults sharedInstance].enableMap) {
            //init the map so it will not crash the application when trying to access SKPositioner.currentLocation
            SKMapsInitSettings *mapsettings = [SKMapsInitSettings mapsInitSettings];
            mapsettings.mapStyle.resourcesFolderName = @"GrayscaleStyle";
            mapsettings.mapStyle.styleFileName = @"grayscalestyle.json";
            [[SKMapsService sharedInstance] initializeSKMapsWithAPIKey:@"" settings:mapsettings];
        }

        [UIAlertView showWithTitle:NSLocalizedString(@"", @"")
                           message:NSLocalizedString(@"The app has to be restarted for this to take place", @"")
                 cancelButtonTitle:NSLocalizedString(@"Ok", @"")
                 otherButtonTitles:@[NSLocalizedString(@"Not now", @"")]
                          tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                if (buttonIndex == [alertView cancelButtonIndex]) {
                    exit(0);
                } else {
                    [OSVUserDefaults sharedInstance].enableMap = ![OSVUserDefaults sharedInstance].enableMap;
                    [sender reloadData];
                }
            }];
    };

    
    return item;
}

+ (OSVMenuItem *)showMapItem {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"Display map while recording", @"");
    item.subtitle = NSLocalizedString(@"Map display increases battery and data consumption.", @"");
    item.type = OSVMenuItemSwitch;
    item.key = @"showMapWhileRecording";
    
    return item;
}

+ (OSVMenuItem *)signDetectionItem {
    OSVMenuItem *video = [OSVMenuItem new];
    video.title = NSLocalizedString(@"Detect road signs", @"");
    video.subtitle = NSLocalizedString(@"Only works in landscape mode with home button on the right.", @"");
    video.type = OSVMenuItemSwitch;
    video.key = @"useImageRecognition";
    
    return video;
}

+ (OSVMenuItem *)gamificationItem {
    OSVMenuItem *video = [OSVMenuItem new];
    video.title = NSLocalizedString(@"Points", @"");
    video.subtitle = NSLocalizedString(@"Compete with other users and improve your ranking.", @"");
    video.type = OSVMenuItemSwitch;
    video.key = @"useGamification";
    
    return video;
}

#pragma mark - Feedback Item Factory

+ (OSVMenuItem *)feedbackItem {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"Send Feedback", @"");
    item.subtitle = NSLocalizedString(@"", @"");
    item.type = OSVMenuItemDetails;
    item.action = ^(OSVSettingsViewController *sender, id indexPath) {
        NSURL *url = [NSURL URLWithString:@"https://github.com/openstreetview/ios/issues"];
        
        if ([[SFSafariViewController alloc] respondsToSelector:@selector(initWithURL:)]) {
            UIViewController *vc = [[SFSafariViewController alloc] initWithURL:url];
            
            [sender presentViewController:vc animated:YES completion:^{
                
            }];
            
        } else {
            [[UIApplication sharedApplication] openURL:url];
        }

        [sender reloadData];
    };
    
    return item;
}

#pragma mark - About Item Factory 

+ (OSVMenuItem *)tipsItem {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"Tips", nil);
    item.subtitle = NSLocalizedString(@"See how to improve your recordings. \n", nil);
    item.type = OSVMenuItemDetails;
    item.action = ^(OSVSettingsViewController *sender, id indexPath) {
        OSVTipView *tipview = [[[NSBundle mainBundle] loadNibNamed:@"OSVTipView" owner:self options:nil] objectAtIndex:0];
        [tipview configureViews];
        
        [sender.navigationController.view addSubview:tipview];
        tipview.frame = sender.navigationController.view.frame;
        [sender reloadData];
    };
    
    return item;
}

+ (OSVMenuItem *)walkthrough {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"Walkthrough", nil);
    item.subtitle = NSLocalizedString(@"What OpenStreetCam is about. \n", nil);
    item.type = OSVMenuItemDetails;
    item.action = ^(OSVSettingsViewController *sender, id indexPath) {
        OSVTipView *tipView = [[[NSBundle mainBundle] loadNibNamed:@"OSVTipView" owner:self options:nil] objectAtIndex:0];
        [tipView prepareIntro];
        [tipView configureViews];
        
        PortraitViewController *vc = [PortraitViewController new];
        vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

        tipView.willDissmiss = ^() {
            [vc dismissViewControllerAnimated:YES completion:^{}];
            return YES;
        };
        
        [sender presentViewController:vc animated:NO completion:^{
            [vc.view addSubview:tipView];
        }];

        tipView.frame = sender.navigationController.view.frame;
        [sender reloadData];
    };
    
    return item;
}

+ (OSVMenuItem *)appVersion {
    OSVMenuItem *item = [OSVMenuItem new];
    item.type = OSVMenuItemAction;

    NSString *appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *versionBuildString = [NSString stringWithFormat:@"%@ (%@)", appVersionString, appBuildString];
    item.title = versionBuildString;
    item.subtitle = NSLocalizedString(@"Build version", @"");
    
    return item;
}

+ (OSVMenuItem *)termsConditions {
    OSVMenuItem *item = [OSVMenuItem new];
    item.type = OSVMenuItemDetails;
    item.title = NSLocalizedString(@"Terms & Conditions", @"");
    
    item.action = ^(OSVSettingsViewController *sender, id indexPath) {
        NSURL *url = [NSURL URLWithString:@"http://openstreetcam.org/terms/"];
        if ([[SFSafariViewController alloc] respondsToSelector:@selector(initWithURL:)]) {
            UIViewController *vc = [[SFSafariViewController alloc] initWithURL:url];
            
            [sender presentViewController:vc animated:YES completion:^{
                
            }];

        } else {
            [[UIApplication sharedApplication] openURL:url];
        }
    };

    return item;
}

+ (OSVMenuItem *)privacyPolicy {
    OSVMenuItem *item = [OSVMenuItem new];
    item.type = OSVMenuItemDetails;
    item.title = NSLocalizedString(@"Privacy Policy", @"");
    
    item.action = ^(OSVSettingsViewController *sender, id indexPath) {
        NSURL *url = [NSURL URLWithString:@"http://www.telenav.com/legal/policies.html#privacy-policy"];
        if ([[SFSafariViewController alloc] respondsToSelector:@selector(initWithURL:)]) {
            UIViewController *vc = [[SFSafariViewController alloc] initWithURL:url];
            
            [sender presentViewController:vc animated:YES completion:^{
                
            }];
            
        } else {
            [[UIApplication sharedApplication] openURL:url];
        }
    };

    return item;
}

+ (OSVMenuItem *)copyRight {
    OSVMenuItem *item = [OSVMenuItem new];
    item.type = OSVMenuItemAction;
    item.title = NSLocalizedString(@"Copyright 2017 Telenav GmbH", @"");
    
    return item;
}

#pragma mark - OBD II Item Factory 

+ (OSVMenuItem *)obdDisconnected {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"WiFi Not connected", nil);
    item.subtitle = NSLocalizedString(@"Connect", nil);
    item.type = OSVMenuItemButton;
    item.action = ^(OSVSettingsViewController *sender, id indexPath) {
        sender.obdWIFIConnectionStatus = 1;
        [[OSVSensorsManager sharedInstance] startUpdatingOBD];
        [sender reloadData];
    };
    
    return item;
}

+ (OSVMenuItem *)obdConnecting {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"Connecting ... ", nil);
    item.type = OSVMenuItemBasic;

    return item;
}

+ (OSVMenuItem *)obdConnected {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"WiFi Connected to OBD 2", nil);
    item.subtitle = NSLocalizedString(@"Disconnect", nil);
    item.type = OSVMenuItemButton;
    item.action = ^(OSVSettingsViewController *sender, id indexPath) {
        sender.obdWIFIConnectionStatus = 2;
        [[OSVSensorsManager sharedInstance] stopUpdatingOBD];
        [sender reloadData];
    };
    
    return item;
}

+ (OSVMenuItem *)obdBLEDisconnected {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"BluetoothLE Not connected", nil);
    item.type = OSVMenuItemDetails;
    item.action = ^(OSVSettingsViewController *sender, id indexPath) {
        sender.obdBLEConnectionStatus = 1;
        [[OSVSensorsManager sharedInstance] startBLEOBDScan];
        OSVSectionItem *dataItem = [self obdBLE];
        dataItem.key = @"bleDevice";
        [sender performSegueWithIdentifier:@"showSettingsDetails" sender:dataItem];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BLEDatasource" object:nil userInfo:@{@"datasource":dataItem}];
        [sender reloadData];
    };
    
    return item;
}

+ (OSVSectionItem *)obdBLE {
    OSVSectionItem *item = [OSVSectionItem new];
    return item;
}

+ (OSVMenuItem *)obdBLEConnected {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"BLE Connected to OBD 2", nil);
    item.subtitle = [NSString stringWithFormat:NSLocalizedString(@"Disconnect %@", nil), [OSVUserDefaults sharedInstance].bleDevice];
    item.type = OSVMenuItemButton;
    item.action = ^(OSVSettingsViewController *sender, id indexPath) {
        sender.obdBLEConnectionStatus = 2;
        [[OSVSensorsManager sharedInstance] stopUpdatingOBD];
        [sender reloadData];
    };
    
    return item;
}

#pragma mark - Debug

+ (OSVMenuItem *)debugItem {
    OSVMenuItem *debug = [OSVMenuItem new];
    debug.title = @"Debug";
    debug.type = OSVMenuItemButton;
    debug.action = ^(UIViewController *sender, id indexPath) {
        [sender performSegueWithIdentifier:@"debugSegue" sender:indexPath];
    };
    
    return debug;
}

@end
