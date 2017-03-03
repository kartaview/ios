//
//  OSVAPIDefaultConfigurator.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 07/01/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVAPIConfigurator.h"

#define kAPIVersion             @"1.0/"

#define kProductionBaseURLOSC           @"http://openstreetcam.org"
#define kTstBaseURLOSC                  @"http://testing.openstreetcam.org"
#define kStagingBaseURLOSC              @"http://staging.openstreetcam.org"

@implementation OSVAPIConfigurator

- (nonnull NSString *)osvBaseURL {
    return kProductionBaseURLOSC;
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

+ (nonnull NSString *)testingEnvironment {
	return kTstBaseURLOSC;
}

+ (nonnull NSString *)stagingEnvironment {
	return kStagingBaseURLOSC;
}

+ (nonnull NSString *)productionEnvironment {
	return kProductionBaseURLOSC;
}


@end
