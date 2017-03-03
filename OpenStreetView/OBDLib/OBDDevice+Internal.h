//
//  OBDDevice_Internal.h
//  OBDLib
//
//  Created by BogdanB on 05/04/16.
//  Copyright © 2016 Telenav. All rights reserved.
//

#import "OBDDevice.h"

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface OBDDevice (Internal)

@property (nonatomic, strong) CBPeripheral *peripheral;

- (id)initWithPeripheral:(CBPeripheral *)peripheral centralManager:(CBCentralManager *)manager;
- (void)handleConnectionSuccess;
- (void)handleConnectionFailure:(NSError *)error;
- (void)handleDisconnection:(NSError *)error;

@end
