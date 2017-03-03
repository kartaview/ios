//
//  OSVSequence.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 20/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol OSVPhoto;

@protocol OSVSequence <NSObject>

@property (nonatomic, assign) NSInteger                     uid;
@property (nonatomic, strong) NSDate                        *dateAdded;
@property (nonatomic, strong) NSMutableArray<id<OSVPhoto>>  *photos; // an array containing all the photo objects

@property (nonatomic, strong) NSArray                       *track; // an array of locations representing the tack

@property (nonatomic, assign) CLLocationCoordinate2D        topLeftCoordinate;
@property (nonatomic, assign) CLLocationCoordinate2D        bottomRightCoordinate;

@property (nonatomic, assign) long long                     sizeOnDisk;
@property (nonatomic, assign) double                        length; // the lenght of the track expresed in meters

@property (nonatomic, assign) BOOL                          hasOBD;
@property (nonatomic, strong) NSString                      *location;
@property (nonatomic, strong) NSString                      *previewImage;
@property (nonatomic, assign) NSInteger                     coverage;

- (BOOL)intersectWithTopLeftCoordinate:(CLLocationCoordinate2D)topLeftCoordinate andBottomRightCoordinate:(CLLocationCoordinate2D)bottomRightCoordinate;

@end


@interface OSVSequence : NSObject <OSVSequence>

@property (nonatomic, assign) NSInteger                     uploadID; // the id used to upload a sequence of photos
@property (nonatomic, assign) NSInteger                     points;
@property (nonatomic, strong) NSMutableArray                *scoreHistory;
@property (nonatomic, strong) NSMutableDictionary           *videos;

@end
