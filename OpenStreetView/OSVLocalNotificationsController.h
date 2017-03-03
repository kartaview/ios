//
//  OSVLocalNotificationsController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 18/10/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSVLocalNotificationsController : NSObject

+ (void)scheduleUploadNotification;
+ (void)removeUploadNotification;

+ (void)handleNotification:(UILocalNotification *)notification application:(UIApplication *)application;

@end
