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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willDisplayView) name:kLGSideMenuControllerWillShowLeftViewNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showUploadScreen) name:@"kShowUploadScreen" object:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)willDisplayView {
    if (![[OSVSyncController sharedInstance].tracksController userIsLoggedIn]) {
        self.titleButton.text = NSLocalizedString(@"Sign In", @"");
    } else {
        self.titleButton.text = NSLocalizedString(@"Sign Out", @"");
    }
    
    self.menu = [OSVMainMenuFactory mainMenu];
    [self.tableView reloadData];
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
    if (item && item.action) {
        item.action(self.defaultViewController, nil);
    }
    if ([self.mainMenuDelegate respondsToSelector:@selector(hideLeftViewAnimated:completionHandler:)]) {
        [self.mainMenuDelegate hideLeftViewAnimated:YES completionHandler:^{
            
        }];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];   
}

- (IBAction)didTapActionView:(id)sender {
	if ([[OSVSyncController sharedInstance].tracksController userIsLoggedIn]) {
		if (![OSVSyncController isUploading]) {
			[UIAlertView showWithTitle:@""
							   message:NSLocalizedString(@"Are you sure you want to logout?", @"")
					 cancelButtonTitle:NSLocalizedString(@"No", nil)
					 otherButtonTitles:@[NSLocalizedString(@"Yes", nil)]
							  tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
								  if (buttonIndex != [alertView cancelButtonIndex]) {
									  [[OSVSyncController sharedInstance].tracksController logout];
									  self.titleButton.text = NSLocalizedString(@"Sign In", @"");
								  }
							  }];
		} else {
			[UIAlertView showWithTitle:@""
							   message:NSLocalizedString(@"Can not logout while uploading!", @"")
					 cancelButtonTitle:NSLocalizedString(@"Ok", nil)
					 otherButtonTitles:nil
							  tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
							  }];
		}
	} else {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLoginWithSuccess:) name:@"kOSVDidSigninRequest" object:nil];
		
		[self.defaultViewController performSegueWithIdentifier:@"showLoginController" sender:nil];

		if ([self.mainMenuDelegate respondsToSelector:@selector(hideLeftViewAnimated:completionHandler:)]) {
			[self.mainMenuDelegate hideLeftViewAnimated:YES completionHandler:^{
			}];
		}
	}
}

- (void)didLoginWithSuccess:(NSNotification *)notification {
	NSNumber *success = notification.userInfo[@"success"];
	if ([success boolValue]) {
		self.titleButton.text = NSLocalizedString(@"Sign Out", @"");
	} else {
		self.titleButton.text = NSLocalizedString(@"Sign In", @"");
	}
}

- (void)showUploadScreen {
    //TODO this is a hack
    OSVMenuItem *item = self.menu[1];
    if (item && item.action) {
        item.action(self.defaultViewController, nil);
    }
}

@end
