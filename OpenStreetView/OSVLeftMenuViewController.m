//
//  OSVLeftMenuViewController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 05/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVLeftMenuViewController.h"
#import "OSVMainViewController.h"

#import "OSVMainMenuFactory.h"
#import "OSVMainMenuCell.h"

#import "OSVSyncController.h"
#import "OSVUser.h"
#import "UIAlertView+Blocks.h"

#import "OSVUserDefaults.h"

@interface OSVLeftMenuViewController ()

@property (nonatomic, strong) NSArray   *menu;

@end

@implementation OSVLeftMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.menu = [OSVMainMenuFactory mainMenu];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willDisplayView) name:kLGSideMenuControllerWillShowLeftViewNotification object:nil];
}

- (void)willDisplayView {
    if (![[OSVSyncController sharedInstance].tracksController userIsLoggedIn]) {
        self.titleButton.text = NSLocalizedString(@"Sign In", @"");
    } else {
        self.titleButton.text = NSLocalizedString(@"Sign Out", @"");
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.menu.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OSVMainMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    OSVMenuItem *item = self.menu[indexPath.row];
    cell.title.text = item.title;
    cell.active = NO;
    cell.icon.image = item.additional[@"icon"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OSVMenuItem *item = self.menu[indexPath.row];
    item.action(self.defaultViewController, nil);
    if ([self.mainMenuDelegate respondsToSelector:@selector(hideLeftViewAnimated:completionHandler:)]) {
        [self.mainMenuDelegate hideLeftViewAnimated:YES completionHandler:^{
            
        }];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];   
}


- (IBAction)didTapActionView:(id)sender {
    if (![[OSVSyncController sharedInstance].tracksController userIsLoggedIn]) {
        [[OSVSyncController sharedInstance].tracksController loginWithCompletion:^(NSError *error) {
            if (error) {
                [[OSVSyncController sharedInstance].tracksController logout];
            } else {
                self.titleButton.text = NSLocalizedString(@"Sign Out", @"");
            }
        }];
    } else {
        [UIAlertView showWithTitle:@""
                           message:NSLocalizedString(@"Are you sure you want to logout?", @"Preemtiv message to stop a unwanted loggout form the current online user profile")
                 cancelButtonTitle:NSLocalizedString(@"No", nil)
                 otherButtonTitles:@[NSLocalizedString(@"Yes", nil)]
                          tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                              if (buttonIndex == [alertView cancelButtonIndex]) {

                              } else {
                                  [[OSVSyncController sharedInstance].tracksController logout];
                                  self.titleButton.text = NSLocalizedString(@"Sign In", @"");
                              }
                          }];


    }
}

@end
