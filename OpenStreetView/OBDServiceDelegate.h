//
//  OBDServiceDelegate.h
//  OBDLib
//
//  Created by BogdanB on 24/03/16.
//  Copyright © 2016 Telenav. All rights reserved.
//

#import "OBDSensors.h"

typedef NS_ENUM(NSInteger, OBDConnectionType) {
    OBDConnectionTypeBluetoothLE = 1,
};

@class OBDService;
@class OBDDevice;

@protocol OBDServiceDelegate <NSObject>

@optional

- (void)OBDService:(OBDService *)service didDidFindDevice:(OBDDevice *)device;
- (void)OBDService:(OBDService *)service unableToSearchForDevicesOnConnection:(OBDConnectionType)connection;

@end