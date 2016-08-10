//
//  OSVBasicMapController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 11/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVBasicMapController.h"
#import <SKMaps/SKMaps.h>
#import "UIColor+OSVColor.h"
#import <Crashlytics/Crashlytics.h>
#import "OSVUtils.h"
#import "OSVPolyline.h"

#import "OSVSequenceMapController.h"
#import "OSVServerSequence.h"
#import "OSVUserDefaults.h"

@interface OSVBasicMapController ()

@property (nonatomic, assign) NSInteger                 polylineID;
@property (nonatomic, strong) UIColor                   *colorPurple;
@property (nonatomic, strong) NSArray                   *localSeq;

@end

@implementation OSVBasicMapController

@synthesize viewController;
@synthesize syncController;

#pragma mark - Public

- (instancetype)init {
    self = [super init];
    if (self) {
        self.syncController = [OSVSyncController sharedInstance];
        
        self.colorPurple = [UIColor colorWithHex:0xbd10e0];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishCreatingSequence:) name:@"didFinishCreatingSequence" object:nil];
    }
    
    return self;
}

- (void)willChangeUIControllerFrom:(id<OSVMapStateProtocol>)controller animated:(BOOL)animated {
    self.localSeq = nil;
    [self addLocalSequences];

    self.viewController.bottomRightButton.hidden = NO;
    
    [self.viewController.bottomRightButton setImage:[UIImage imageNamed:@"recenter"] forState:UIControlStateNormal];  
   
    [self showCurrentPostion:YES];
    [self.viewController.mapView removeAnnotationWithID:kCurrentAnnotationID];
    
    if (animated) {
        [self didTapBottomRightButton];
    }
}

- (void)reloadVisibleTracks {
    CLLocationCoordinate2D coordinateTop = [self.viewController.mapView coordinateForPoint:CGPointZero];
    CLLocationCoordinate2D coordinateBottomRight = [self.viewController.mapView coordinateForPoint:CGPointMake(CGRectGetMaxX(self.viewController.view.frame), CGRectGetMaxY(self.viewController.view.frame))];
    
    if (!isnan(coordinateTop.longitude) && !isnan(coordinateTop.longitude) && !isnan(coordinateBottomRight.latitude) && !isnan(coordinateBottomRight.longitude)) {
        SKBoundingBox *box = [SKBoundingBox boundingBoxWithTopLeftCoordinate:coordinateTop bottomRightCoordinate:coordinateBottomRight];
        [self requestAndDisplayAllSequencesOnMapInBoundingBox:(id<OSVBoundingBox>)box withZoom:self.viewController.mapView.visibleRegion.zoomLevel] ;
    }
}

- (void)didReceiveMemoryWarning {
    [self clearAllCache];
}

- (void)clearAllCache{
}

- (void)didTapBottomRightButton {
    if ([CLLocationManager authorizationStatus] ==  kCLAuthorizationStatusNotDetermined) {
        [[SKPositionerService sharedInstance] startLocationUpdate];
    } else {
        [self.viewController.mapView centerOnCurrentPosition];
        [self.viewController.mapView animateToZoomLevel:14];
    }
}

- (void)didEndRegionChange:(id<OSVBoundingBox>)box withZoomlevel:(double)zoom {
    if (self.viewController.controller == self) {
        [self requestAndDisplayAllSequencesOnMapInBoundingBox:box  withZoom:zoom];
    }
}

- (void)didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    if ([self.viewController.actIndicator isAnimating]) {
        return;
    }
    self.viewController.actIndicator.hidden = NO;
    [self.viewController.actIndicator startAnimating];
    [self.syncController.tracksController getLayersFromLocation:coordinate withCompletion:^(NSArray *array, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (array.count) {
                [self.viewController performSegueWithIdentifier:@"showLayers" sender:array];
            }
            [self.viewController.actIndicator stopAnimating];
            self.viewController.actIndicator.hidden = YES;
        });
    }];
}

int iii = 0;

- (void)addSequenceOnMap:(id<OSVSequence>)sequence {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *track = [self getTrackForSequence:sequence];
        OSVPolyline *polyline = [OSVPolyline new];
        polyline.lineWidth = 6;
        polyline.backgroundLineWidth = 6;
        polyline.coordinates = track;
        polyline.identifier = iii++;
        if ([sequence isKindOfClass:[OSVSequence class]]) {
            polyline.fillColor = [UIColor blackColor];
        } else {
            polyline.fillColor = self.colorPurple;
        }
        
        polyline.isLocal = YES;
        [self.viewController.mapView addPolyline:polyline];
    });
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

- (void)zoomOnSequence:(id<OSVSequence>)seq {
    SKBoundingBox *box = [SKBoundingBox new];
    box.topLeftCoordinate = seq.topLeftCoordinate;
    box.bottomRightCoordinate = seq.bottomRightCoordinate;

    [self.viewController.mapView fitBounds:box withInsets:UIEdgeInsetsMake(20, 20, 20, 20)];
}

- (void)zoomOnCurrentPosition {
    [self.viewController.mapView centerOnCurrentPosition];
}

