//
//  OSVTrackLogger.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 11/02/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import "OSVOBDData.h"
#import "OSVLogItem.h"

@interface OSVTrackLogger : NSObject

- (instancetype)initWithBasePath:(NSString *)string;

- (void)createNewLogFileForSequenceID:(NSInteger)uid;
- (void)logItem:(OSVLogItem *)trackLogItem;
- (void)closeLoggFileForSequenceID:(NSInteger)uid;

@end
