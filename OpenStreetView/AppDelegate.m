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
#import <GoogleSignIn/GoogleSignIn.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <UIKit/UIKit.h>

#import "OSVLocationManager.h"

#import "OSVSyncController.h"

#import "OSVUserDefaults.h"

#import "UIAlertView+Blocks.h"
#import "OSVReachablityController.h"
#import "OSVLocalNotificationsController.h"

#import "OSVUser.h"

#import "OSVUtils.h"

@interface AppDelegate () <GIDSignInDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    UILocalNotification *localNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    
    if (localNotification) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [OSVLocalNotificationsController handleNotification:localNotification application:application];
        });
    }

    [Fabric with:@[[Crashlytics class]]];
    NSString *username = [OSVSyncController sharedInstance].tracksController.oscUser.name;
    if (username) {
        [CrashlyticsKit setUserName:username];
    }
    
    [[OSVSyncController sharedInstance].tracksController checkForAppUpdateWithCompletion:^(BOOL response) {
        if (response) {
            [[UIApplication sharedApplication] openURL:[[OSVSyncController sharedInstance].tracksController getAppLink]];
        }
    }];
    
    if ([OSVUserDefaults sharedInstance].enableMap) {
        SKMapsInitSettings *mapsettings = [SKMapsInitSettings mapsInitSettings];
        mapsettings.mapStyle.resourcesFolderName = @"GrayscaleStyle";
        mapsettings.mapStyle.styleFileName = @"grayscalestyle.json";
        if ([OSVUtils isHighDensity]) {
        } else {
        }
        
        [[SKMapsService sharedInstance] initializeSKMapsWithAPIKey:@"" settings:mapsettings];
        [SKMapsService sharedInstance].tilesCacheManager.cacheLimit = 100 * 1024 * 1024;
    }
    
    [[OSVSensorsManager sharedInstance] startUpdatingOBD];

    if ([CLLocationManager authorizationStatus] !=  kCLAuthorizationStatusNotDetermined) {
        [[OSVLocationManager sharedInstance] startLocationUpdate];
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
    
    [GIDSignIn sharedInstance].clientID = kOSCGoogleClientID;
    [GIDSignIn sharedInstance].delegate = self;
	
	if ([[GIDSignIn sharedInstance] hasAuthInKeychain]) {
		[[GIDSignIn sharedInstance] signInSilently];
	}
    
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [OSVLocalNotificationsController handleNotification:notification application:application];
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
    
    [[OSVSensorsManager sharedInstance] startUpdatingOBD];
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

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [self handleOpenURL:url forApplication:application
             sourceApplication:sourceApplication annotation:annotation];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
	return [self handleOpenURL:url	forApplication:app
			 sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
					annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    self.sessionCompletionHandler = completionHandler;
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return [window.rootViewController supportedInterfaceOrientations];
}
    
#pragma mark - GIDSignInDelegate
    
- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
	
	if (user) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"kOSVGoogleSignIn" object:nil userInfo:@{@"user":user}];
	}
}
	
#pragma mark - URL handle

- (BOOL)handleOpenURL:(NSURL *)url forApplication:(UIApplication *)application sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAFApplicationLaunchedWithURLNotification object:@{kAFApplicationLaunchOptionsURLKey:url}];
    
    BOOL facebookHandled = [[FBSDKApplicationDelegate sharedInstance] application:application
                                                                          openURL:url
                                                                sourceApplication:sourceApplication
                                                                       annotation:annotation];
    BOOL googleHandled = [[GIDSignIn sharedInstance] handleURL:url
                                             sourceApplication:sourceApplication
                                                    annotation:annotation];
	BOOL osmHandled = [url.absoluteString containsString:@"osmlogin"];
	
    return facebookHandled||googleHandled||osmHandled;
}
    
@end
