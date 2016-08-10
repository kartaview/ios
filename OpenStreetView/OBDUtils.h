//
//  OBDUtils.h
//  OBDLib
//
//  Created by BogdanB on 05/04/16.
//  Copyright © 2016 Telenav. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OBDSensors.h"

@interface OBDUtils : NSObject

/** Extracts the RPM from the response.
 */
+ (BOOL)getRPM:(int *)rpm fromData:(NSData *)data;

/** Extracts the speed from the response.
 */
+ (BOOL)getSpeed:(int *)speed fromData:(NSData *)data;

/** Extracts the PID from the response.
 */
+ (OBDSensor)getPIDFromResponse:(NSData *)response;

@end
