//
//  OSVBasicMapController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 11/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVSyncController.h"
#import "OSVMapViewController.h"
#import "OSVMapStateProtocol.h"

@class SKPolyline;
@class SKAnnotation;
@class SKBoundingBox;

@interface OSVBasicMapController : NSObject <OSVMapStateProtocol>

@property (nonatomic, assign) int                       identifier;

- (void)addSequenceOnMap:(id<OSVSequence>)sequence;
- (void)showCurrentPostion:(BOOL)value;
- (void)didCreateMapAnnotation:(SKAnnotation *)annotation;

- (void)didEndRegionChange:(id<OSVBoundingBox>)box withZoomlevel:(double)zoom;
- (void)didTapAtCoordinate:(CLLocationCoordinate2D)coordinate;

- (void)zoomOnSequence:(id<OSVSequence>)seq;
- (void)zoomOnCurrentPosition;
- (void)clearAllCache;

@end
