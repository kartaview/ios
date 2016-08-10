//
//  OSVAPIDefaultConfigurator.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 07/01/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVAPIConfigurator.h"

//#ifdef ENABLED_DEBUG
////#define kBaseURLOSV             @"http://openstreetview.com"
////#define kBaseURLOSV             @"http://testing.openstreetview.com"
//#define kBaseURLOSV             @"http://staging.openstreetview.com"
//#else
#define kBaseURLOSV             @"http://openstreetview.com"
//#define kBaseURLOSV             @"http://staging.openstreetview.com"
//#endif

#define kAPIVersion             @"1.0/"
//#define kAPIVersion             @""

@implementation OSVAPIConfigurator

- (nonnull NSString *)osvBaseURL {
    return kBaseURLOSV;
}

- (nonnull NSString *)osvAPIVerion {
    return kAPIVersion;
}

- (nonnull NSString *)platformName {
    return @"iOS";
}

- (nonnull NSString *)platformVersion {
    return @"unknown";
}

- (nonnull NSString *)appVersion {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

@end
