//
//  OSVCameraMapManager.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 19/08/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SKMaps/SKMaps.h>
#import "OSVPolyline.h"

@class OSVTrackMatcher;

@interface OSVCameraMapManager : NSObject

@property (nonatomic, strong) OSVTrackMatcher   *matcher;

- (instancetype)initWithMap:(SKMapView *)view;

- (void)addPolyline:(id)sequence;
- (void)moveToMap;


@end
