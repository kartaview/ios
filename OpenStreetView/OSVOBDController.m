//
//  OSVOBDController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 22/03/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVOBDController.h"
#import "ELM327.h"
#import "FLECUSensor.h"
#import "OSVOBDData.h"
#import "OSVLogger.h"
#import "Reachability.h"
#import "ConnectivityHandler.h"
#import "OBDLib.h"

#import "OSVSectionItem.h"
#import "OSVMenuItem.h"
#import "OSVUserDefaults.h"

#import <CoreBluetooth/CoreBluetooth.h>
#import <Crashlytics/Crashlytics.h>

@interface OSVOBDController () <FLScanToolDelegate, OBDServiceDelegate, OBDDeviceDelegate>

@property (strong, nonatomic) ELM327        *obdScanner;

@property (copy, nonatomic) OSVOBDHandler   handler;

@property (strong, nonatomic) NSTimer       *timer;

@property (strong, nonatomic) NSTimer       *keepAlive;

@property (strong, nonatomic) NSTimer       *bleTimer;
@property (strong, nonatomic) NSTimer       *bleConnection;

@property (strong, nonatomic) NSDate        *lastReceivedDataTimestamp;

@property (assign, nonatomic) BOOL          isConnected;
@property (assign, nonatomic) BOOL          isConnecting;

@property (assign, nonatomic) BOOL          isConnectedBLE;
@property (assign, nonatomic) BOOL          isConnectingBLE;

@property (assign, nonatomic) BOOL          manualyDisconnected;
@property (assign, nonatomic) BOOL          hasWiFiConnection;

@property (assign, nonatomic) BOOL          shouldDisplayBluetooth;

@property (nonatomic, strong) Reachability  *r;

@property (assign, nonatomic) NSInteger     retryCheckStatus;

@property (strong, nonatomic) OSVSectionItem    *item;
@property (strong, nonatomic) OBDDevice         *bleDevice;

@end

const int secondsBetweenChecks = 5;

const int connectionTimeOut = 7;

@implementation OSVOBDController

- (instancetype)initWithHandler:(OSVOBDHandler)handler {
    self = [super init];
    if (self) {
        self.isConnected = NO;
        self.isConnectedBLE = NO;
        self.manualyDisconnected = NO;
        self.shouldReconnect = YES;
        self.isConnecting = NO;
        self.isConnectingBLE = NO;
        
        self.r = [Reachability reachabilityForLocalWiFi];
        [self.r startNotifier];
        self.handler = handler;
        [OBDService sharedInstance].delegate = self;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentStatus) name:@"kOBDStatus" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNetworkStatusChange:) name:kReachabilityChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNewDatasourceItem:) name:@"BLEDatasource" object:nil];

    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - public methods

- (void)startOBDUpdates {
    if (self.isConnected || self.isConnecting ||
        self.isConnectedBLE || self.isConnectingBLE) {
        return;
    }
    
//detect if there is a bluethooth device connection
    if (self.hasWiFiConnection) {
        self.isConnecting = YES;
        self.manualyDisconnected = NO;
        
        //reset OBD
        [self.obdScanner cancelScan];
        [self.obdScanner setSensorScanTargets:nil];
        [self.obdScanner setDelegate:nil];
        self.obdScanner = [ELM327 scanToolWithHost:@"192.168.0.10" andPort:35000];
        
        [self.obdScanner setUseLocation:NO];
        [self.obdScanner setDelegate:self];
        [self.obdScanner startScanWithSensors:^NSArray *{
            NSArray *sensors = @[@(OBD2SensorVehicleSpeed)];
            [[OSVLogger sharedInstance] logMessage:@"is connected" withLevel:LogLevelDEBUG];
            self.isConnected = YES;
            self.isConnecting = NO;
            
            return sensors;
        }];
    }

    [self scanBLEOBDShowAlert:NO];
}

