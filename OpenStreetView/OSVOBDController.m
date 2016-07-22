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

@interface OSVOBDController () <FLScanToolDelegate>

@property (strong, nonatomic) ELM327 *obdScanner;

@property (copy, nonatomic) OSVOBDHandler handler;

@property (strong, nonatomic) NSTimer *timer;

@property (strong, nonatomic) NSTimer *keepAlive;

@property (strong, nonatomic) NSDate  *lastReceivedDataTimestamp;

@property (assign, nonatomic) BOOL    isConnected;
@property (assign, nonatomic) BOOL    isConnecting;

@property (assign, nonatomic) BOOL    manualyDisconnected;
@property (assign, nonatomic) BOOL    hasWiFiConnection;


@property (nonatomic, strong) Reachability *r;

@property (assign, nonatomic) NSInteger     retryCheckStatus;

@end

const int secondsBetweenChecks = 5;

const int connectionTimeOut = 7;

@implementation OSVOBDController

- (instancetype)initWithHandler:(OSVOBDHandler)handler {
    self = [super init];
    if (self) {
        self.isConnected = NO;
        self.manualyDisconnected = NO;
        self.shouldReconnect = YES;
        self.isConnecting = NO;
        
        self.r = [Reachability reachabilityForLocalWiFi];
        [self.r startNotifier];
        self.handler = handler;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentStatus) name:@"kOBDStatus" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNetworkStatusChange:) name:kReachabilityChangedNotification object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - public methods

- (void)startOBDUpdates {
    if (self.isConnected || self.isConnecting) {
        return;
    }
    
    if (!self.hasWiFiConnection) {
        return;
    }
    
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kOBDDidDisconnect" object:nil userInfo:@{}];
    NSLog(@"kOBDDidDisconnect");
    [self.timer invalidate];
    self.timer = nil;
    self.isConnected = NO;
    self.isConnecting = NO;
    self.manualyDisconnected = YES;
}

#pragma mark - Private

- (void)checkForNewData {
    
    NSTimeInterval timePassed = [[NSDate new] timeIntervalSinceDate:self.lastReceivedDataTimestamp];
    
    if (timePassed > secondsBetweenChecks && self.isConnected) {
        NSLog(@"did not receive data will display -");
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
    if (self.isConnected) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kOBDDidConnect" object:nil userInfo:@{}];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kOBDDidDisconnect" object:nil userInfo:@{}];
    }
}

#pragma mark - FLScanToolDelegate

- (void)scanToolDidConnect:(FLScanTool *)scanTool {
    self.isConnected = YES;
    self.isConnecting = NO;
    [[OSVLogger sharedInstance] logMessage:@"has connection" withLevel:LogLevelDEBUG];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kOBDDidConnect" object:nil userInfo:@{}];
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

#pragma mark - OBD2 notifications

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
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kOBDDidDisconnect" object:nil userInfo:@{}];
        
        [[OSVLogger sharedInstance] logMessage:@"did lost wifi connection" withLevel:LogLevelDEBUG];
        [self.obdScanner cancelScan];
        [self.obdScanner setSensorScanTargets:nil];
        [self.obdScanner setDelegate:nil];
    }
}

- (BOOL)hasWiFiConnection {
    Reachability *r = [Reachability reachabilityForLocalWiFi];
    NetworkStatus status = [r currentReachabilityStatus];
    
    return status == ReachableViaWiFi;
}

@end
