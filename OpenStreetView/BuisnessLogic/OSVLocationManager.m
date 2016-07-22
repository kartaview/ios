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

@interface OSVLocationManager () <CLLocationManagerDelegate,SKPositionerServiceDelegate>

@property (nonatomic, strong) CLLocation *currentLocation;

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
        [SKPositionerService sharedInstance].delegate = self;

        self.sensorsManager = [OSVSensorsManager new];
    }
    
    return self;
}

- (void)positionerService:(SKPositionerService *)positionerService updatedCurrentLocation:(CLLocation *)currentLocation {
    if (!self.realPositions) {
        return;
    }
    
    if (!self.currentLocation) {
        if ([OSVUserDefaults sharedInstance].automaticDistanceUnitSystem) {
            [OSVUserDefaults sharedInstance].distanceUnitSystem = [OSVUtils isUSCoordinate:currentLocation.coordinate] ? kImperialSystem : kMetricSystem;
        }
        self.currentLocation = currentLocation;
    }
    
    [self.delegate locationManager:(CLLocationManager *)self didUpdateLocations:@[currentLocation]];
    
    self.currentLocation = currentLocation;
}

- (void)positionerService:(SKPositionerService *)positionerService updatedCurrentHeading:(CLHeading *)currentHeading {
    OSVLogItem *item = [OSVLogItem new];
    item.heading = currentHeading;
    item.timestamp = [[NSDate new] timeIntervalSince1970];
    [[OSVSyncController sharedInstance].logger logItems:@[item] inFileForSequenceID:0];
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

#pragma mark - Public 

- (void)startUpdatingLocation {
    [self refreshSimulationDelegate];
}

- (void)startUpdatingHeading {
    [self refreshSimulationDelegate];
}

- (void)setRealPositions:(BOOL)realPositions {
    _realPositions = realPositions;
    [self refreshSimulationDelegate];
}

- (void)refreshSimulationDelegate {

}

@end
