//
//  OSVSensorsManager.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 03/03/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OSVOBDData;
@protocol OSVSensorsManagerDelegate;

@interface OSVSensorsManager : NSObject

@property (weak, nonatomic) id<OSVSensorsManagerDelegate>   delegate;

+ (instancetype)sharedInstance;

- (void)startAllSensors;
- (void)stopAllSensors;

- (void)startLoggingSensors;
- (void)stopLoggingSensors;

- (void)startUpdatingAccelerometer;
- (void)startUpdatingGyro;
- (void)startUpdatingMagnetometer;
- (void)startUpdatingAltitude;

- (void)startUpdatingOBD;
- (void)reconnectOBD;
- (void)startBLEOBDScan;

- (void)startUpdatingDeviceMotion;

- (void)stopUpdatingAccelerometer;
- (void)stopUpdatingGyro;
- (void)stopUpdatingMagnetometer;
- (void)stopUpdatingAltitude;

- (void)stopUpdatingOBD;

- (void)stopUpdatingDeviceMotion;

@end

@protocol OSVSensorsManagerDelegate <NSObject>

- (void)manager:(OSVSensorsManager *)manager didUpdateOBDData:(OSVOBDData *)data withError:(NSError *)error;

@end
