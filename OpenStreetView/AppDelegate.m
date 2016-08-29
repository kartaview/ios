//
//  AppDelegate.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 09/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "AppDelegate.h"
#import <SKMaps/SKMaps.h>
#import "AFOAuth1Client.h"
#import <Realm/Realm.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "OSVLocationManager.h"

#import "OSVSyncController.h"

#import "OSVUserDefaults.h"

#import "UIAlertView+Blocks.h"
#import "OSVReachablityController.h"

#import "OSVUser.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Fabric with:@[[Crashlytics class]]];
    NSString *username = [OSVSyncController sharedInstance].tracksController.user.name;
    if (username) {
        [CrashlyticsKit setUserName:username];
    }
    
    [[OSVSyncController sharedInstance].tracksController checkForAppUpdateWithCompletion:^(BOOL response) {
        if (response) {
            [[UIApplication sharedApplication] openURL:[[OSVSyncController sharedInstance].tracksController getAppLink]];
        }
    }];
    
    SKMapsInitSettings *mapsettings = [SKMapsInitSettings mapsInitSettings];
    
    [[SKMapsService sharedInstance] initializeSKMapsWithAPIKey:@"47c0589b94694c04e757f6c36157f13b21d30d051d662b7c8034bf3988bd9843" settings:mapsettings];
    [[OSVLocationManager sharedInstance].sensorsManager startUpdatingOBD];

    if ([CLLocationManager authorizationStatus] !=  kCLAuthorizationStatusNotDetermined) {
        [[SKPositionerService sharedInstance] startLocationUpdate];        
    }
    
    if ([OSVUserDefaults sharedInstance].isUploading && ![OSVUserDefaults sharedInstance].automaticUpload) {
        [UIAlertView showWithTitle:@"Continue uploading?" message:@"OpenStreetView closed while uploading your tracks." cancelButtonTitle:NSLocalizedString(@"No", @"") otherButtonTitles:@[NSLocalizedString(@"Yes", @"")] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex != [alertView cancelButtonIndex]) {
                [[OSVSyncController sharedInstance].tracksController uploadAllSequencesWithCompletion:^(NSError *error) {
                } partialCompletion:^(OSVMetadata *metadata, NSError *error) {
                }];
            } else {
                [OSVUserDefaults sharedInstance].isUploading = NO;
            }
        }];
    }
    
    if (([OSVReachablityController hasWiFiAccess] || [OSVReachablityController hasCellularAcces]) &&
        [OSVUserDefaults sharedInstance].automaticUpload &&
        [OSVSyncUtils hasInternetPermissions] &&
        [[OSVSyncController sharedInstance].tracksController userIsLoggedIn]) {
        [[OSVSyncController sharedInstance].tracksController uploadAllSequencesWithCompletion:^(NSError *error) {
        } partialCompletion:^(OSVMetadata *metadata, NSError *error) {
        }];
    }

    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [[OSVSyncController sharedInstance].tracksController finishUploadingEmptySequencesWithCompletionBlock:^(NSError *error) {
        }];
    });

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
//    NSLog(@"is in background");
    if ([OSVSyncController hasSequencesToUpload] && [OSVSyncController isUploading]) {
        [[OSVSyncController sharedInstance].tracksController pauseUpload];
        UIBackgroundTaskIdentifier __block bgTask = [application beginBackgroundTaskWithName:@"uploadOSVTask" expirationHandler:^{
            [application endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[OSVSyncController sharedInstance].tracksController resumeUploadWithBackgroundTask:bgTask];
        });
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[OSVSyncController sharedInstance].tracksController checkForAppUpdateWithCompletion:^(BOOL response) {
        if (response) {
            [[UIApplication sharedApplication] openURL:[[OSVSyncController sharedInstance].tracksController getAppLink]];
        }
    }];
    
    [[OSVLocationManager sharedInstance].sensorsManager startUpdatingOBD];
    if (([OSVReachablityController hasWiFiAccess] || [OSVReachablityController hasCellularAcces]) &&
        [OSVUserDefaults sharedInstance].automaticUpload &&
        [OSVSyncUtils hasInternetPermissions] &&
        [[OSVSyncController sharedInstance].tracksController userIsLoggedIn] &&
        ![OSVSyncController isUploading]) {
        [[OSVSyncController sharedInstance].tracksController uploadAllSequencesWithCompletion:^(NSError *error) {
        } partialCompletion:^(OSVMetadata *metadata, NSError *error) {
        }];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAFApplicationLaunchedWithURLNotification object:@{kAFApplicationLaunchOptionsURLKey:url}];
    
    return NO;
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    self.sessionCompletionHandler = completionHandler;
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return [window.rootViewController supportedInterfaceOrientations];
}

@end