- (void)checkForOBDScannerStatus {
    double delay = 0.2;
    self.isConnecting = self.obdScanner.status == NSStreamStatusOpening || self.obdScanner.status == NSStreamStatusNotOpen;
    if (!self.isConnected && self.isConnecting && self.retryCheckStatus < (connectionTimeOut / delay)) {
        [self performSelector:@selector(checkForOBDScannerStatus) withObject:nil afterDelay:delay];
        self.retryCheckStatus++;
    } else if (!self.isConnected && self.retryCheckStatus == (connectionTimeOut / delay)) {
        //this is not a OBD 2 WIFI should stop trying to connect
        self.retryCheckStatus = 0;
        //error code 60 is return if time out by NSStream
        //      if (self.obdScanner.error.code == 60) {
        [self.obdScanner cancelScan];
        [self.obdScanner setSensorScanTargets:nil];
        [self.obdScanner setDelegate:nil];
        [self.timer invalidate];
        self.timer = nil;
        self.isConnected = NO;
        self.isConnecting = NO;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kOBDFailedToConnectInTime" object:nil userInfo:@{}];
        [[OSVLogger sharedInstance] logMessage:@"failed to connect" withLevel:LogLevelDEBUG];
        [CrashlyticsKit setObjectValue:@"faildToConnectInTime" forKey:@"OBD"];
        if (self.isRecordingMode) {
            [self reconnect];
        }
    } else if (self.isConnected) {
        self.retryCheckStatus = 0;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.timer) {
                [self.timer invalidate];
                self.timer = nil;
            }
            
            self.lastReceivedDataTimestamp = [NSDate new];
            self.timer = [NSTimer scheduledTimerWithTimeInterval:secondsBetweenChecks target:self
                                                        selector:@selector(checkForNewData) userInfo:nil
                                                         repeats:YES];
        });
        
    } else if (self.retryCheckStatus == (connectionTimeOut / delay)) {
        self.retryCheckStatus = 0;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kOBDFailedToConnectInTime" object:nil userInfo:@{}];
        [CrashlyticsKit setObjectValue:@"faildToConnectInTime" forKey:@"OBD"];
        [[OSVLogger sharedInstance] logMessage:@"failed to connect will reconnect" withLevel:LogLevelDEBUG];
        self.isConnected = NO;
        self.isConnecting = NO;
        [self reconnect];
    }
}

- (void)stopOBDUpdates {
    [self.obdScanner cancelScan];
    [self.obdScanner setSensorScanTargets:nil];
    [self.obdScanner setDelegate:nil];
    
    [[OSVLogger sharedInstance] logMessage:@"did stop obd upldates" withLevel:LogLevelDEBUG];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kOBDDidDisconnect" object:nil userInfo:@{@"OBD" : @"WIFI"}];
    [CrashlyticsKit setObjectValue:@"kOBDDidDisconnect - WIFI" forKey:@"OBD"];

    [self.timer invalidate];
    self.timer = nil;
    self.isConnected = NO;
    self.isConnecting = NO;
    self.manualyDisconnected = YES;
    
    if (self.bleDevice) {
        [self.bleDevice disconnect];
        self.bleDevice = nil;
        [OSVUserDefaults sharedInstance].bleDevice = nil;
        [[OSVUserDefaults sharedInstance] save];
    }
}

- (void)scanBLEOBDShowAlert:(BOOL)value {
    self.shouldDisplayBluetooth = value;
    [[OBDService sharedInstance] stopDeviceSearch];
    [[OBDService sharedInstance] searchForDevicesOnConnection:OBDConnectionTypeBluetoothLE];
}

#pragma mark - Private

- (void)checkForNewData {
    
    NSTimeInterval timePassed = [[NSDate new] timeIntervalSinceDate:self.lastReceivedDataTimestamp];
    
    if (timePassed > secondsBetweenChecks && self.isConnected) {
        [[OSVLogger sharedInstance] logMessage:@"did not receive data" withLevel:LogLevelDEBUG];
        if (self.handler) {
            self.handler(nil);
        }
        
        if (timePassed > connectionTimeOut && self.shouldReconnect && !self.manualyDisconnected) {
            self.isConnected = NO;
            self.isConnecting = NO;
            
            [self reconnect];
        } else if (self.manualyDisconnected) {
            [self.timer invalidate];
            self.timer = nil;
            
            [self.obdScanner cancelScan];
            [self.obdScanner setSensorScanTargets:nil];
            [self.obdScanner setDelegate:nil];
            
            [[OBDService sharedInstance] stopDeviceSearch];
            
            self.isConnected = NO;
            self.isConnecting = NO;
        }
    }
}

- (void)reconnect {
    
    [[OSVLogger sharedInstance] logMessage:@"is reconnecting" withLevel:LogLevelDEBUG];
    self.retryCheckStatus = 0;
    [self startOBDUpdates];
}