- (OSVPolyline *)nearestPolylineLocationToCoordinate:(CLLocationCoordinate2D)coordinate index:(NSInteger *)index {
//    OSVPolyline *bestPolyline = nil;
//    NSInteger bestIndex = 0;
//    double bestDistance = DBL_MAX;
//
//    CGPoint originPoint = [self.viewController.mapView pointForCoordinate:coordinate];
    
//    for (OSVPolyline *polyline in self.viewController.polylines) {
//        if (!polyline.coordinates.count) {
//            continue;
//        }
//        
//        if (polyline.coordinates.count && polyline.coordinates.count < 2) { // we need at least 2 points: start and end
//            CGPoint spoint = [self.viewController.mapView pointForCoordinate:((CLLocation *)polyline.coordinates[0]).coordinate];
//            CGPoint epoint = [self.viewController.mapView pointForCoordinate:coordinate];
//            double distance = [OSVUtils distanceBetweenStartPoint:spoint andEndPoint:epoint];
//            if (distance < bestDistance) {
//                bestIndex = 0;
//                bestDistance = distance;
//                bestPolyline = polyline;
//            }
//            continue;
//        }
//        
//        for (NSInteger index = 0; index < polyline.coordinates.count - 1; index++) {
//            CLLocation *startCoordinate = polyline.coordinates[index];
//            CGPoint startPoint = [self.viewController.mapView pointForCoordinate:startCoordinate.coordinate];
//            CLLocation *endCoordinate = polyline.coordinates[index + 1];
//            CGPoint endPoint = [self.viewController.mapView pointForCoordinate:endCoordinate.coordinate];
//            double distance;
//            [OSVUtils nearestPointToPoint:originPoint onLineSegmentPointA:startPoint pointB:endPoint distance:&distance];
//            
//            if (distance < bestDistance) {
//                bestDistance = distance;
//                bestPolyline = polyline;
//                bestIndex = index;
//            }
//        }
//    }
    
//    if (bestDistance < 25) {
//        *index = bestIndex;
//        return bestPolyline;
//    }
    
    return nil;
}

#pragma mark - Private

- (void)requestAndDisplayAllSequencesOnMapInBoundingBox:(id<OSVBoundingBox>)box withZoom:(double)zoom {
    if ([OSVUtils getAirDistanceBetweenCoordinate:box.topLeftCoordinate andCoordinate:box.bottomRightCoordinate] < 400 * 1000) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

            [self.syncController.tracksController getServerTracksInBoundingBox:box withZoom:zoom withPartialCompletion:^(id<OSVSequence> sequence, OSVMetadata *metadata, NSError *error) {
    //TODO: refactor the line below..
                if (![self.viewController.navigationController.viewControllers.firstObject isKindOfClass:[OSVMapViewController class]]) {
                    [self.viewController.mapView clearAllOverlays];
                } else {
                    if (metadata.pageIndex == 0) {
                        [self.viewController.mapView clearAllOverlays];
                        [self addLocalSequences];
                    }
                    
                    [self addSequenceOnMap:sequence];
                }
            }];
        });
    } else {
        [self.viewController.mapView clearAllOverlays];
    }
}

- (void)addLocalSequences {
    if (self.localSeq.count) {
        for (OSVSequence *sequence in self.localSeq) {
            if (!sequence) {
                return;
            }
            // this should not caches
            [self addSequenceOnMap:sequence];
        }
    } else {
        [self.syncController.tracksController getLocalSequencesWithCompletion:^(NSArray *sequences) {
            self.localSeq = sequences;
            for (OSVSequence *sequence in sequences) {
                if (!sequence) {
                    return;
                }
                // this should not caches
                [self addSequenceOnMap:sequence];
            }
        }];
    }
}

- (void)orderPhotosIntoSequence:(OSVSequence *)sequence {
    sequence.photos = [NSMutableArray arrayWithArray:[sequence.photos sortedArrayUsingComparator:^NSComparisonResult(id<OSVPhoto> photoA, id<OSVPhoto> photoB) {
        NSInteger first = photoA.photoData.sequenceIndex;
        NSInteger second = photoB.photoData.sequenceIndex;
        if (first < second) {
            return NSOrderedAscending;
        } else if (first == second) {
            return NSOrderedSame;
        } else {
            return NSOrderedDescending;
        }
    }]];
}

- (void)showCurrentPostion:(BOOL)value {
    self.viewController.mapView.settings.showCurrentPosition = value;
    self.viewController.mapView.settings.showAccuracyCircle = value;
}

- (void)didCreateMapAnnotation:(SKAnnotation *)annotation {
    [self.viewController.mapView addAnnotation:annotation withAnimationSettings:[SKAnimationSettings animationSettings]];
}

- (void)didFinishCreatingSequence:(NSNotification *)notification {
    NSNumber *uid = notification.userInfo[@"sequenceID"];
    [self.syncController.tracksController getLocalSequenceWithID:[uid integerValue] completion:^(OSVSequence *seq) {
//        [self addSequenceOnMap:seq];
    }];
}


@end