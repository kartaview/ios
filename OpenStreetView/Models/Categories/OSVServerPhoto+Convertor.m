//
//  OSVPhoto+Convertor.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 18/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVServerPhoto+Convertor.h"
#import <CoreLocation/CoreLocation.h>

@implementation OSVServerPhoto (Convertor)

+ (OSVServerPhoto *)photoFromDictionary:(NSDictionary *)photoDictionary {
    NSString *string = photoDictionary[@"date_added_f"];
    NSDateFormatter *dateFormatter  =   [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd (HH:mm)"];
    NSDate *yourDate = [dateFormatter dateFromString:string];
    
    OSVServerPhoto *photo = [OSVServerPhoto new];
    photo.photoData = [OSVPhotoData new];
    photo.photoData.location = [[CLLocation alloc] initWithLatitude:[photoDictionary[@"lat"] floatValue] longitude:[photoDictionary[@"lng"] floatValue]];
    photo.photoData.sequenceIndex = [photoDictionary[@"sequence_index"] integerValue];
    photo.photoData.timestamp = [yourDate timeIntervalSince1970];
    
    photo.photoId = [photoDictionary[@"id"] integerValue];
    photo.serverSequenceId = [photoDictionary[@"sequence_id"] integerValue];
    photo.imageName = photoDictionary[@"name"];
    photo.thumbnailName = photoDictionary[@"th_name"];
    
    return photo;
}

+ (OSVServerPhoto *)photoFromPhoto:(OSVPhoto *)photo {
    
    return nil;
}

@end
