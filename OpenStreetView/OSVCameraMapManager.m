//
//  OSVCameraMapManager.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 19/08/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVCameraMapManager.h"
#import "OSVSyncController.h"
#import "OSVPolyline.h"
#import "UIColor+OSVColor.h"
#import "OSVUtils.h"
#import "OSVLocationManager.h"
#import "OSVTrackMatcher.h"
#import "OSVUserDefaults.h"

@interface OSVCameraMapManager () <SKMapViewDelegate>

@property (strong, nonatomic) SKMapView *mapView;
@property (strong, nonatomic) UIColor   *colorPurple;

@property (assign, nonatomic) BOOL first;

@property (assign, nonatomic) BOOL isRequestingView;

@property (assign, nonatomic) BOOL isRequestingTop;
@property (assign, nonatomic) BOOL isRequestingBot;
@property (assign, nonatomic) BOOL isRequestingLeft;
@property (assign, nonatomic) BOOL isRequestingRight;

@property (strong, nonatomic) NSMutableArray *bufferV;
@property (strong, nonatomic) NSMutableArray *bufferN;

@property (strong, nonatomic) SKBoundingBox *viewBox;
@property (strong, nonatomic) SKBoundingBox *midBox;
@property (strong, nonatomic) SKBoundingBox *loadedBox;

@property (assign, nonatomic) NSInteger     bestIndex;

@property (strong, nonnull) NSLock          *lock;

@end

@implementation OSVCameraMapManager

- (instancetype)initWithMap:(SKMapView *)view {
    self = [super init];
    if (self) {
        self.first = YES;

        self.mapView = view;
		self.mapView.delegate = self;
		self.mapView.clipsToBounds = YES;
		
		self.mapView.mapScaleView.hidden = YES;

		self.mapView.settings.showHouseNumbers = NO;
		self.mapView.settings.showCompass = NO;
		self.mapView.settings.displayMode = SKMapDisplayMode2D;
		self.mapView.settings.showStreetNamePopUps = YES;
		self.mapView.settings.osmAttributionPosition = SKOSMAttributionPositionTopLeft;
		self.mapView.settings.panningEnabled = NO;
		
		SKMapZoomLimits zoomLimits;
		zoomLimits.mapZoomLimitMax = 20;
		zoomLimits.mapZoomLimitMin = 15;
		self.mapView.settings.zoomLimits = zoomLimits;
		
		SKCoordinateRegion region;
		region.zoomLevel = [OSVUserDefaults sharedInstance].zoomLevel;
		region.center = [OSVLocationManager sharedInstance].currentLocation.coordinate;
		self.mapView.visibleRegion = region;
		
        self.colorPurple = [UIColor colorWithHex:0xbd10e0];
        self.bufferV = [NSMutableArray array];
        self.bufferN = [NSMutableArray array];

        self.matcher = [OSVTrackMatcher new];
        self.matcher.delegate = self;
        self.lock = [NSLock new];
    }
    
    return self;
}

- (void)mapView:(SKMapView *)mapView didChangeToRegion:(SKCoordinateRegion)region {
    [self.matcher getTracksForMap:self.mapView withRegion:region];
}

- (void)mapView:(SKMapView *)mapView didEndRegionChangeToRegion:(SKCoordinateRegion)region {
	if (region.zoomLevel <= 20 && region.zoomLevel >= 15) {
		[OSVUserDefaults sharedInstance].zoomLevel = region.zoomLevel;
		[[OSVUserDefaults sharedInstance] save];
	}
}
	
- (void)addPolyline:(OSVPolyline *)polyline {
    [self.lock lock];
        [self.bufferN addObject:polyline];
    [self.lock unlock];
}

int _iii_ = 0;

- (void)moveToMap {
    
    [self.lock lock];
//    NSLog(@"___x___ %p - %ld,  %p - %ld", self.bufferV, self.bufferV.count, self.bufferN, self.bufferN.count);

    for (NSNumber *uid in self.bufferV) {
        [self.mapView clearOverlayWithID:(int)[uid integerValue]];
    }
    self.bufferV = [NSMutableArray array];
    
    for (OSVPolyline *polyline in self.bufferN) {
        
        if (_iii_ > 3000) {
            _iii_ = 0;
        }
        
        polyline.identifier = _iii_;
        polyline.lineWidth = 6;
        polyline.backgroundLineWidth = 6;
        polyline.fillColor = [self.colorPurple colorWithAlphaComponent:MIN(polyline.coverage, 10.0)/10.0 + 0.01];
        polyline.strokeColor = [self.colorPurple colorWithAlphaComponent:MIN(polyline.coverage, 10.0)/10.0 + 0.01];
        
        [self.bufferV addObject:@(_iii_)];
        
        _iii_ += 1;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.mapView addPolyline:polyline];
        });
    }
    
    self.bufferN = [NSMutableArray array];
    
    [self.lock unlock];
}

@end
