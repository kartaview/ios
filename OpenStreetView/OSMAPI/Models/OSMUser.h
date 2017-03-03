//
//  OSMUser.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 14/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface OSMUser : NSObject

@property (nonatomic, assign) NSInteger                 userID;
@property (nonatomic, strong) NSString                  *name;
@property (nonatomic, strong) NSDate                    *creationDate;
@property (nonatomic, strong) NSString                  *profilePictureURL;
@property (nonatomic, assign) NSInteger                 changesetsCount;
@property (nonatomic, assign) NSInteger                 tracesCount;
@property (nonatomic, assign) CLLocationCoordinate2D    homeCoordinate;
@property (nonatomic, strong) NSString                  *descriptions;

@property (nonatomic, strong) NSString                  *providerKey;
@property (nonatomic, strong) NSString                  *providerSecret;
@property (nonatomic, strong) NSString                  *provider;

@end
