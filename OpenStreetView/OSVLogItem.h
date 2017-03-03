//
//  OSVLogItem.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 11/02/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CMLogItem;
@class OSVPhotoData;
@class CLLocation;
@class CLHeading;
@class OSVOBDData;

@interface OSVLogItem : NSObject

@property (nonatomic, strong) CMLogItem     *sensorData;
@property (nonatomic, strong) OSVPhotoData  *photodata;
@property (nonatomic, strong) CLLocation    *location;
@property (nonatomic, strong) CLHeading     *heading;

@property (nonatomic, strong) OSVOBDData    *carSensorData;

@end
