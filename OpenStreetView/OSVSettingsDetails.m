//
//  OSVSettingsDetails.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 12/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVSettingsDetails.h"
#import "OSVSectionItem.h"
#import "OSVMenuItem.h"
#import "OSVSettingsOptionCell.h"
#import "OSVUserDefaults.h"

@interface OSVSettingsDetails () <UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation OSVSettingsDetails

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.item.rowItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OSVMenuItem *item = self.item.rowItems[indexPath.row];
    
    OSVSettingsOptionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"optionIdentifier"];
    cell.optionTitle.text = item.title;
    cell.isActive = [item.key isEqualToString:[[OSVUserDefaults sharedInstance] valueForKeyPath:self.item.key]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    OSVMenuItem *item = self.item.rowItems[indexPath.row];
    
    if (self.item.action) {
        self.item.action(self, indexPath);
    }
    
    [[OSVUserDefaults sharedInstance] setValue:item.key forKeyPath:self.item.key];
    [[OSVUserDefaults sharedInstance] save];
    
    [self.tableView reloadData];
}

- (IBAction)didTapBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


@end
