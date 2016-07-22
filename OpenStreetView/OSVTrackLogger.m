//
//  OSVTrackLogger.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 11/02/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVTrackLogger.h"
#import "OSVPhotoData.h"
#import "Godzippa.h"
#import "UIDevice+Aditions.h"
#import "OSVLogger.h"

@interface OSVTrackLogger ()

@property (nonatomic) NSLock            *createLock;
@property (nonatomic) NSFileHandle      *currentLogFileHandle;
@property (nonatomic) NSString          *basePath;
@property (nonatomic, assign) NSInteger currentID;

@end

@implementation OSVTrackLogger

- (instancetype)initWithBasePath:(NSString *)string {
    self = [super init];
    if (self) {
        self.createLock = [NSLock new];
        self.basePath = string;
    }
    
    return self;
}

- (void)createNewLogFileForSequenceID:(NSInteger)uid {
    if (self.currentID) {
        [self closeLoggFileForSequenceID:self.currentID];
    }

    self.currentID = uid;
    
    NSString *logsFileName = [self fileNameForTrackID:uid];
    
    if (logsFileName) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:self.basePath]) {
            [fileManager createDirectoryAtPath:self.basePath
                   withIntermediateDirectories:YES
                                    attributes:NULL
                                         error:NULL];
        }
        
        if (![fileManager fileExistsAtPath:logsFileName]) {
            [fileManager createFileAtPath:logsFileName contents:nil attributes:nil];
        }
        
        self.currentLogFileHandle = [NSFileHandle fileHandleForWritingAtPath:logsFileName];
        
        if (self.currentLogFileHandle) {
            NSString *metainfo = [NSString stringWithFormat:@"%@;%@;1.1;%@(%@)\n", [UIDevice modelString], [UIDevice osVersion], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
            [self safeWriteString:metainfo];
        }
    }
}

- (NSString *)fileNameForTrackID:(NSInteger)uid {
    NSString *folderPathString = [NSString stringWithFormat:@"%@%ld", self.basePath, (long)uid];
    if (![[NSFileManager defaultManager] fileExistsAtPath:folderPathString]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPathString withIntermediateDirectories:NO attributes:NULL error:NULL];
    }
    
    return [folderPathString stringByAppendingString:@"/track.txt"];
}

- (void)logItems:(NSArray<CMLogItem *> *)trackLogItems inFileForSequenceID:(NSInteger)uid {
    if (!self.currentLogFileHandle || self.currentID == 0) {
        return;
    }
    NSMutableString *logMessage = [NSMutableString new];
    NSString *rowMessage = @"";
    // @"timestamp;longitude;latitude;elevation;horizontal_accuracy;GPSspeed;yaw;pitch;roll;accelerationX;accelerationY;accelerationZ;pressure;compass;videoIndex;tripFrameIndex;gravityX;gravityY;gravityZ;OBD2speed\n";
    for (OSVLogItem *item in trackLogItems) {
        if (item.photodata){
            CLLocation *location = item.photodata.location;
            rowMessage = [NSString stringWithFormat:@"%f;%f;%f;%f;%f;%f;;;;;;;;;%ld;%ld;;;;\n", item.photodata.timestamp, location.coordinate.longitude, location.coordinate.latitude, location.altitude, location.horizontalAccuracy, location.speed, (long)item.photodata.videoIndex, (long)item.photodata.sequenceIndex];
        } else if (item.location) {
            CLLocation *location = item.location;
            rowMessage = [NSString stringWithFormat:@"%f;%f;%f;%f;%f;%f;;;;;;;;;;;;;;\n", [location.timestamp timeIntervalSince1970], location.coordinate.longitude, location.coordinate.latitude, location.altitude, location.horizontalAccuracy, location.speed];
        } else if (item.heading) {
            rowMessage = [NSString stringWithFormat:@"%f;;;;;;;;;;;;;%f;;;;;;\n", item.timestamp, item.heading.trueHeading];
        } else if ([item.sensorData isKindOfClass:[CMAltitudeData class]]) {
            CMAltitudeData *altitudeData = (CMAltitudeData *)item.sensorData;
            rowMessage = [NSString stringWithFormat:@"%f;;;;;;;;;;;;%f;;;;;;;\n", item.timestamp, [altitudeData.pressure doubleValue]];
        } else if ([item.sensorData isKindOfClass:[CMDeviceMotion class]]) {
            CMDeviceMotion *deviceMotionData = (CMDeviceMotion *)item.sensorData;
            rowMessage = [NSString stringWithFormat:@"%f;;;;;;%f;%f;%f;%f;%f;%f;;;;;%f;%f;%f;\n", item.timestamp, deviceMotionData.attitude.yaw, deviceMotionData.attitude.pitch, deviceMotionData.attitude.roll, deviceMotionData.userAcceleration.x, deviceMotionData.userAcceleration.y, deviceMotionData.userAcceleration.z, deviceMotionData.gravity.x, deviceMotionData.gravity.y, deviceMotionData.gravity.z];
        } else if (item.carSensorData) {
            rowMessage = [rowMessage stringByAppendingFormat:@"%f;;;;;;;;;;;;;;;;;;;%f\n", item.timestamp, item.carSensorData.speed];
        }
        [logMessage appendString:rowMessage];
    }
    
    if (self.currentLogFileHandle) {
        [self safeWriteString:logMessage];
    }
}

- (void)safeWriteString:(NSString *)string {
    int i = 0;
    while (![self retryToWriteString:string] && i < 5) {
        i++;
    }
}

- (BOOL)retryToWriteString:(NSString *)string {
    @try {
        [self.currentLogFileHandle seekToEndOfFile];
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        [self.currentLogFileHandle writeData:data];
    } @catch (NSException *exception) {
        return NO;
    }
    
    return YES;
}

- (void)closeLoggFileForSequenceID:(NSInteger)uid {
    [self.currentLogFileHandle closeFile];
    self.currentLogFileHandle = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *txtfile = [NSString stringWithFormat:@"%@%ld/track.txt", self.basePath, (long)uid];
        NSString *zipfile = [NSString stringWithFormat:@"%@%ld/track.txt.gz", self.basePath, (long)uid];
        NSError *error;
        
        [[NSFileManager defaultManager] GZipCompressFile:[NSURL URLWithString:txtfile] writingContentsToFile:[NSURL URLWithString:zipfile] error:&error];
    });
}

@end
