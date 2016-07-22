//
//  RLMPhoto.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 14/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIImage.h>
#import <Realm/Realm.h>

@interface RLMPhoto : RLMObject

@property (nonatomic, strong) NSString  *addressName;

@property (nonatomic, strong) NSDate    *timestamp;

//location
@property (nonatomic, assign) double                latitude;
@property (nonatomic, assign) double                longitude;
@property (nonatomic, assign) CLLocationDistance    altitude;
@property (nonatomic, assign) CLLocationDirection   course;
@property (nonatomic, assign) CLLocationAccuracy    horizontalAccuracy;
@property (nonatomic, assign) CLLocationAccuracy    verticalAccuracy;
@property (nonatomic, assign) CLLocationSpeed       speed;

@property (nonatomic, assign) NSInteger localSequenceID;
@property (nonatomic, assign) NSInteger serverSequenceID;
@property (nonatomic, assign) NSInteger sequenceIndex;

@property (nonatomic, assign) NSString  *localPhotoID;

@property (nonatomic, assign) BOOL      hasOBD;

@property (nonatomic, assign) NSInteger videoIndex;

@end

RLM_ARRAY_TYPE(RLMPhoto);
