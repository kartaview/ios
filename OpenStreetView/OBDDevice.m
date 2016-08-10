//
//  OBDDevice.m
//  OBDLib
//
//  Created by BogdanB on 24/03/16.
//  Copyright © 2016 Telenav. All rights reserved.
//

#import "OBDDevice.h"
#import "OBDDevice+Internal.h"
#import "OBDUtils.h"

static NSString* const kServiceID = @"FFE0";
static NSString* const kCharacteristicID = @"FFE1";

@interface OBDDevice () <CBPeripheralDelegate>

@property (nonatomic, strong) CBPeripheral *internalPeripheral;
@property (nonatomic, strong) CBCentralManager *internalManager;
@property (nonatomic, strong) NSMutableArray *pendingRequests;
@property (nonatomic, strong) CBService *obdService;
@property (nonatomic, strong) CBCharacteristic *obdCharacteristic;
@property (nonatomic, strong) NSMutableData *responseData;

@end

@implementation OBDDevice

@synthesize name = _name;
@synthesize UUID = _UUID;
@synthesize connected = _connected;

- (id)initWithPeripheral:(CBPeripheral *)peripheral centralManager:(CBCentralManager *)manager {
    self = [super init];
    if (self) {
        self.peripheral = peripheral;
        self.internalManager = manager;
        self.pendingRequests = [NSMutableArray array];
    }

    return self;
}

- (NSString *)name {
    return _name;
}

- (NSString *)UUID {
    return _UUID;
}

- (void)setPeripheral:(CBPeripheral *)peripheral {
    self.internalPeripheral = peripheral;
    self.internalPeripheral.delegate = self;
    _name = peripheral.name;
    _UUID = peripheral.identifier.UUIDString;
}

- (CBPeripheral *)peripheral {
    return self.internalPeripheral;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"name = %@ UUID = %@", self.name, self.UUID];
}

- (BOOL)isConnected {
    @synchronized (self) {
        return _connected;
    }
}

#pragma mark - Public methods

- (void)connect {
    @synchronized (self) {
        self.obdCharacteristic = nil;
        self.obdService = nil;
        _connected = NO;
        [self.pendingRequests removeAllObjects];
        self.responseData = nil;

        [self.internalManager connectPeripheral:self.internalPeripheral options:nil];
    }
}

- (void)disconnect {
    @synchronized (self) {
        [self.internalManager cancelPeripheralConnection:self.internalPeripheral];
        self.obdCharacteristic = nil;
        self.obdService = nil;
        _connected = NO;
    }
}

- (void)getValueForSensor:(OBDSensor)sensor {
    @synchronized (self) {
        if (!_connected) {
            return;
        }

        [self.pendingRequests addObject:@(sensor)];

        //check if we got a response pending
        if (!self.responseData) {
            [self requestValueForSensor:sensor];
        }
    }
}

- (void)requestValueForSensor:(OBDSensor)sensor {
    @synchronized (self) {
        if (!_connected) {
            return;
        }

        self.responseData = [NSMutableData data];
        char buffer[5];
        snprintf(buffer, 5, "%04X", sensor);
        buffer[4] = '\r';
        [self.internalPeripheral writeValue:[NSData dataWithBytes:buffer length:5] forCharacteristic:self.obdCharacteristic type:CBCharacteristicWriteWithResponse];
    }
}

