//
//  OSVAPISpeedometer.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 12/02/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSVAPISpeedometer : NSObject

@property (nonatomic, assign) double        latestAverageSpeed;
@property (nonatomic, assign) long long     bytesInLastSample;

- (void)startSpeedCalculationTimer;
- (void)cancelSpeedCalculationTimer;

@end
