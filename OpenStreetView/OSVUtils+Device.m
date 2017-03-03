//
//  OSVUtils+Device.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 22/09/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVUtils.h"
#import <UIKit/UIKit.h>

@implementation OSVUtils (Device)

+ (BOOL)isHighDensity {
    CGFloat scale = [UIScreen mainScreen].scale;
    if (scale > 2.9) {
        return YES;
    }

    return NO;
}


@end
