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
    NSArray *array;
    if ([OSVUserDefaults sharedInstance].useGamification) {
        array = @[[self myProfileItem],
                   [self localTracksItem],
                   [self leaderboardItem],
                   [self settingsItem]];
    } else {
        array = @[[self myProfileItem],
                   [self localTracksItem],
                   [self settingsItem]];
    }
    
    
    return array;
}

//TODO check version from 07/02/2017
+ (OSVMenuItem *)myProfileItem {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"My Profile", @"");
    item.additional = @{@"icon":[UIImage imageNamed:@"profile"]};
    
    item.action = ^(UIViewController *sender, id info) {
        if (![[OSVSyncController sharedInstance].tracksController userIsLoggedIn]) {
			[sender performSegueWithIdentifier:@"showLoginController" sender:info];
        } else {
            [sender performSegueWithIdentifier:@"showMyProfile" sender:info];
        }
    };
    
    return item;
}

//TODO check version from 07/02/2017
+ (OSVMenuItem *)localTracksItem {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"Upload", @"");
    item.additional = @{@"icon":[UIImage imageNamed:@"tracks"]};
    
    item.action = ^(UIViewController *sender, id info) {
        if ([OSVSyncController hasSequencesToUpload]) {
            if ([OSVUserDefaults sharedInstance].isUploading) {
				[sender performSegueWithIdentifier:@"showUploading" sender:info];
            } else {
                [sender performSegueWithIdentifier:@"showLocalTracks" sender:info];
            }
        } else {
            [UIAlertView showWithTitle:@"" message:NSLocalizedString(@"Looks like you don't have any recordings.",@"") cancelButtonTitle:NSLocalizedString(@"Ok", @"") otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                
            }];
        }
    };
    
    return item;
}

+ (OSVMenuItem *)leaderboardItem {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"Leaderboard", @"");
    item.additional = @{@"icon":[UIImage imageNamed:@"leaderboard"]};
    
    item.action = ^(UIViewController *sender, id info) {
        [sender performSegueWithIdentifier:@"showLeaderboard" sender:info];
    };
    
    return item;
}

+ (OSVMenuItem *)settingsItem {
    OSVMenuItem *item = [OSVMenuItem new];
    item.title = NSLocalizedString(@"Settings", @"");
    item.additional = @{@"icon":[UIImage imageNamed:@"settings"]};
    
    item.action = ^(UIViewController *sender, id info) {
        [sender performSegueWithIdentifier:@"showSettings" sender:info];
    };
    
    return item;
}

@end
