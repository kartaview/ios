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

@property (strong, nonatomic) NSMutableArray *bufferT;
@property (strong, nonatomic) NSMutableArray *bufferB;
@property (strong, nonatomic) NSMutableArray *bufferL;
@property (strong, nonatomic) NSMutableArray *bufferR;

@property (strong, nonatomic) SKBoundingBox *viewBox;

@end

@implementation OSVCameraMapManager

- (instancetype)initWithMap:(SKMapView *)view {
    self = [super init];
    if (self) {
        self.first = YES;

        self.mapView = view;
        self.mapView.delegate = self;
        self.colorPurple = [UIColor colorWithHex:0xbd10e0];
        self.bufferV = [NSMutableArray array];
    }
    
    return self;
}

- (void)mapView:(SKMapView *)mapView didChangeToRegion:(SKCoordinateRegion)region {
    if (self.first) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self addTracksOnMapWithRegion:region];
            self.first = NO;
        });
    } else {
        [self addTracksOnMapWithRegion:region];
    }
}


- (void)addTracksOnMapWithRegion:(SKCoordinateRegion)region {
    SKBoundingBox *box = [SKBoundingBox boundingBoxForRegion:region inMapViewWithSize:self.mapView.frame.size];
    
    double diagonalTopL = [OSVUtils getAirDistanceBetweenCoordinate:box.topLeftCoordinate andCoordinate:self.viewBox.topLeftCoordinate];
    double diagonalBotR = [OSVUtils getAirDistanceBetweenCoordinate:box.bottomRightCoordinate andCoordinate:self.viewBox.bottomRightCoordinate];
    
    CLLocationCoordinate2D boxTopRight = CLLocationCoordinate2DMake(box.topLeftCoordinate.latitude, box.bottomRightCoordinate.longitude);
    CLLocationCoordinate2D boxBotLeft = CLLocationCoordinate2DMake(box.bottomRightCoordinate.latitude, box.topLeftCoordinate.longitude);
    CLLocationCoordinate2D viewTopRight = CLLocationCoordinate2DMake(self.viewBox.topLeftCoordinate.latitude, self.viewBox.bottomRightCoordinate.longitude);
    CLLocationCoordinate2D viewBotLeft = CLLocationCoordinate2DMake(self.viewBox.bottomRightCoordinate.latitude, self.viewBox.topLeftCoordinate.longitude);
    
    double diagonalTopR = [OSVUtils getAirDistanceBetweenCoordinate:boxTopRight andCoordinate:viewTopRight];
    double diagonalBotL = [OSVUtils getAirDistanceBetweenCoordinate:boxBotLeft andCoordinate:viewBotLeft];
    
    double diagonal = [OSVUtils getAirDistanceBetweenCoordinate:self.viewBox.topLeftCoordinate andCoordinate:self.viewBox.bottomRightCoordinate];
    
    if (((![self.viewBox containsLocation:box.bottomRightCoordinate] && ![self.viewBox containsLocation:box.topLeftCoordinate]) ||
         !self.isRequestingView) &&
        (diagonalTopL  / diagonal < 0.4   ||
         diagonalBotR  / diagonal < 0.4   ||
         diagonalTopR  / diagonal < 0.4   ||
         diagonalBotL  / diagonal < 0.4   ||
         ![self.viewBox containsLocation:box.topLeftCoordinate] ||
         ![self.viewBox containsLocation:box.bottomRightCoordinate]) ) {
            
            self.isRequestingView = YES;
            self.viewBox = [SKBoundingBox new];
            self.viewBox.topLeftCoordinate = CLLocationCoordinate2DMake(box.topLeftCoordinate.latitude + 0.02, box.topLeftCoordinate.longitude - 0.02);
            self.viewBox.bottomRightCoordinate = CLLocationCoordinate2DMake(box.bottomRightCoordinate.latitude - 0.02, box.bottomRightCoordinate.longitude + 0.02);
            
            [self deleteBuffer:self.bufferV];
            self.bufferV = [NSMutableArray array];
            
            NSLog(@"requested view");

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [[OSVSyncController sharedInstance].tracksController getServerTracksInBoundingBox:(id<OSVBoundingBox>)self.viewBox withZoom:region.zoomLevel withPartialCompletion:^(id<OSVSequence> sequence, OSVMetadata *metadata, NSError *error) {
                    if ([metadata isLastPage] || error || !sequence) {
                        self.isRequestingView = NO;
                    }
                    
                    [self addSequenceOnMap:sequence];
                    [self.bufferV addObject:@(_iii_)];
                }];
            });
        }
}

int _iii_ = 0;

- (void)addSequenceOnMap:(id<OSVSequence>)sequence {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *track = [self getTrackForSequence:sequence];
        OSVPolyline *polyline = [OSVPolyline new];
        polyline.lineWidth = 6;
        polyline.backgroundLineWidth = 6;
        polyline.coordinates = track;
        if (_iii_ > 2000) {
            _iii_ = 0;
        }
        polyline.identifier = _iii_++;

        if ([sequence isKindOfClass:[OSVSequence class]]) {
            polyline.fillColor = [UIColor blackColor];
        } else {
            polyline.fillColor = self.colorPurple;
        }
        
        polyline.isLocal = YES;
        [self.mapView addPolyline:polyline];
    });
}


- (void)deleteBuffer:(NSMutableArray *)array {
    for (NSNumber *uid in array) {
        [self.mapView clearOverlayWithID:(int)[uid integerValue]];
    }
}

- (NSMutableArray *)getTrackForSequence:(id<OSVSequence>)sequence {
    
    NSMutableArray *positions;
    if ([sequence isKindOfClass:[OSVSequence class]] || !sequence.track.count) {
        positions = [NSMutableArray array];
        for (OSVPhoto *photo in sequence.photos) {
            CLLocation *location = photo.photoData.location;
            [positions addObject:location];
        }
    } else {
        positions = [sequence.track mutableCopy];
    }
    
    return positions;
}

@end
