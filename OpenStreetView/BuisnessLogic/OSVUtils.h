//
//  Utils.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 10/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIImage.h>

@interface OSVUtils : NSObject

@end

/* --------------------------------------------------*/

@interface OSVUtils (Location)

/**
 * This method will return the air distance betwheen two coordinates.
 */
+ (const double)getAirDistanceBetweenCoordinate:(CLLocationCoordinate2D)start andCoordinate:(CLLocationCoordinate2D)end;

+ (const double)distanceBetweenStartPoint:(CGPoint)startP andEndPoint:(CGPoint)endP;

/**
 * This method will check if the two locations are the same within a error margin
 */
+ (BOOL)isSameLocation:(CLLocationCoordinate2D)firstLocation asLocation:(CLLocationCoordinate2D)secondLocation;
/**
 * This method will check if the two directions are the same within a error margin
 */
+ (BOOL)isSameHeading:(CLLocationDirection)firstHeading asHeading:(CLLocationDirection)secondHeading;
/**
 * This method computes the distance and nereast point to a segment
 */
+ (CGPoint)nearestPointToPoint:(CGPoint)origin onLineSegmentPointA:(CGPoint)pointA pointB:(CGPoint)pointB distance:(double *)distance;

+ (NSArray *)metricDistanceArray:(NSInteger)meters;
+ (NSString *)metricDistanceFormatter:(NSInteger)meters;
+ (NSArray *)imperialDistanceArray:(NSInteger)meters;
+ (NSString *)imperialDistanceFormatter:(NSInteger)meters;

+ (float)feetFromMeters:(NSInteger)meters;
+ (float)yardsFormMeters:(NSInteger)meters;
+ (float)milesFormMeters:(NSInteger)meters;

+ (float)kmPerHourFromMetersPerSecond:(NSInteger)meters;
+ (float)milesPerHourFromKmPerHour:(NSInteger)kmPerHour;
+ (BOOL)isUSCoordinate:(CLLocationCoordinate2D)coordinate;

@end

/* --------------------------------------------------*/

@interface OSVUtils (FileManager)

+ (NSString *)getDirectoryPath;

/**
 * This method will format the space in MB, GB
 */
+ (NSString *)memoryFormatter:(long long)space;
+ (NSString *)stringFromByteCount:(long long)bytes;
/**
 * This method will format the space in MB, GB ...
 * and return the size on the first value and unit at the second 
 * value int the array
 */
+ (NSArray *)arrayFormatedFromByteCount:(long long)bytes;

/**
 * This method returns a formated string representing total disk space.
 */
+ (NSString *)totalDiskSpace;
/**
 * This method returns a formated string representing free disk space.
 */
+ (NSString *)freeDiskSpace;
/**
 * This method returns a formated string representing total disk space.
 */
+ (NSString *)usedDiskSpace;

/**
 * This method returns total disk space in bytes
 */
+ (long long)totalDiskSpaceBytes;
/**
 * This method returns free disk space in bytes
 */
+ (long long)freeDiskSpaceBytes;
/**
 * This method returns used disk space in bytes
 */
+ (long long)usedDiskSpaceBytes;
/**
 * This method returns the size for a folder in bytes;
 */
+ (long long)sizeOfFolder:(NSString *)folderPath;
/**
 * This method returns the size for a folder in bytes and confirms if the folder contains or not png files;
 */
+ (long long)sizeOfFolder:(NSString *)directoryUrl containsImages:(BOOL *)contains;

@end

/* --------------------------------------------------*/

@interface OSVUtils (Image)
/**
 * This method returns a rotate image 
 */
+ (UIImage *)rotateImage:(UIImage *)image toImageOrientation:(UIImageOrientation)orient;


@end

