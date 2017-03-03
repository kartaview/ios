//
//  OBDUtils.m
//  OBDLib
//
//  Created by BogdanB on 05/04/16.
//  Copyright © 2016 Telenav. All rights reserved.
//

#import "OBDUtils.h"

@implementation OBDUtils

+ (BOOL)getRPM:(int *)rpm fromData:(NSData *)data {
    char *bytes = NULL;
    if ([OBDUtils getPIDFromResponse:data] == OBDSensorEngineRPM && (bytes = [OBDUtils getValueBufferFromResponse:data forSensor:OBDSensorEngineRPM])) {
        char number[5];
        number[0] = bytes[0];
        number[1] = bytes[1];
        number[2] = bytes[3];
        number[3] = bytes[4];
        number[4] = '\0';
        
        long value = strtol(number, NULL, 16) / 4;
        *rpm = (int)value;
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL)getSpeed:(int *)speed fromData:(NSData *)data {
    char *bytes = NULL;
    if ([OBDUtils getPIDFromResponse:data] == OBDSensorVehicleSpeed && (bytes = [OBDUtils getValueBufferFromResponse:data forSensor:OBDSensorVehicleSpeed])) {
        char number[3];
        number[0] = bytes[0];
        number[1] = bytes[1];
        number[2] = '\0';
        long value = strtol(number, NULL, 16);
        *speed = (int)value;
        return YES;
    }
    
    return NO;
}

+ (OBDSensor)getPIDFromResponse:(NSData *)response {
    char *bytes = NULL;
    if ((bytes = strstr(response.bytes, "\r4\0")) && (bytes + 5 < (char*)response.bytes + response.length)) {
        char number[5];
        number[0] = bytes[1];
        number[1] = bytes[2];
        number[2] = bytes[4];
        number[3] = bytes[5];
        number[4] = '\0';
        long value = strtol(number, NULL, 16) - 0x4000;
        return (OBDSensor)value;
    }
    
    return OBDSensorUnknown;
}

/** Returns the start of the value part from a response for a given sensor. NULL if the response is not for the received sensor.
 Example: for 010C\r41 0C 9A C9 it should return the start of 9A
 */
+ (char *)getValueBufferFromResponse:(NSData *)data forSensor:(OBDSensor)sensor {
    char number[6];
    [OBDUtils sensor:sensor + 0x4000 toString:number];
    char *offset = strstr(data.bytes, number);
    if (offset + 6 <= (char*)data.bytes + data.length) {
        return offset + 6;
    } else {
        return NULL;
    }
}

/** Converts a uint16 into a null-terminated hex string with bytes separated by a string. string must be able to hold 6 bytes.
 */
+ (void)sensor:(OBDSensor)sensor toString:(char *)string {
    snprintf(string, 5, "%04X", sensor);
    //move the second byte 1 char to the right
    string[4] = string[3];
    string[3] = string[2];
    string[2] = ' ';
    string[5] = '\0';
}

@end
