//
//  OSVMainMenuFactory.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 05/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVMainMenuFactory.h"
#import <UIKit/UIKit.h>

#import "OSVSyncController.h"
#import "OSVUser.h"
#import "UIAlertView+Blocks.h"
#import "OSVUserDefaults.h"

@implementation OSVMainMenuFactory

+ (NSArray *)mainMenu {
    NSArray *array = @[[self myProfileItem],  [self waitingItem], [self settingsItem]];
    
    return array;
}

+ (OSVMenuItem *)myProfileItem {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"My Profile", @"");
    item.additional = @{@"icon":[UIImage imageNamed:@"profile"]};
    
    item.action = ^(UIViewController *sender, id info) {
        if (![[OSVSyncController sharedInstance].tracksController userIsLoggedIn]) {
            [[OSVSyncController sharedInstance].tracksController loginWithCompletion:^(NSError *error) {
                if (error) {
                    [UIAlertView showWithTitle:@"" message:@"Failed to login. Please retry." cancelButtonTitle:@"Ok" otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                        
                    }];
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [sender performSegueWithIdentifier:@"showMyProfile" sender:info];
                    });
                }
            }];
        } else {
            [sender performSegueWithIdentifier:@"showMyProfile" sender:info];
        }
    };
    
    return item;
}

+ (OSVMenuItem *)waitingItem {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"Upload", @"");
    item.additional = @{@"icon":[UIImage imageNamed:@"tracks"]};
    
    item.action = ^(UIViewController * sender, id info) {
        if ([OSVSyncController hasSequencesToUpload]) {
            if ([OSVUserDefaults sharedInstance].isUploading) {
                [sender performSegueWithIdentifier:@"showUploading" sender:info];
            } else {
                [sender performSegueWithIdentifier:@"showWaiting" sender:info];
            }
        } else {
            [UIAlertView showWithTitle:@"" message:NSLocalizedString(@"Looks like you don't have any recordings.",@"") cancelButtonTitle:NSLocalizedString(@"Ok", @"") otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                
            }];
        }
    };
    
    return item;
}

+ (OSVMenuItem *)settingsItem {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"Settings", @"");
    item.additional = @{@"icon":[UIImage imageNamed:@"settings"]};
    
    item.action = ^(UIViewController * sender, id info) {
        [sender performSegueWithIdentifier:@"showSettings" sender:info];
    };
    
    return item;
}

@end
