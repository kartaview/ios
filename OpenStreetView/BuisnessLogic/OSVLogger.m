//
//  SKLogger.m
//  SKMaps
//
//  Created by Alex Ilisei on 5/13/13.
//  Copyright (c) 2013 Skobbler. All rights reserved.
//

#import "OSVLogger.h"

static NSString *const kLogsFolderName = @"OSVLogs";

@interface OSVLogger ()

@property (atomic, strong) NSFileHandle *currentLogFileHandle;
@property (atomic, strong) NSDateFormatter *dateFormatter;

@end


@implementation OSVLogger
static OSVLogger *sharedInstance;
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[OSVLogger alloc] init];
        sharedInstance.enabled = YES;
    });
    return sharedInstance;
}

#pragma mark init/dealloc
- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)dealloc {
    if (_currentLogFileHandle) {
        [_currentLogFileHandle closeFile];
    }
}

- (void)createNewLogFile {
    if (self.isEnabled) {
        if (self.currentLogFileHandle) {
            [self.currentLogFileHandle closeFile];
            self.currentLogFileHandle = nil;
        }
        @autoreleasepool
        {
            self.dateFormatter = [[NSDateFormatter alloc] init];
            [self.dateFormatter setDateFormat:@"dd-MM-yyyy HH_mm"];
            
            NSString *logsFolder = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:kLogsFolderName];
            NSString *logsFileName = [NSString stringWithFormat:@"%@.log", [self.dateFormatter stringFromDate:[NSDate date]]];
            NSString *logFilePath = [logsFolder stringByAppendingPathComponent:logsFileName];
            
            if (logFilePath) {
                NSFileManager *fileManager = [NSFileManager defaultManager];
                if (![fileManager fileExistsAtPath:logsFolder]) {
                    [fileManager createDirectoryAtPath:logsFolder
                           withIntermediateDirectories:YES
                                            attributes:NULL
                                                 error:NULL];
                }
                
                if (![fileManager fileExistsAtPath:logFilePath]) {
                    [fileManager createFileAtPath:logFilePath contents:nil attributes:nil];
                }
                
                self.currentLogFileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
                [self.dateFormatter setDateFormat:@"dd-MM-yyyy HH:mm:ss.SSSS:"];
            }
        }
    }
}



- (void)logMessage:(NSString *)message withLevel:(LogLevel)level {

    if (self.isEnabled && self.currentLogFileHandle) {
        NSString *currentLogTime = [self.dateFormatter stringFromDate:[NSDate date]];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                           @autoreleasepool {
                               NSString *currentTime = [self.dateFormatter stringFromDate:[NSDate date]];
                               NSString *logLevelString = [self stringIdentifierForLogLevel:level];
                               NSString *messageWithLine = [NSString stringWithFormat:@"[%@][%@][%@] %@\n", logLevelString, currentLogTime, currentTime, message];
                               [self safeWriteString:messageWithLine];
                           }
                       });
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

- (NSString *)stringIdentifierForLogLevel:(LogLevel)level {
    NSString *stringLevel;
    switch (level) {
        case LogLevelDEBUG:
        {
            stringLevel = @"DEBUG";
            break;
        }
        case LogLevelWARNING:
        {
            stringLevel = @"WARNING";
            break;
        }
        case LogLevelERROR:
        {
            stringLevel = @"ERROR";
            break;
        }
        default:
        {
            stringLevel = @"";
            break;
        }
    }
    return stringLevel;
}

@end
