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
#import <UIKit/UIKit.h>

@interface OSVTrackLogger ()

@property (nonatomic) NSLock            *createLock;
@property (nonatomic) NSFileHandle      *currentLogFileHandle;
@property (nonatomic) NSString          *basePath;
@property (nonatomic, assign) NSInteger currentID;

@property (nonatomic, strong) dispatch_queue_t  serialDispatchQueue;
@property (nonatomic, assign) long              count;
@property (nonatomic, strong) NSMutableString   *flushMessage;

@property (nonatomic, assign) NSTimeInterval    offsetTime;

@end

@implementation OSVTrackLogger

- (instancetype)initWithBasePath:(NSString *)string {
    self = [super init];
    if (self) {
        self.createLock = [NSLock new];
        self.basePath = string;
        
        self.serialDispatchQueue = dispatch_queue_create("trackLoggingQueue", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

- (void)createNewLogFileForSequenceID:(NSInteger)uid {
    // Get NSTimeInterval of uptime i.e. the delta: now - bootTime
    self.offsetTime = [[NSDate date] timeIntervalSince1970] - [NSProcessInfo processInfo].systemUptime;
    
    if (self.currentID) {
        [self closeLoggFileForSequenceID:self.currentID];
    }
    
    self.currentID = uid;
    self.flushMessage = [NSMutableString string];
    self.count = 0;
    
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
            NSString *metainfo = [NSString stringWithFormat:@"%@;%@;1.1.5;%@(%@)\n",
                                  [UIDevice modelString],
                                  [UIDevice osVersion],
                                  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                                  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
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

- (void)logItem:(OSVLogItem *)item {
    if (!self.currentLogFileHandle || self.currentID == 0) {
        return;
    }
    
    NSString *rowMessage = nil;
    
    if (item.photodata){
        rowMessage = [NSString stringWithFormat:@"%f;;;;;;;;;;;;;;%ld;%ld;;;;;\n",
                      item.photodata.timestamp,
                      (long)item.photodata.videoIndex,
                      (long)item.photodata.sequenceIndex];
    } else if (item.location) {
        CLLocation *location = item.location;
        rowMessage = [NSString stringWithFormat:@"%f;%f;%f;%f;%f;%f;;;;;;;;;;;;;;;%f\n",
                      [location.timestamp timeIntervalSince1970],
                      location.coordinate.longitude,
                      location.coordinate.latitude,
                      location.altitude,
                      location.horizontalAccuracy,
                      location.speed,
                      location.verticalAccuracy];
    } else if (item.heading) {
        rowMessage = [NSString stringWithFormat:@"%f;;;;;;;;;;;;;%f;;;;;;;\n",
                      [item.heading.timestamp timeIntervalSince1970],
                      [self adjustHeadingToOrientation:item.heading.trueHeading]];
    } else if ([item.sensorData isKindOfClass:[CMAltitudeData class]]) {
        CMAltitudeData *altitudeData = (CMAltitudeData *)item.sensorData;
        rowMessage = [NSString stringWithFormat:@"%f;;;;;;;;;;;;%f;;;;;;;;\n",
                      altitudeData.timestamp + self.offsetTime,
                      [altitudeData.pressure doubleValue]];
    } else if ([item.sensorData isKindOfClass:[CMDeviceMotion class]]) {
        CMDeviceMotion *deviceMotionData = (CMDeviceMotion *)item.sensorData;
        rowMessage = [NSString stringWithFormat:@"%f;;;;;;%f;%f;%f;%f;%f;%f;;;;;%f;%f;%f;;\n",
                      deviceMotionData.timestamp + self.offsetTime,
                      deviceMotionData.attitude.yaw,
                      deviceMotionData.attitude.pitch,
                      deviceMotionData.attitude.roll,
                      deviceMotionData.userAcceleration.x,
                      deviceMotionData.userAcceleration.y,
                      deviceMotionData.userAcceleration.z,
                      deviceMotionData.gravity.x,
                      deviceMotionData.gravity.y,
                      deviceMotionData.gravity.z];
    } else if (item.carSensorData) {
        rowMessage = [NSString stringWithFormat:@"%f;;;;;;;;;;;;;;;;;;;%f;\n",
                      item.carSensorData.timestamp,
                      item.carSensorData.speed];
    }
    
    if (self.currentLogFileHandle && rowMessage != nil) {
        [self safeWriteString:rowMessage];
    }
}

- (void)safeWriteString:(NSString *)string {
    dispatch_async(self.serialDispatchQueue, ^{
        int i = 0;
        self.count++;
        [self.flushMessage appendString:string];
        
        if (self.flushMessage.length > 1700) {
            while (![self retryToWriteString:self.flushMessage] && i < 5) {
                i++;
            }
            [self.flushMessage setString:@""];
        }
    });
}

- (BOOL)retryToWriteString:(NSString *)string {
    @try {
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        [self.currentLogFileHandle writeData:data];
        [self.currentLogFileHandle synchronizeFile];
        
    } @catch (NSException *exception) {
        return NO;
    }
    
    return YES;
}

- (void)closeLoggFileForSequenceID:(NSInteger)uid {
    dispatch_async(self.serialDispatchQueue, ^{
        if (self.flushMessage.length > 0) {
            [self retryToWriteString:self.flushMessage];
        }
        [self retryToWriteString:@"DONE"];
        [self.currentLogFileHandle closeFile];
        self.currentLogFileHandle = nil;
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *txtfile = [NSString stringWithFormat:@"%@%ld/track.txt", self.basePath, (long)uid];
        NSString *zipfile = [NSString stringWithFormat:@"%@%ld/track.txt.gz", self.basePath, (long)uid];
        NSError *error;
        
        [[NSFileManager defaultManager] GZipCompressFile:[NSURL URLWithString:txtfile] writingContentsToFile:[NSURL URLWithString:zipfile] error:&error];
    });
}

- (double)adjustHeadingToOrientation:(double)heading {
    double value = heading;
    
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationLandscapeLeft:
            value = fmod((heading + 90), 359.0);
            break;
        case UIDeviceOrientationLandscapeRight:
            value = fmod((heading + 270), 359.0);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            value = fmod((heading + 180), 359.0);
            break;
        default:
            break;
    }
    
    return value;
}

@end
