//
//  OSVUtils+Location.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 23/10/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVUtils.h"

#define kDeg2RadFactor M_PI / 180.0
#define kEarthRadius 6367444
#define kEpsilon 0.00003
#define kKM 1000.0f

@implementation OSVUtils (Location)

+ (const double)getAirDistanceBetweenCoordinate:(CLLocationCoordinate2D)start andCoordinate:(CLLocationCoordinate2D)end {
    const double point_A_long = start.longitude;
    const double point_A_lat = start.latitude;
    const double point_B_long = end.longitude;
    const double point_B_lat = end.latitude;
    
    if ((point_A_long == 0.0 && point_A_lat == 0.0) || (point_B_long == 0.0 && point_B_lat == 0.0)) {
        return -1;
    }
    
    // Convert degrees to radians
    const double pA_long_RAD = (point_A_long * kDeg2RadFactor);
    const double pA_lat_RAD = (point_A_lat * kDeg2RadFactor);
    const double pB_long_RAD = (point_B_long * kDeg2RadFactor);
    const double pB_lat_RAD = (point_B_lat * kDeg2RadFactor);
    
    /*
     * Side a and b are the angles from the pole to the latitude (=> 90 -
     * latitude). Gamma is the angle between the longitudes measured at the
     * pole. The missing side c can be calculated with the given sides a and
     * b and the angle gamma. Therefore the spherical law of cosines is
     * used.
     */
    const double cosb = cos(M_PI_2 - pA_lat_RAD);
    const double cosa = cos(M_PI_2 - pB_lat_RAD);
    const double cosGamma = cos(pB_long_RAD - pA_long_RAD);
    const double sina = sin(M_PI_2 - pA_lat_RAD);
    const double sinb = sin(M_PI_2 - pB_lat_RAD);
    
    /*
     * Law of cosines for the sides (Spherical trigonometry) cos(c) = cos(a)
     * * cos(b) + sin(a) * sin(b) * cos(Gamma)
     */
    double cosc = cosa * cosb + sina * sinb * cosGamma;
    
    // Limit the cosine from 0 to 180 degrees.
    if (cosc < -1) {
        cosc = -1;
    }
    if (cosc > 1) {
        cosc = 1;
    }
    
    // Calculate the angle in radians for the distance
    const double side_c = acos(cosc);
    
    // return the length in meter by multiplying the angle with
    // the standard sphere radius.
    return MAX(0.0, kEarthRadius * side_c);
}

+ (const double)distanceBetweenStartPoint:(CGPoint)startP andEndPoint:(CGPoint)endP {
    return sqrt((startP.x - endP.x) * (startP.x - endP.x) + (startP.y - endP.y) * (startP.y - endP.y));
}

+ (CGPoint)nearestPointToPoint:(CGPoint)origin onLineSegmentPointA:(CGPoint)pointA pointB:(CGPoint)pointB distance:(double *)distance {
    CGPoint dAP = CGPointMake(origin.x - pointA.x, origin.y - pointA.y);
    CGPoint dAB = CGPointMake(pointB.x - pointA.x, pointB.y - pointA.y);
    CGFloat dot = dAP.x * dAB.x + dAP.y * dAB.y;
    CGFloat squareLength = dAB.x * dAB.x + dAB.y * dAB.y;
    CGFloat param = dot / squareLength;
    
    CGPoint nearestPoint;
    if (param < 0 || (pointA.x == pointB.x && pointA.y == pointB.y)) {
        nearestPoint.x = pointA.x;
        nearestPoint.y = pointA.y;
    } else if (param > 1) {
        nearestPoint.x = pointB.x;
        nearestPoint.y = pointB.y;
    } else {
        nearestPoint.x = pointA.x + param * dAB.x;
        nearestPoint.y = pointA.y + param * dAB.y;
    }
    
    CGFloat dx = origin.x - nearestPoint.x;
    CGFloat dy = origin.y - nearestPoint.y;
    *distance = sqrtf(dx * dx + dy * dy);
    
    return nearestPoint;
}

