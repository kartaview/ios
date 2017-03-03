//
//  OBDService.h
//  OBDLib
//
//  Created by BogdanB on 24/03/16.
//  Copyright © 2016 Telenav. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OBDServiceDelegate.h"

@class OBDDevice;

/** Allows connecting to an OBD device and communicating with it.
 */
@interface OBDService : NSObject

/** Receives updates about device status.
 */
@property (atomic, weak) id<OBDServiceDelegate> delegate;

/** A list of devices that have been discovered so far.
 */
@property (nonatomic, readonly) NSArray<OBDDevice *> *discoveredDevices;

/** Returns the singleton of the OBD service.
 */
+ (instancetype)sharedInstance;

/** Searches for possible devices using a connection interface.
 */
- (void)searchForDevicesOnConnection:(OBDConnectionType)connection;

/** Cancels device discovery.
 */
- (void)stopDeviceSearch;

@end
