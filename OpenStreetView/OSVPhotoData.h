//
//  OSVPhotoData.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 11/02/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface OSVPhotoData : NSObject;

/** The GPS coordinates where the photo was taken.
 */
@property (nonatomic, strong) CLLocation                *location;

@property (nonatomic, strong) NSString                  *addressName;

@property (nonatomic, assign) NSInteger                 sequenceIndex;
@property (nonatomic, assign) NSInteger                 videoIndex;

@property (nonatomic, assign) NSTimeInterval            timestamp;

@end
