//
//  ConnectivityHandler.h
//  OpenStreetView
//
//
//  Created by Bogdan Sala on 10/17/12.
//  Copyright (c) 2012 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

extern NSString *const kFMDidLooseConnectionNotification;
extern NSString *const kFMDidEstablishConnectionNotification;
extern NSString *const kFMDidChangeConnectionToWWANNotification;

@interface ConnectivityHandler : NSObject

@property (nonatomic, strong) Reachability *reachability;

+ (ConnectivityHandler *)sharedInstance;

- (BOOL)checkInternetConnectionSynchronous; //the block is called on the main thread, its bool parameter specifies if there is an internet connection or not
- (void)checkInternetConnectionAsynchronousWithBlock:(void (^)(bool))block;
- (BOOL)isConnectionViaWiFi;
- (BOOL)isConnectionViaWWAN;
- (NetworkStatus)connectionType;

@end
