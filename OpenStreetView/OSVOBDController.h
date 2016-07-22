//
//  OSVOBDController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 22/03/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OSVOBDData;

typedef void (^OSVOBDHandler)(OSVOBDData *obdData);

@interface OSVOBDController : NSObject

@property (assign, nonatomic) BOOL shouldReconnect;
@property (assign, nonatomic) BOOL isRecordingMode;

- (instancetype)initWithHandler:(OSVOBDHandler)handler;

- (void)startOBDUpdates;
- (void)stopOBDUpdates;

- (void)reconnect;

@end

