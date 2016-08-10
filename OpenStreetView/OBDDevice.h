//
//  OBDDevice.h
//  OBDLib
//
//  Created by BogdanB on 24/03/16.
//  Copyright © 2016 Telenav. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OBDDeviceDelegate.h"
#import "OBDSensors.h"

@interface OBDDevice : NSObject

@property (atomic, weak) id<OBDDeviceDelegate> delegate;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *UUID;
@property (readonly, getter = isConnected) BOOL connected;

- (void)connect;
- (void)disconnect;

- (void)getValueForSensor:(OBDSensor)sensor;

@end