- (void)currentStatus {
    [[OBDService sharedInstance] stopDeviceSearch];
    if (self.isConnected) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kOBDDidConnect" object:nil userInfo:@{@"OBD" : @"WIFI"}];
        [CrashlyticsKit setObjectValue:@"kOBDDidConnect - WIFI" forKey:@"OBD"];

    } else if (self.isConnectedBLE) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kOBDDidConnect" object:nil userInfo:@{@"OBD" : @"BLE"}];
        
        [CrashlyticsKit setObjectValue:@"kOBDDidConnect - BLE" forKey:@"OBD"];

    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kOBDDidDisconnect" object:nil userInfo:@{@"OBD" : @"WIFI"}];
        
        [CrashlyticsKit setObjectValue:@"kOBDDidDisconnect - WIFI" forKey:@"OBD"];

    }
}

- (BOOL)hasWiFiConnection {
    Reachability *r = [Reachability reachabilityForLocalWiFi];
    NetworkStatus status = [r currentReachabilityStatus];
    
    return status == ReachableViaWiFi;
}

#pragma mark - FLScanToolDelegate

- (void)scanToolDidConnect:(FLScanTool *)scanTool {
    self.isConnected = YES;
    self.isConnecting = NO;
    [[OSVLogger sharedInstance] logMessage:@"has connection" withLevel:LogLevelDEBUG];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kOBDDidConnect" object:nil userInfo:@{@"OBD" : @"WIFI"}];
    [CrashlyticsKit setObjectValue:@"kOBDDidConnect-WIFI" forKey:@"OBD"];
}

- (void)scanTool:(FLScanTool *)scanTool didUpdateSensor:(FLECUSensor *)sensor {
    self.isConnected = YES;
    self.isConnecting = NO;
    switch (sensor.pid) {
        case OBD2SensorVehicleSpeed: {
            self.lastReceivedDataTimestamp = [NSDate new];
            
            OSVOBDData *data = [OSVOBDData new];
            data.speed = [[sensor valueForMeasurement1:YES] floatValue];
            data.timestamp = [sensor.currentResponse.timestamp timeIntervalSince1970];
            if (self.handler) {
                self.handler(data);
            }
            break;
        }
        default:
            NSLog(@"default sensor");
            
            break;
    }
}

- (void)scanDidStart:(FLScanTool *)scanTool {
    NSLog(@"manged to stat Socket");
    [[OSVLogger sharedInstance] logMessage:@"did start connection" withLevel:LogLevelDEBUG];
    [self checkForOBDScannerStatus];
}

- (void)scanDidCancel:(FLScanTool *)scanTool {
    NSLog(@"canceled");
}

- (void)scanTool:(FLScanTool *)scanTool didReceiveVoltage:(NSString*)voltage {
    self.isConnected = YES;
    self.isConnecting = NO;
}

- (void)scanTool:(FLScanTool *)scanTool didReceiveError:(NSError*)error {
    self.isConnected = NO;
    
    if (self.hasWiFiConnection) {
        [[OSVLogger sharedInstance] logMessage:@"did receive error with wifi connection" withLevel:LogLevelDEBUG];
        [self reconnect];
    }
}

#pragma mark - WIFI notifications

- (void)didReceiveNetworkStatusChange:(NSNotification *)notificaiton {
    if (self.hasWiFiConnection) {
        NSLog(@"did receive connection to wifi");
        [[OSVLogger sharedInstance] logMessage:@"did receive wifi connection" withLevel:LogLevelDEBUG];
        self.isConnected = NO;
        [self reconnect];
    } else {
        NSLog(@"did lost connection to wifi");
        self.isConnected = NO;
        self.isConnecting = NO;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kOBDDidDisconnect" object:nil userInfo:@{@"OBD" : @"WIFI"}];
        [CrashlyticsKit setObjectValue:@"kOBDDidDisconnect-WIFI" forKey:@"OBD"];
        [[OSVLogger sharedInstance] logMessage:@"did lost wifi connection" withLevel:LogLevelDEBUG];
        [self.obdScanner cancelScan];
        [self.obdScanner setSensorScanTargets:nil];
        [self.obdScanner setDelegate:nil];
    }
}

- (void)didReceiveNewDatasourceItem:(NSNotification *)notificaiton {
    self.item = notificaiton.userInfo[@"datasource"];
}

#pragma mark - OBDServiceDelegate

