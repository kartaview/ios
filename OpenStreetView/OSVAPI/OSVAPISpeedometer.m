//
//  OSVAPISpeedometer.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 12/02/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVAPISpeedometer.h"

@interface OSVAPISpeedometer ()

@property (nonatomic, strong) NSTimer           *uploadSpeedTimer;
@property (nonatomic, strong) NSMutableArray    *uploadSpeeds;

@end

@implementation OSVAPISpeedometer

const float kUploadSpeedSamplingInterval = 1;
const int kUnitBytesSize = 1024;
const int kDownloadSpeedsMaxCount = 50;


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.uploadSpeeds = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Public

- (void)startSpeedCalculationTimer {
    
    if (!self.uploadSpeedTimer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.uploadSpeedTimer = [NSTimer scheduledTimerWithTimeInterval:kUploadSpeedSamplingInterval target:self
                                                                   selector:@selector(calculateUploadSpeed) userInfo:nil
                                                                    repeats:YES];
        });
    }
}

- (void)cancelSpeedCalculationTimer {
    if (self.uploadSpeedTimer) {
        [self.uploadSpeedTimer invalidate];
        self.uploadSpeedTimer = nil;
    }
}

#pragma mark - Private

- (void)calculateUploadSpeed {
    
    //Calculate current speed.
    long long kB = self.bytesInLastSample / kUnitBytesSize;
    double samplingRate = 1 / kUploadSpeedSamplingInterval;
    double speed = kB * samplingRate;
    
    //Add current speed to history.
    [self.uploadSpeeds addObject:[NSNumber numberWithDouble:speed]];
    
    //Delete oldest speed, if it is necessary.
    if ([self.uploadSpeeds count] > kDownloadSpeedsMaxCount) {
        [self.uploadSpeeds removeObjectAtIndex:0];
    }
    
    //Calculate average speed.
    double averageSpeed = 0;
    for (int i = 0; i < [self.uploadSpeeds count]; i++) {
        averageSpeed += [[self.uploadSpeeds objectAtIndex:i] doubleValue];
    }
    averageSpeed /= [self.uploadSpeeds count];
    
    self.latestAverageSpeed = averageSpeed;
    
    self.bytesInLastSample = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kDidChangeSpeed" object:nil userInfo:@{@"kLatestSpeed":@(self.latestAverageSpeed)}];
}

@end
