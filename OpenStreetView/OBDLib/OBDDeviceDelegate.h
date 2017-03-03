//
//  OBDDeviceDelegate.h
//  OBDLib
//
//  Created by BogdanB on 24/03/16.
//  Copyright © 2016 Telenav. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OBDSensors.h"

@class OBDDevice;

@protocol OBDDeviceDelegate <NSObject>

@optional

- (void)OBDDeviceDidConnect:(OBDDevice *)device;
- (void)OBDDeviceFailedToConnect:(OBDDevice *)device error:(NSError *)error;
- (void)OBDDeviceDidDisconnect:(OBDDevice *)device error:(NSError *)error;

- (void)OBDDevice:(OBDDevice *)device didUpdateInteger:(int)value forSensor:(OBDSensor)sensor;
- (void)OBDDevice:(OBDDevice *)device didUpdateDouble:(double)value forSensor:(OBDSensor)sensor;
- (void)OBDDevice:(OBDDevice *)device didUpdateString:(NSString *)string forSensor:(OBDSensor)sensor;
- (void)OBDDevice:(OBDDevice *)device didUpdateSupportedPIDs:(NSSet<NSNumber *> *)pids forSensor:(OBDSensor)sensor;
- (void)OBDDevice:(OBDDevice *)device failedToGetValueForSensor:(OBDSensor)sensor;

@end