#pragma mark - CBPeripheralDelegate methods

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    @synchronized (self) {
        //check if the required service has been found
        for (CBService *service in peripheral.services) {
            if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceID]]) {
                self.obdService = service;
                break;
            }
        }

        if (self.obdService) {
            [self.internalPeripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kCharacteristicID]] forService:self.obdService];
        } else {
            NSError *e = error;
            if (!e) {
                e = [NSError errorWithDomain:@"OBDService" code:1 userInfo:nil];
            }
            if ([self.delegate respondsToSelector:@selector(OBDDeviceFailedToConnect:error:)]) {
                [self.delegate OBDDeviceFailedToConnect:self error:e];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    @synchronized (self) {
        if (service != self.obdService) {
            return;
        }

        //find the obd characteristic
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicID]]) {
                self.obdCharacteristic = characteristic;
                [self.internalPeripheral setNotifyValue:YES forCharacteristic:self.obdCharacteristic];
                break;
            }
        }

        if (!self.obdCharacteristic) {
            NSError *e = error;
            if (!e) {
                e = [NSError errorWithDomain:@"OBDService" code:2 userInfo:nil];
            }
            if ([self.delegate respondsToSelector:@selector(OBDDeviceFailedToConnect:error:)]) {
                [self.delegate OBDDeviceFailedToConnect:self error:e];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    @synchronized (self) {
        if(!self.responseData) {
            return;
        }

        [self.responseData appendData:characteristic.value];

        //check for end of message
        if (strstr(self.responseData.bytes, "\r>")) {
            [self.responseData appendBytes:"\0" length:1];
            if (self.pendingRequests.count > 0) {
                [self processResponse];
                [self.pendingRequests removeObjectAtIndex:0];
            } else {
                NSLog(@"No requests for this response %s", self.responseData.bytes);
            }
            //        NSLog(@"response = %s", self.responseData.bytes);
            self.responseData = nil;
            if (self.pendingRequests.count > 0) {
                [self requestValueForSensor:[self.pendingRequests[0] intValue]];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    @synchronized (self) {
        if (characteristic == self.obdCharacteristic && characteristic.isNotifying && !self.isConnected) {
            _connected = YES;
            if ([self.delegate respondsToSelector:@selector(OBDDeviceDidConnect:)]) {
                [self.delegate OBDDeviceDidConnect:self];
            }
        }
    }
}

#pragma mark - Internal methods

- (void)handleConnectionSuccess {
    [self.internalPeripheral discoverServices:@[[CBUUID UUIDWithString:kServiceID]]];
}

- (void)handleConnectionFailure:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(OBDDeviceFailedToConnect:error:)]) {
        [self.delegate OBDDeviceFailedToConnect:self error:error];
    }
}

- (void)handleDisconnection:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(OBDDeviceDidDisconnect:error:)]) {
        [self.delegate OBDDeviceDidDisconnect:self error:error];
    }

    if (error.code == CBErrorConnectionTimeout) {
        [self connect];
    }
}

//processes the response of the current request in the stack. this is done after all the messages for a request have been received
- (void)processResponse {
    if (self.pendingRequests.count == 0) {
        NSLog(@"got response without any request");
        return;
    }
    OBDSensor sensor = (OBDSensor)[self.pendingRequests[0] intValue];

    BOOL parseSucceed = false;
    switch (sensor) {
        case OBDSensorEngineRPM: {
            int rpm = 0;
            if ((parseSucceed = [OBDUtils getRPM:&rpm fromData:self.responseData]) && [self.delegate respondsToSelector:@selector(OBDDevice:didUpdateInteger:forSensor:)]) {
                [self.delegate OBDDevice:self didUpdateInteger:rpm forSensor:sensor];
            }
        }
            break;

        case OBDSensorVehicleSpeed: {
            int speed = 0;
            if ((parseSucceed = [OBDUtils getSpeed:&speed fromData:self.responseData]) && [self.delegate respondsToSelector:@selector(OBDDevice:didUpdateInteger:forSensor:)]) {
                [self.delegate OBDDevice:self didUpdateInteger:speed forSensor:sensor];
            }
        }
            break;

        default:
            NSLog(@"got response for unsupported sensor");
            break;
    }

    if (!parseSucceed && [self.delegate respondsToSelector:@selector(OBDDevice:failedToGetValueForSensor:)]) {
        [self.delegate OBDDevice:self failedToGetValueForSensor:sensor];
    }
}

@end
