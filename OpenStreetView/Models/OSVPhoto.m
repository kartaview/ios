//
//  OSMPhoto.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 15/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVPhoto.h"
#import "OSVUtils.h"
#import <QuartzCore/QuartzCore.h>

@implementation OSVPhoto

@synthesize imageName;
@synthesize image;
@synthesize imageData;
@synthesize photoData;
@synthesize thumbnail;
@synthesize serverSequenceId;
@synthesize correctionOrientation;
@synthesize hasOBD;

- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    } else if (!object || ![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    return [self isEqualToPhoto:object];
}

- (BOOL)isEqualToPhoto:(OSVPhoto *)photo {
    if (self == photo) {
        return YES;
    } else if (![OSVUtils isSameHeading:self.photoData.location.course asHeading:photo.photoData.location.course]) {
        return NO;
    } else if (![OSVUtils isSameLocation:self.photoData.location.coordinate asLocation:photo.photoData.location.coordinate]) {
        return NO;
    } else if (!(self.photoData.timestamp == photo.photoData.timestamp)) {
        return NO;
    } else if (![self.image isEqual:photo.image]) {
        return NO;
    }
    
    return YES;
}

@end
