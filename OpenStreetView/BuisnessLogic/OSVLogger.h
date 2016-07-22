//
//  SKLogger.h
//  SKMaps
//
//  Created by Alex Ilisei on 5/13/13.
//  Copyright (c) 2013 Skobbler. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    LogLevelERROR,
    LogLevelWARNING,
    LogLevelDEBUG
}LogLevel;

//#ifdef ENABLED_DEBUG
//
//#else

#undef NSLog
#define NSLog(...)

//#endif


@interface OSVLogger : NSObject

@property (atomic, assign, getter = isEnabled) BOOL enabled;

+ (instancetype)sharedInstance;
- (void)createNewLogFile;
- (void)logMessage:(NSString *)message withLevel:(LogLevel)level;

@end
