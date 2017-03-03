//
//  OSVTrackMatcher.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 12/12/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSVCameraMapManager.h"

@interface OSVTrackMatcher : NSObject

@property (strong, nonatomic) OSVCameraMapManager * _Nullable delegate;

- (void)getTracksForMap:(SKMapView * _Nonnull)mapView withRegion:(SKCoordinateRegion)region;
- (void)getTracks;

- (BOOL)hasCoverage;
- (OSVPolyline * _Nonnull)nearestPolylineToLocation:(CLLocation * _Nonnull)coordinate;

@end
