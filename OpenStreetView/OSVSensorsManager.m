//
//  OSVSensorsManager.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 03/03/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import "OSVSensorsManager.h"
#import "OSVOBDController.h"
#import "OSVLogItem.h"
#import "OSVSyncController.h"
#import "OSVOBDData.h"

@interface OSVSensorsManager ()

@property (nonatomic, strong) CMMotionManager   *motionManager;
@property (nonatomic, strong) CMAltimeter       *altimeter;
@property (nonatomic, strong) OSVOBDController  *OBD;

@property (nonatomic, strong) NSOperationQueue *accelerometerQueue;
@property (nonatomic, strong) NSOperationQueue *gyroQueue;
@property (nonatomic, strong) NSOperationQueue *magnetometerQueue;
@property (nonatomic, strong) NSOperationQueue *deviceMotionQueue;
@property (nonatomic, strong) NSOperationQueue *altimeterQueue;

@property (nonatomic, assign) BOOL              shouldLog;

@end

@implementation OSVSensorsManager

- (instancetype)init {
    self = [super init];
    if (self) {
        self.accelerometerQueue = [NSOperationQueue new];
        self.gyroQueue = [NSOperationQueue new];
        self.magnetometerQueue = [NSOperationQueue new];
        self.deviceMotionQueue = [NSOperationQueue new];
        self.altimeterQueue = [NSOperationQueue new];
        
        self.motionManager = [CMMotionManager new];
        self.motionManager.accelerometerUpdateInterval = 0.1;
        self.motionManager.gyroUpdateInterval = 0.1;
        self.motionManager.magnetometerUpdateInterval = 0.1;
        self.motionManager.deviceMotionUpdateInterval = 0.1;
        
        self.OBD = [[OSVOBDController alloc] initWithHandler:^(OSVOBDData *obdData) {
            
            if ([self.delegate respondsToSelector:@selector(manager:didUpdateOBDData:withError:)]) {
                if (obdData) {
                    [self.delegate manager:self didUpdateOBDData:obdData withError:nil];
                } else {
                    [self.delegate manager:self didUpdateOBDData:obdData withError:[NSError errorWithDomain:@"OBD" code:-1 userInfo:nil]];
                }
            }
            
            if (obdData && obdData.speed != NSNotFound) {
                OSVLogItem *item = [OSVLogItem new];
                item.carSensorData = obdData;
                item.timestamp = obdData.timestamp;
                [[OSVSyncController sharedInstance].logger logItems:@[item] inFileForSequenceID:0];
            }
        }];
        
        self.altimeter = [CMAltimeter new];
    }
    return self;
}

- (void)startUpdatingAccelerometer {
    [self.motionManager startAccelerometerUpdatesToQueue:self.accelerometerQueue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
        OSVLogItem *item = [OSVLogItem new];
        item.sensorData = accelerometerData;
        item.timestamp = [[NSDate new] timeIntervalSince1970];
        if (self.shouldLog) {
            [[OSVSyncController sharedInstance].logger logItems:@[item] inFileForSequenceID:0];
        }
    }];
}

- (void)startUpdatingGyro {
    [self.motionManager startGyroUpdatesToQueue:self.gyroQueue withHandler:^(CMGyroData *gyroData, NSError *error) {
        OSVLogItem *item = [OSVLogItem new];
        item.sensorData = gyroData;
        item.timestamp = [[NSDate new] timeIntervalSince1970];
        if (self.shouldLog) {
            [[OSVSyncController sharedInstance].logger logItems:@[item] inFileForSequenceID:0];
        }
    }];
}

- (void)startUpdatingMagnetometer {
    [self.motionManager startMagnetometerUpdatesToQueue:self.magnetometerQueue withHandler:^(CMMagnetometerData * magnetometerData, NSError *error) {
        OSVLogItem *item = [OSVLogItem new];
        item.sensorData = magnetometerData;
        item.timestamp = [[NSDate new] timeIntervalSince1970];
        if (self.shouldLog) {
            [[OSVSyncController sharedInstance].logger logItems:@[item] inFileForSequenceID:0];
        }
    }];
}

- (void)startUpdatingAltitude {
    [self.altimeter startRelativeAltitudeUpdatesToQueue:self.altimeterQueue withHandler:^(CMAltitudeData *altitudeData, NSError *error) {
        OSVLogItem *item = [OSVLogItem new];
        item.sensorData = altitudeData;
        item.timestamp = [[NSDate new] timeIntervalSince1970];
        if (self.shouldLog) {
            [[OSVSyncController sharedInstance].logger logItems:@[item] inFileForSequenceID:0];
        }
    }];
}

- (void)startUpdatingDeviceMotion {
    self.OBD.isRecordingMode = YES;
    [self.motionManager  startDeviceMotionUpdatesToQueue:self.altimeterQueue withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
        OSVLogItem *item = [OSVLogItem new];
        item.sensorData = motion;
        item.timestamp = [[NSDate new] timeIntervalSince1970];
        if (self.shouldLog) {
            [[OSVSyncController sharedInstance].logger logItems:@[item] inFileForSequenceID:0];
        }
    }];
}

- (void)startUpdatingOBD {
    [self.OBD startOBDUpdates];
}

- (void)startBLEOBDScan {
    [self.OBD scanBLEOBD];
}

- (void)stopUpdatingAccelerometer {
    [self.motionManager stopAccelerometerUpdates];
}

- (void)stopUpdatingGyro {
    [self.motionManager stopGyroUpdates];
}

- (void)stopUpdatingMagnetometer {
    [self.motionManager stopMagnetometerUpdates];
}

- (void)stopUpdatingAltitude {
    [self.altimeter stopRelativeAltitudeUpdates];
}

- (void)stopUpdatingDeviceMotion {
    self.OBD.isRecordingMode = NO;
    [self.motionManager stopDeviceMotionUpdates];
}

- (void)stopUpdatingOBD {
    [self.OBD stopOBDUpdates];
}

- (void)startLoggingSensors {
    self.shouldLog = YES;
}

- (void)stopLoggingSensors {
    self.shouldLog = NO;
}

- (void)reconnectOBD {
    [self.OBD reconnect];
}

@end
