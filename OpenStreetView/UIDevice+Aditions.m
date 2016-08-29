//
//  UIDevice+Aditions.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 16/02/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "UIDevice+Aditions.h"
#import <CommonCrypto/CommonDigest.h>
#import <ifaddrs.h>
#import <arpa/inet.h>

#import <sys/types.h>
#import <sys/sysctl.h>
#import <Foundation/Foundation.h>

#include <sys/socket.h> // Per msqr
#include <net/if.h>
#include <net/if_dl.h>

@implementation UIDevice (Aditions)

static NSString *deviceModel = nil;
static NSString *result = nil;

+ (NSString *)modelString {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *answer = (char *)malloc(size);
        sysctlbyname("hw.machine", answer, &size, NULL, 0);
        result = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
        free(answer);
        
        NSDictionary *dictionary = @{
                                     @"iPhone1,1" : @"iPhone2G",
                                     @"iPhone1,2" : @"iPhone3G",
                                     @"iPhone2,1" : @"iPhone3GS",
                                     @"iPhone3,1" : @"iPhone4G",
                                     @"iPhone3,3" : @"iPhone4G",
                                     @"iPhone4,1" : @"iPhone4S",
                                     @"iPhone5,1" : @"iPhone5",
                                     @"iPhone5,2" : @"iPhone5",
                                     @"iPhone5,3" : @"iPhone5C",
                                     @"iPhone5,4" : @"iPhone5C",
                                     @"iPhone5,5" : @"iPhone5C",
                                     @"iPhone6,1" : @"iPhone5S",
                                     @"iPhone6,2" : @"iPhone5S",
                                     @"iPhone7,1" : @"iPhone6Plus",
                                     @"iPhone7,2" : @"iPhone6",
                                     @"iPhone8,1" : @"iPhone6S",
                                     @"iPhone8,2" : @"iPhone6SPlus",
                                     @"iPad1,1" : @"iPad",
                                     @"iPad2,1" : @"iPad2",
                                     @"iPad2,2" : @"iPad2",
                                     @"iPad2,3" : @"iPad2",
                                     @"iPad2,4" : @"iPad2",
                                     @"iPad2,5" : @"iPadMini",
                                     @"iPad2,6" : @"iPadMini",
                                     @"iPad2,7" : @"iPadMini",
                                     @"iPad4,4" : @"iPadMini2",
                                     @"iPad4,5" : @"iPadMini2",
                                     @"iPad4,7" : @"iPadMini3",
                                     @"iPad4,8" : @"iPadMini3",
                                     @"iPad4,9" : @"iPadMini3",
                                     @"iPad5,1" : @"iPadMini4",
                                     @"iPad5,2" : @"iPadMini4",
                                     @"iPad6,7" : @"iPadPro",
                                     @"iPad6,8" : @"iPadPro",
                                     @"iPad3,1" : @"iPad3",
                                     @"iPad3,2" : @"iPad3",
                                     @"iPad3,3" : @"iPad3",
                                     @"iPad3,4" : @"iPad4",
                                     @"iPad3,5" : @"iPad4",
                                     @"iPad3,6" : @"iPad4",
                                     @"iPad4,1" : @"iPadAir",
                                     @"iPad4,2" : @"iPadAir",
                                     @"iPad5,3" : @"iPadAir2",
                                     @"iPad5,4" : @"iPadAir2",
                                     @"iPod1,1" : @"iPod1G",
                                     @"iPod2,1" : @"iPod2G",
                                     @"iPod3,1" : @"iPod3G",
                                     @"iPod4,1" : @"iPod4G",
                                     @"iPod5,1" : @"iPod5G",
                                     @"iPod7,1" : @"iPod6G",
                                     @"86" : @"iPhoneSimulator",
                                     @"x86_64" : @"iPhoneSimulator"
                                     };
        
        deviceModel = [dictionary objectForKey:result];
        if (!deviceModel) {
            deviceModel = @"unknown";
        }
    });
    
    return deviceModel;
}

+ (NSString *)osVersion {
    return [[UIDevice currentDevice] systemVersion];
}

+ (BOOL)isLessTheniPhone6 {
    [self modelString];
    if ([result containsString:@"iPhone"]) {
        NSString *deviceModelNumb = [result stringByReplacingOccurrencesOfString:@"iPhone" withString:@""];
        deviceModelNumb = [deviceModelNumb stringByReplacingOccurrencesOfString:@"," withString:@"."];
        double value = [deviceModelNumb doubleValue];
        return value < 7;
    }
    
    return YES;
}

@end