- (void)OBDService:(OBDService *)service didDidFindDevice:(OBDDevice *)device {
    NSMutableArray *allDevices = [NSMutableArray array];
    if (self.item) {
        for (OBDDevice *someDev in service.discoveredDevices) {
            OSVMenuItem *menuItem = [OSVMenuItem new];
            menuItem.title = someDev.name != nil ? ([someDev.name isEqualToString:@""] ? someDev.UUID : someDev.name) : someDev.UUID;
            menuItem.key = menuItem.title;
            menuItem.action = ^(id sender, id index) {
                [self.bleDevice disconnect];
                [someDev connect];
                someDev.delegate = self;
                self.bleDevice = someDev;
            };
            
            [allDevices addObject:menuItem];
        }
        self.item.rowItems = allDevices;
        
        __weak typeof(self) welf = self;
        self.item.action = ^(id sender, NSIndexPath *index) {
            ((OSVMenuItem *)welf.item.rowItems[index.row]).action(nil, nil);
        };
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kReloadDetails" object:@{}];
        });
    } else { // autoconnect
        NSString *name = device.name != nil ? ([device.name isEqualToString:@""] ? device.UUID : device.name) : device.UUID;
        if ([name isEqualToString:[OSVUserDefaults sharedInstance].bleDevice]) {
            [device connect];
            device.delegate = self;
            [service stopDeviceSearch];
        } else { // delete the automatic
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!self.bleConnection) {
                    self.bleConnection = [NSTimer scheduledTimerWithTimeInterval:7 target:self
                                                                        selector:@selector(stopAutomaticSearch) userInfo:@{}
                                                                         repeats:NO];

                }
            });
        }
    }
}

- (void)OBDService:(OBDService *)service unableToSearchForDevicesOnConnection:(OBDConnectionType)connection {
    self.isConnectedBLE = NO;
    self.isConnectingBLE = NO;
    
    if (connection == OBDConnectionTypeBluetoothLE) {
        [service stopDeviceSearch];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kOBDDidDisconnect" object:nil userInfo:@{@"OBD" : @"BLE"}];
            [CrashlyticsKit setObjectValue:@"kOBDDidDisconnect-BLE" forKey:@"OBD"];

            if (self.shouldDisplayBluetooth) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"kWaitForData" object:nil userInfo:@{}];
                CBCentralManager *cb = [[CBCentralManager alloc] initWithDelegate:nil queue:nil];
                [cb scanForPeripheralsWithServices:nil options:nil];
                [cb stopScan];
            }
        });
    }
}

#pragma mark - OBDDeviceDelegate

- (void)OBDDeviceDidConnect:(OBDDevice *)device {
    self.isConnectedBLE = YES;
    self.isConnectingBLE = NO;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"request data");
        [device getValueForSensor:OBDSensorVehicleSpeed];
    });
    
    self.bleDevice = device;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kOBDDidConnect" object:nil userInfo:@{@"OBD" : @"BLE"}];
        [CrashlyticsKit setObjectValue:@"kOBDDidConnect-BLE" forKey:@"OBD"];
    });
}

- (void)OBDDeviceFailedToConnect:(OBDDevice *)device error:(NSError *)error {
    self.isConnectedBLE = NO;
    self.isConnectingBLE = NO;
    [OSVUserDefaults sharedInstance].bleDevice = nil;
    [[OSVUserDefaults sharedInstance] save];

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kOBDDidDisconnect" object:nil userInfo:@{@"OBD" : @"BLE"}];
        [CrashlyticsKit setObjectValue:@"kOBDDidDisconnect-BLE" forKey:@"OBD"];
    });
}

- (void)OBDDeviceDidDisconnect:(OBDDevice *)device error:(NSError *)error {
    self.isConnectedBLE = NO;
    self.isConnectingBLE = NO;
    
    [self.bleTimer invalidate];
    self.bleTimer = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kOBDDidDisconnect" object:nil userInfo:@{@"OBD" : @"BLE"}];
        [CrashlyticsKit setObjectValue:@"kOBDDidDisconnect-BLE" forKey:@"OBD"];
    });
}

- (void)OBDDevice:(OBDDevice *)device didUpdateInteger:(int)value forSensor:(OBDSensor)sensor {
    self.isConnectedBLE = YES;
    self.isConnectingBLE = NO;
    
    switch (sensor) {
        case OBDSensorVehicleSpeed: {
            self.lastReceivedDataTimestamp = [NSDate new];
            
            OSVOBDData *data = [OSVOBDData new];
            data.speed = value;
            data.timestamp = [[NSDate new] timeIntervalSince1970];
            if (self.handler) {
                self.handler(data);
            }
            break;
        }
        default:
            NSLog(@"default sensor");
            
            break;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.bleDevice getValueForSensor:sensor];
    });
}

#pragma mark - OBD BluethoothLE

- (void)stopAutomaticSearch {
    self.bleConnection = nil;
    if (self.isConnectedBLE == NO) {
        [OSVUserDefaults sharedInstance].bleDevice = nil;
        [[OSVUserDefaults sharedInstance] save];
        [[OBDService sharedInstance] stopDeviceSearch];
    }
}

@end
