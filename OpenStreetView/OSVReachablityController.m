//
//  OSVReachablilityController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 14/12/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OSVReachablityController.h"
#import "Reachability.h"

@implementation OSVReachablityController

+ (BOOL)checkReachablility {
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [reachability currentReachabilityStatus];
    
    if (status == ReachableViaWiFi || status == ReachableViaWWAN) {
        return YES;
    } else {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No internet Connection", nil) message:NSLocalizedString(@"Please connect to the internet" , nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil] show];
        
        return NO;
    }
}

+ (BOOL)hasWiFiAccess {
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [reachability currentReachabilityStatus];
    
    return status == ReachableViaWiFi;
}

+ (BOOL)hasCellularAcces {
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [reachability currentReachabilityStatus];
    
    return status == ReachableViaWWAN;
}

@end
