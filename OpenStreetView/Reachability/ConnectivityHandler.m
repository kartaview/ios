//
//  ConnectivityHandler.m
//  OpenStreetView
//
//
//  Created by Bogdan Sala on 10/17/12.
//  Copyright (c) 2012 Bogdan Sala. All rights reserved.
//

#import "ConnectivityHandler.h"

NSString* const kFMDidLooseConnectionNotification       = @"kFMDidLooseConnectionNotification";
NSString* const kFMDidEstablishConnectionNotification   = @"kFMDidEstablishConnectionNotification";
NSString* const kFMDidChangeConnectionToWWANNotification= @"kFMDidChangeConnectionToWWAN";

@implementation ConnectivityHandler

#pragma mark - Lifecycle

+ (ConnectivityHandler *)sharedInstance {
    static dispatch_once_t onceToken = 0;
    __strong static id connectivityHandler = nil;
    
    dispatch_once(&onceToken, ^{
        connectivityHandler = [[self alloc] init];
    });
    
    return connectivityHandler;
}

- (id)init {
    if (self = [super init]) {
        _reachability = [Reachability reachabilityForInternetConnection];
        [_reachability startNotifier];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChangedNotification:) name:kReachabilityChangedNotification object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [_reachability stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public methods

//the block is called on the main thread
- (void)checkInternetConnectionAsynchronousWithBlock:(void (^)(bool))block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block BOOL success = YES;
        
        Reachability *r = [Reachability reachabilityForInternetConnection];
        
        NetworkStatus internetStatus = [r currentReachabilityStatus];
        
        if ((internetStatus != ReachableViaWiFi) && (internetStatus != ReachableViaWWAN)) {
            success = NO;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            block(success);
        });
    });
}

- (BOOL)checkInternetConnectionSynchronous {
    Reachability *r = [Reachability reachabilityForInternetConnection];
    
    NetworkStatus internetStatus = [r currentReachabilityStatus];
    
    if ((internetStatus != ReachableViaWiFi) && (internetStatus != ReachableViaWWAN)) {
        return NO;
    }
    return YES;
}

- (BOOL)isConnectionViaWiFi {
    Reachability *r = [Reachability reachabilityForInternetConnection];
    
    NetworkStatus internetStatus = [r currentReachabilityStatus];
    
    if (internetStatus == ReachableViaWiFi) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isConnectionViaWWAN {
    Reachability *r = [Reachability reachabilityForInternetConnection];
    
    NetworkStatus internetStatus = [r currentReachabilityStatus];
    
    return internetStatus == ReachableViaWWAN;
}


- (NetworkStatus)connectionType {
    Reachability *r = [Reachability reachabilityForInternetConnection];
    return [r currentReachabilityStatus];
}

#pragma mark - Notification handlers

- (void)reachabilityChangedNotification:(NSNotification *)notif {
    NetworkStatus status = [_reachability currentReachabilityStatus];
    switch (status) {
        case ReachableViaWiFi:
            [[NSNotificationCenter defaultCenter] postNotificationName:kFMDidEstablishConnectionNotification object:nil];
            break;
            
        case ReachableViaWWAN:
            [[NSNotificationCenter defaultCenter] postNotificationName:kFMDidEstablishConnectionNotification object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kFMDidChangeConnectionToWWANNotification object:nil];
            break;
            
        case NotReachable:
            [[NSNotificationCenter defaultCenter] postNotificationName:kFMDidLooseConnectionNotification object:nil];
            break;
            
        default:
            break;
    }
}

@end
