//
//  OSMPhoto+Relm.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 15/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVPhoto+Relm.h"

@implementation OSVPhoto (Relm)

- (RLMPhoto *)toRealmObject {
    
    RLMPhoto *photo = [[RLMPhoto alloc] init];
    photo.latitude  = self.photoData.location.coordinate.latitude;
    photo.longitude = self.photoData.location.coordinate.longitude;
    photo.altitude  = self.photoData.location.altitude;
    photo.course    = self.photoData.location.course;
    photo.speed     = self.photoData.location.speed;
    photo.horizontalAccuracy    = self.photoData.location.horizontalAccuracy;
    photo.verticalAccuracy      = self.photoData.location.verticalAccuracy;
    
    photo.sequenceIndex = self.photoData.sequenceIndex;
    photo.videoIndex    = self.photoData.videoIndex;
    
    photo.timestamp     = [NSDate dateWithTimeIntervalSince1970:self.photoData.timestamp];
    
    if (self.photoData.addressName) {
        photo.addressName = self.photoData.addressName;
    }
    
    photo.localSequenceID   = self.localSequenceId;
    photo.serverSequenceID  = self.serverSequenceId;
    photo.localPhotoID      = [@([photo.timestamp timeIntervalSince1970]) stringValue];
    photo.hasOBD            = self.hasOBD;
    
    return photo;
}

+ (OSVPhoto *)fromRealmObject:(RLMPhoto *)rlmObj {
    
    OSVPhoto *photo         = [OSVPhoto new];
    
    photo.serverSequenceId  = rlmObj.serverSequenceID;
    photo.localSequenceId   = rlmObj.localSequenceID;
    photo.hasOBD            = rlmObj.hasOBD;
    
    photo.photoData         = [OSVPhotoData new];
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(rlmObj.latitude, rlmObj.longitude);
    photo.photoData.location = [[CLLocation alloc] initWithCoordinate:coordinate altitude:rlmObj.altitude horizontalAccuracy:rlmObj.horizontalAccuracy verticalAccuracy:rlmObj.verticalAccuracy course:rlmObj.course speed:rlmObj.speed timestamp:rlmObj.timestamp];
    
    photo.photoData.sequenceIndex   = rlmObj.sequenceIndex;
    photo.photoData.addressName     = rlmObj.addressName;
    photo.photoData.videoIndex      = rlmObj.videoIndex;
    photo.photoData.timestamp       = [rlmObj.timestamp timeIntervalSince1970];
    
    return photo;
}

@end
