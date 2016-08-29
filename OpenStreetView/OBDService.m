//
//  OBDService.m
//  OBDLib
//
//  Created by BogdanB on 24/03/16.
//  Copyright © 2016 Telenav. All rights reserved.
//

#import "OBDService.h"

#import <CoreBluetooth/CoreBluetooth.h>

#import "OBDDevice.h"
#import "OBDDevice+Internal.h"

static NSString * const kCentralManagerRestorationID = @"OBDLibCentralManagerID";

@interface OBDService () <CBCentralManagerDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) dispatch_queue_t bluethoothQueue;

@property (nonatomic, strong) NSMutableArray<OBDDevice *> *devices;

@property (atomic, assign) BOOL searchPending;

@end

@implementation OBDService

+ (instancetype)sharedInstance {
    static OBDService *instance;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [OBDService new];
    });

    return instance;
}

- (id)init {
    self = [super init];

    if (self) {
        self.bluethoothQueue = dispatch_queue_create("OBDServiceBluetoothQueue", DISPATCH_QUEUE_SERIAL);
        if ([self backgroundBluetoothEnabled]) {
            self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:self.bluethoothQueue options:@{CBCentralManagerOptionRestoreIdentifierKey : kCentralManagerRestorationID, CBCentralManagerOptionShowPowerAlertKey: @NO}];
        } else {
            self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:self.bluethoothQueue options:@{CBCentralManagerOptionShowPowerAlertKey: @NO}];
        }
        self.devices = [NSMutableArray array];
    }

    return self;
}

- (NSArray *)discoveredDevices {
    return self.devices;
}

#pragma mark - Public methods

- (void)searchForDevicesOnConnection:(OBDConnectionType)connection {
    if (connection == OBDConnectionTypeBluetoothLE) {
        if (self.centralManager.state == CBCentralManagerStatePoweredOn) {
            [self.devices removeAllObjects];
            [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerOptionShowPowerAlertKey: @NO}];
        } else if (self.centralManager.state == CBCentralManagerStatePoweredOff) {
            if ([self.delegate respondsToSelector:@selector(OBDService:unableToSearchForDevicesOnConnection:)]) {
                [self.delegate OBDService:self unableToSearchForDevicesOnConnection:OBDConnectionTypeBluetoothLE];
            }
        } else {
            self.searchPending = YES;
        }
    }
}

- (void)stopDeviceSearch {
    [self.centralManager stopScan];
}

#pragma mark - CBCentralManagerDelegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBCentralManagerStatePoweredOn) {
        if (self.searchPending) {
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
            self.searchPending = NO;
        }
    } else if (self.centralManager.state == CBCentralManagerStatePoweredOff) {
        if ([self.delegate respondsToSelector:@selector(OBDService:unableToSearchForDevicesOnConnection:)]) {
            [self.delegate OBDService:self unableToSearchForDevicesOnConnection:OBDConnectionTypeBluetoothLE];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *,id> *)dict {
    NSArray *peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey];
    for (CBPeripheral *p in peripherals) {
        OBDDevice *device = [self deviceForPeripheral:p];
        if (device) {
            device.peripheral = p;
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    OBDDevice *device = [self deviceForPeripheral:peripheral];
    if (device) {
        [device handleConnectionSuccess];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    OBDDevice *device = [self deviceForPeripheral:peripheral];
    if (device) {
        [device handleDisconnection:error];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    OBDDevice *device = [self deviceForPeripheral:peripheral];
    if (device) {
        [device handleConnectionFailure:error];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    BOOL deviceExists = false;
    for (OBDDevice *device in self.devices) {
        if ([peripheral.identifier isEqual:device.peripheral.identifier]) {
            deviceExists = true;
            break;
        }
    }

    if (!deviceExists) {
        OBDDevice *device = [[OBDDevice alloc] initWithPeripheral:peripheral centralManager:self.centralManager];
        [self.devices addObject:device];
        if ([self.delegate respondsToSelector:@selector(OBDService:didDidFindDevice:)]) {
            [self.delegate OBDService:self didDidFindDevice:device];
        }
    }
}

#pragma mark - Private methods

- (OBDDevice *)deviceForPeripheral:(CBPeripheral *)peripheral {
    for (OBDDevice *d in self.devices) {
        if ([d.UUID isEqualToString:peripheral.identifier.UUIDString]) {
            return d;
        }
    }

    return nil;
}

- (BOOL)backgroundBluetoothEnabled {
    NSArray *modes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIBackgroundModes"];
    for (NSString *mode in modes) {
        if ([mode isEqualToString:@"bluetooth-central"]) {
            return YES;
        }
    }

    return NO;
}

@end