+ (BOOL)isSameLocation:(CLLocationCoordinate2D)firstLocation asLocation:(CLLocationCoordinate2D)secondLocation {
    //this gives 1m precision
    return  fabs(firstLocation.latitude - secondLocation.latitude) <= kEpsilon &&
            fabs(firstLocation.longitude - secondLocation.longitude) <= kEpsilon;
}

+ (BOOL)isSameHeading:(CLLocationDirection)firstHeading asHeading:(CLLocationDirection)secondHeading {
    return fabs(firstHeading - secondHeading) <= kEpsilon;
}

+ (NSArray *)metricDistanceArray:(NSInteger)meters {
    NSString *formatted;
    NSString *unit;
    double kmeters = meters / kKM;
    if (kmeters >= 0.5) {
        formatted = [NSString stringWithFormat:@"%.1f", kmeters];
        unit = @" KM";
    } else {
        formatted = [NSString stringWithFormat:@"%ld", (long)meters];
        unit = @" M";
    }
    
    return @[formatted, unit];
}

+ (NSString *)metricDistanceFormatter:(NSInteger)meters {
    NSString *formatted;
    double kmeters = meters / kKM;
    if (kmeters >= 0.5) {
        formatted = [NSString stringWithFormat:@"%.1f km", kmeters];
    } else {
        formatted = [NSString stringWithFormat:@"%ld m", (long)meters];
    }

    return formatted;
}

+ (NSArray *)imperialDistanceArray:(NSInteger)meters {
    float feet = [self feetFromMeters:meters];
    float miles = [self milesFormMeters:meters];
    if (feet >= 1500.0) {
        NSString *distance = miles > 10.0 ? [NSString stringWithFormat:@"%d ", (int)miles] : [NSString stringWithFormat:@"%.1f ", miles];
        
        return @[distance, @" MI"];
    } else {
        NSString *distance = [NSString stringWithFormat:@"%d ", (int)feet > 100 ? (int)feet / 10 * 10:(int)feet];
        
        return @[distance, @" FT"];
    }
}


+ (NSString *)imperialDistanceFormatter:(NSInteger)meters {
    float feet = [self feetFromMeters:meters];
    float miles = [self milesFormMeters:meters];
    if (feet >= 1500.0) {
        return miles > 10.0 ? [NSString stringWithFormat:@"%d mi", (int)miles] : [NSString stringWithFormat:@"%.1f mi", miles];
    } else {
        return [NSString stringWithFormat:@"%d ft", (int)feet > 100 ? (int)feet / 10 * 10:(int)feet];
    }
}

+ (float)feetFromMeters:(NSInteger)meters {
    return  meters * 3.2808398950131;
}

+ (float)yardsFormMeters:(NSInteger)meters {
    return meters * 1.0936132983377;
}

+ (float)milesFormMeters:(NSInteger)meters {
    return meters * 0.00062137119223733;
}

+ (float)kmPerHourFromMetersPerSecond:(NSInteger)meters {
    return meters * 3.6;
}

+ (float)milesPerHourFromKmPerHour:(NSInteger)kmPerHour {
    return kmPerHour * 0.621371;
}

+ (BOOL)isUSCoordinate:(CLLocationCoordinate2D)coordinate {
    BOOL result = NO;
    
    double latTopLeft = 72.441923;
    double longTopLeft = -171.454003;
    
    double latBottomRight = -55.636317;
    double longBottomRight = -22.889724;
    // is in US
    if (latTopLeft < coordinate.latitude && coordinate.latitude < latBottomRight &&
        longTopLeft > coordinate.longitude && coordinate.longitude > longBottomRight) {
        result = YES;
    } else {
        result = NO;
    }
    
    return result;
}


@end

#undef kDeg2RadFactor
#undef kEarthRadius
#undef kEpsilon
