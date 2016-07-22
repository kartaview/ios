//
//  OSVSensorLibManager.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 07/07/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

@interface OSVSensorLibManager : NSObject

@property (strong, nonatomic) UIImage *debugFrame;

@property (assign, atomic) BOOL isProcessing;

+ (instancetype)sharedInstance;

- (void)speedLimitsFromSampleBuffer:(CMSampleBufferRef)sampleBuffer withCompletion:(void (^)(NSArray *))completion;

- (UIImage *)imageForSpeedLimit:(NSString *)speedLimit;

@end
