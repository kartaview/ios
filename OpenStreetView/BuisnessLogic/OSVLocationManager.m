//
//  OSVLocationManager.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVLocationManager.h"
#import <CoreLocation/CoreLocation.h>
#import <SKMaps/SKPositionerService.h>
#import "OSVUtils.h"

#import "OSVUserDefaults.h"
#import "OSVSyncController.h"

@interface OSVLocationManager () <CLLocationManagerDelegate, SKPositionerServiceDelegate>

@property (nonatomic, strong) CLLocation *firstLocation;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation OSVLocationManager

+ (instancetype)sharedInstance {
    static id sharedInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.realPositions = [OSVUserDefaults sharedInstance].realPositions;
        if ([OSVUserDefaults sharedInstance].enableMap) {
            [SKPositionerService sharedInstance].delegate = self;
        } else {
            self.locationManager = [CLLocationManager new];
            self.locationManager.delegate = self;
        }
    }
    
    return self;
}

- (void)positionerService:(SKPositionerService *)positionerService updatedCurrentLocation:(CLLocation *)currentLocation {
    if (!self.realPositions) {
        return;
    }
    

    [self sendLocationToDelegate:@[currentLocation]];
}

- (void)positionerService:(SKPositionerService *)positionerService updatedCurrentHeading:(CLHeading *)currentHeading {
    OSVLogItem *item = [OSVLogItem new];
    item.heading = currentHeading;
    [[OSVSyncController sharedInstance].logger logItem:item];
}

- (void)positionerService:(SKPositionerService *)positionerService changedGPSAccuracyToLevel:(SKGPSAccuracyLevel)level {

}

- (void)positionerService:(SKPositionerService *)positionerService didFailWithError:(NSError *)error {

}

- (void)positionerService:(SKPositionerService *)positionerService didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didChangeAuthorizationStatus" object:nil userInfo:@{@"status":@(status)}];
}

- (void)positionerService:(SKPositionerService *)positionerService didRetrieveElevation:(float)elevation atCoordinate:(CLLocationCoordinate2D)coordinate {

}

- (void)positionerService:(SKPositionerService *)positionerService didFailToRetrieveElevationAtCoordinate:(CLLocationCoordinate2D)coordinate {

}

#pragma mark - CllocationDelegate 

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)newLocationArray {
    [self sendLocationToDelegate:newLocationArray];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    OSVLogItem *item = [OSVLogItem new];
    item.heading = newHeading;
    [[OSVSyncController sharedInstance].logger logItem:item];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status  {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didChangeAuthorizationStatus" object:nil userInfo:@{@"status":@(status)}];
}
#pragma mark - Public 

- (void)setRealPositions:(BOOL)realPositions {
    _realPositions = realPositions;
}

- (CLLocation *)currentMatchedPosition {
    if ([OSVUserDefaults sharedInstance].enableMap) {
        SKPosition matchedPosition = [SKPositionerService sharedInstance].currentMatchedPosition;
        return [[CLLocation alloc] initWithLatitude:matchedPosition.latY longitude:matchedPosition.lonX];
    } else {
        return self.locationManager.location;
    }
}

- (CLLocation *)currentLocation {
    if ([OSVUserDefaults sharedInstance].enableMap) {
        CLLocationCoordinate2D coordinate = [SKPositionerService sharedInstance].currentCoordinate;
        return [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    } else {
        return self.locationManager.location;
    }
}

- (void)startLocationUpdate {
    if ([OSVUserDefaults sharedInstance].enableMap) {
        [[SKPositionerService sharedInstance] startLocationUpdate];
    } else {
        [self.locationManager startUpdatingLocation];
    }
}

- (void)cancelLocationUpdate {
    if ([OSVUserDefaults sharedInstance].enableMap) {
        [[SKPositionerService sharedInstance] cancelLocationUpdate];
    } else {
        [self.locationManager stopUpdatingLocation];
    }
}

- (void)setPositionerMode:(SKPositionerMode)positionerMode {
    if ([OSVUserDefaults sharedInstance].enableMap) {
        [[SKPositionerService sharedInstance] setPositionerMode:positionerMode];
    }
}

- (void)reportGPSLocation:(CLLocation *)location {
    if ([OSVUserDefaults sharedInstance].enableMap) {
        [[SKPositionerService sharedInstance] reportGPSLocation:location];
    }
}

- (void)sendLocationToDelegate:(NSArray *)currentLocations {
    CLLocation *currentLocation = currentLocations.lastObject;

    if (!self.firstLocation &&
        currentLocation.coordinate.latitude != 0.0 &&
        currentLocation.coordinate.longitude != 0.0) {
        self.firstLocation = currentLocation;
        if ([OSVUserDefaults sharedInstance].automaticDistanceUnitSystem) {
            [OSVUserDefaults sharedInstance].distanceUnitSystem = [OSVUtils isUSCoordinate:currentLocation.coordinate] ? kImperialSystem : kMetricSystem;
        }
    }
    
    NSInteger debugLocationAccuracy = [OSVUserDefaults sharedInstance].debugLocationAccuracy;
    if (debugLocationAccuracy) {
        CLLocation *debugLocation = nil;
        switch (debugLocationAccuracy ) {
            case 1: //high
                debugLocation = [[CLLocation alloc] initWithCoordinate:currentLocation.coordinate
                                                              altitude:currentLocation.altitude
                                                    horizontalAccuracy:5
                                                      verticalAccuracy:currentLocation.verticalAccuracy
                                                             timestamp:currentLocation.timestamp];
                
                break;
            case 2: // medium
                debugLocation = [[CLLocation alloc] initWithCoordinate:currentLocation.coordinate
                                                              altitude:currentLocation.altitude
                                                    horizontalAccuracy:30
                                                      verticalAccuracy:currentLocation.verticalAccuracy
                                                             timestamp:currentLocation.timestamp];
                
                break;
            case 3: // low
                debugLocation = [[CLLocation alloc] initWithCoordinate:currentLocation.coordinate
                                                              altitude:currentLocation.altitude
                                                    horizontalAccuracy:50
                                                      verticalAccuracy:currentLocation.verticalAccuracy
                                                             timestamp:currentLocation.timestamp];
                
                break;
            default: // non debug
				debugLocation = currentLocation;
                break;
        }
        [self.delegate locationManager:(CLLocationManager *)self didUpdateLocations:@[debugLocation]];
        
    } else {
        [self.delegate locationManager:(CLLocationManager *)self didUpdateLocations:@[currentLocation]];
    }
}

@end
