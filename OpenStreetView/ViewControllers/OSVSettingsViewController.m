//
//  OSVSettingsViewController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 09/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVSettingsViewController.h"
#import "OSVUserDefaults.h"
#import "OSVLocationManager.h"
#import "OSVSyncController.h"

#import "OSVUtils.h"

#import "OSVProfileMenuFactory.h"

#import "OSVSettingsSwitchCell.h"
#import "OSVSectionHeaderCell.h"
#import "OSVDetailsCell.h"
#import "OSVBasicCell.h"

#import "UIColor+OSVColor.h"
#import "UIBarButtonItem+Aditions.h"
#import <MessageUI/MFMailComposeViewController.h>

#import "OSVSettingsDetails.h"

@interface OSVSettingsViewController () <UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate>

@property (strong, nonatomic) OSVSyncController     *syncController;
@property (weak, nonatomic) IBOutlet UITableView    *tableView;
@property (strong, nonatomic) NSArray               *datasource;

@end

@implementation OSVSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.syncController = [OSVSyncController sharedInstance];
    self.datasource = [OSVProfileMenuFactory settingsMenuWithOBDStatus:self.obdConnectionStatus];    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.obdConnectionStatus = 0;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidConnectToOBD:) name:@"kOBDDidConnect" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidDisconnectFromOBD:) name:@"kOBDDidDisconnect" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidFailToConnectOBD:) name:@"kOBDFailedToConnectInTime" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kOBDStatus" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Private

- (void)reloadData {
    self.datasource = [OSVProfileMenuFactory settingsMenuWithOBDStatus:self.obdConnectionStatus];
    [self.tableView reloadData];
}

- (void)didPressDissmiss {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)deselectTableViewCell {
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showSettingsDetails"]) {
        OSVSectionItem *item = sender;
        
        OSVSettingsDetails *vc = segue.destinationViewController;
        vc.item = item;
        [vc.titleButton setTitle:item.title forState:UIControlStateNormal];
    }
}

#pragma mark - UITableView Datasource 

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.datasource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    OSVSectionItem *item = self.datasource[section];
    return item.rowItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    OSVSectionItem *section = self.datasource[indexPath.section];
    OSVMenuItem *item = section.rowItems[indexPath.row];

    if (item.type == OSVMenuItemSwitch) {
        OSVSettingsSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"switchCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.titleLable.text = item.title;
        cell.subTitleLabel.text = item.subtitle;
        [cell.onOffSwitch setOn:[[[OSVUserDefaults sharedInstance] valueForKeyPath:item.key] boolValue] animated:NO];

        cell.toggleBlock = ^(BOOL value) {
            [[OSVUserDefaults sharedInstance] setValue:[NSNumber numberWithBool:value] forKeyPath:item.key];
            [[OSVUserDefaults sharedInstance] save];
        };
        
        return cell;
    } else if (item.type == OSVMenuItemDetails) {
        OSVDetailsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detailsCell"];
        cell.titleLabel.text = item.title;
        cell.subTitleLabel.text = item.subtitle;
        
        return cell;
    } else  if (item.type == OSVMenuItemAction) {
        OSVDetailsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"subtitleCell"];
        cell.titleLabel.text = item.title;
        cell.subTitleLabel.text = item.subtitle;
        if (!item.action) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        return cell;
    } else {
        OSVBasicCell *cell = [tableView dequeueReusableCellWithIdentifier:@"basicCell"];
        if (item.type == OSVMenuItemBasic) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        cell.titleLabel.text = item.title;
        if (item.type == OSVMenuItemButton) {
            cell.rightText.text = item.subtitle;
        } 
        
        return cell;
    }
}

#pragma mark - UITableView Delegate 

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    OSVSectionItem *section = self.datasource[indexPath.section];
    OSVMenuItem *item = section.rowItems[indexPath.row];
    
    if (item.type == OSVMenuItemSwitch) {
        return 94;
    }
    
    if (item.type == OSVMenuItemAction || item.type == OSVMenuItemDetails) {
        return 80;
    }

    return 46;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    OSVSectionHeaderCell *headerView = [tableView dequeueReusableCellWithIdentifier:@"sectionHeader"];
    OSVSectionItem *item = self.datasource[section];
    headerView.sectionTitle.text = item.title;
    headerView.sectionTitle.font = [UIFont systemFontOfSize:18];
    
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    OSVSectionItem *section = self.datasource[indexPath.section];
    OSVMenuItem *item = section.rowItems[indexPath.row];
    
    if (item.type == OSVMenuItemAction || item.type == OSVMenuItemButton || item.type == OSVMenuItemDetails) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (item.action) {
                item.action(self, indexPath);
            }
        });
    }
}

#pragma mark - private

- (void)managerDidConnectToOBD:(OSVSensorsManager *)manager {
    self.obdConnectionStatus = 2;
    [self reloadData];
}

- (void)managerDidDisconnectFromOBD:(OSVSensorsManager *)manager {
    self.obdConnectionStatus = 0;
    [self reloadData];
}

- (void)managerDidFailToConnectOBD:(OSVSensorsManager *)manager {
    self.obdConnectionStatus = 0;
    [self reloadData];
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(nullable NSError *)error __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0) {
    [controller dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (IBAction)didTapBackButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
