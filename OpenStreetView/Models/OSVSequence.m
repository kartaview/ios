//
//  OSVSequence.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 20/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import "OSVSequence.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation OSVSequence

@synthesize uid;
@synthesize dateAdded;
@synthesize photos;
@synthesize topLeftCoordinate;
@synthesize bottomRightCoordinate;
@synthesize sizeOnDisk;
@synthesize track;
@synthesize length;
@synthesize hasOBD;
@synthesize location;
@synthesize previewImage;

- (BOOL)intersectWithTopLeftCoordinate:(CLLocationCoordinate2D)tlCoordinate andBottomRightCoordinate:(CLLocationCoordinate2D)brCoordinate {
    if ((!self.topLeftCoordinate.latitude && !self.topLeftCoordinate.longitude) || (!self.bottomRightCoordinate.latitude && !self.bottomRightCoordinate.longitude)) {
        return NO;
    }
    
    if ((!tlCoordinate.latitude && !tlCoordinate.longitude) || (!brCoordinate.latitude && !brCoordinate.longitude)) {
        return NO;
    }
    
    CGRect rect1 = CGRectMake(tlCoordinate.latitude, tlCoordinate.longitude, tlCoordinate.latitude - brCoordinate.latitude, tlCoordinate.longitude - brCoordinate.longitude);
    CGRect rect2 = CGRectMake(self.topLeftCoordinate.latitude, self.topLeftCoordinate.longitude, self.topLeftCoordinate.latitude - self.bottomRightCoordinate.latitude, self.topLeftCoordinate.longitude - self.bottomRightCoordinate.longitude);
    return CGRectIntersectsRect(rect1, rect2);
}

@end
