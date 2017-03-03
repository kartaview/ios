//
//  OSVLocationManager.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSVSensorsManager.h"
#import <SKMaps/SKPositionerService.h>

@protocol CLLocationManagerDelegate;
@class CLLocation;

@interface OSVLocationManager : NSObject

@property (weak, nonatomic) id<CLLocationManagerDelegate>    delegate;
@property (assign, nonatomic) BOOL                           realPositions;

@property (assign, nonatomic) SKPositionerMode              positionerMode;

+ (instancetype)sharedInstance;

- (CLLocation *)currentMatchedPosition;
- (CLLocation *)currentLocation;

- (void)startLocationUpdate;
- (void)cancelLocationUpdate;
- (void)reportGPSLocation:(CLLocation *)location;

@end

