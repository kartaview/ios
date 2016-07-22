//
//  OSVLocationManager.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSVSensorsManager.h"

@protocol CLLocationManagerDelegate;
@class CLLocation;

@interface OSVLocationManager : NSObject

@property (weak, nonatomic) id<CLLocationManagerDelegate>    delegate;
@property (assign, nonatomic) BOOL                           realPositions;
@property (strong, nonatomic) OSVSensorsManager              *sensorsManager;

@property (strong, nonatomic, readonly) CLLocation           *currentLocation;

+ (instancetype)sharedInstance;

- (void)startUpdatingLocation;
- (void)startUpdatingHeading;

@end

