//
//  OSVLocalNotificationsController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 18/10/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OSVLocalNotificationsController.h"

@implementation OSVLocalNotificationsController

+ (void)scheduleUploadNotification {
    UIUserNotificationType types = (UIUserNotificationType) (UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert);
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    
    [self removeUploadNotification];
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    
    NSDate *today = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [gregorian setLocale:[NSLocale currentLocale]];
    
    NSDateComponents *nowComponents = [gregorian components: NSCalendarUnitMonth |NSCalendarUnitYear | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:today];
    
    [nowComponents setHour:19]; 
    [nowComponents setMinute:0];
    
    NSDate *fireDate = [gregorian dateFromComponents:nowComponents];
    
    if ([today compare:fireDate] == NSOrderedDescending) {
        fireDate = [fireDate dateByAddingTimeInterval:3600 * 24];
    }
    
    localNotification.fireDate = fireDate;
	if ([localNotification respondsToSelector:@selector(alertTitle)]) {
		localNotification.alertTitle = NSLocalizedString(@"Upload", @"");
	}
    localNotification.alertBody = NSLocalizedString(@"Hey, it seems that you have local recordings on your phone. Don't forget to upload your photos!", @"");
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

+ (void)removeUploadNotification {
    NSArray *arrayOfLocalNotifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    
    for (UILocalNotification *localNotification in arrayOfLocalNotifications) {
        
        if ([localNotification.alertBody isEqualToString:NSLocalizedString(@"Hey, it seems that you have local recordings on your phone. Don't forget to upload your photos!", @"")]) {
            [[UIApplication sharedApplication] cancelLocalNotification:localNotification];
        }
    }
}

+ (void)handleNotification:(UILocalNotification *)notification application:(UIApplication *)application {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kShowUploadScreen" object:nil];
}


@end
