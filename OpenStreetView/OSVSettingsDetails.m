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

@property (weak, nonatomic) IBOutlet UITableView                *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView    *activityIndicator;

@end

@implementation OSVSettingsDetails

- (void)viewDidLoad {
    [super viewDidLoad];
    self.activityIndicator.hidden = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:@"kReloadDetails" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(waitForData) name:@"kWaitForData" object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Orientation 

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - TableView DataSource

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

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    OSVMenuItem *item = self.item.rowItems[indexPath.row];
    
    if (self.item.action) {
        self.item.action(self, indexPath);
    }
    
    [[OSVUserDefaults sharedInstance] setValue:item.key forKeyPath:self.item.key];
    [[OSVUserDefaults sharedInstance] save];
    
    [self.tableView reloadData];
}

#pragma mark - Actions

- (IBAction)didTapBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Public 

- (void)reloadData {
    [self.activityIndicator stopAnimating];
    self.activityIndicator.hidden = YES;
    [self.tableView reloadData];
}

- (void)waitForData {
    [self.activityIndicator startAnimating];
    self.activityIndicator.hidden = NO;
}

@end
