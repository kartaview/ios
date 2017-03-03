//
//  OSVTrackMatcher.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 12/12/2016.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import "OSVTrackMatcher.h"
#import <SKMaps/SKMaps.h>
#import "OSVLocationManager.h"
#import "OSVSyncController.h"
#import "OSVUserDefaults.h"
#import "OSVUtils.h"
#import "OSVServerSequence.h"

#import "UIColor+OSVColor.h"

#import "OSVLogger.h"

typedef struct {
    //noting Pn the point to that was matched on segment AB
    // distance from point Pn to AB
    double distance;
    // angle between the line defined by Pn and Pn-1 and the line AB
    double historycalAngle;
    
    CLLocationCoordinate2D start;
    CLLocationCoordinate2D end;
} MatchingParameters;

@interface OSVTrackMatcher ()

@property (strong, nonatomic) SKBoundingBox     *midBox;
@property (strong, nonatomic) SKBoundingBox     *loadedBox;

@property (strong, nonatomic) NSMutableArray    *bufferV;
@property (strong, nonatomic) NSMutableArray    *bufferM;

@property (strong, nonatomic) NSLock            *lock;

@property (assign, atomic) BOOL                 isMakingRequest;

@property (strong, nonatomic) SKMapView         *mapView;
@property (strong, nonatomic) OSVPolyline       *bestPolyline;

@property (strong, nonatomic) CLLocation        *prevLocation;

@end

@implementation OSVTrackMatcher

- (instancetype)init {
    self = [super init];
    if (self) {
        self.lock = [NSLock new];
        self.bufferV = [NSMutableArray array];
        self.bufferM = [NSMutableArray array];
        self.isMakingRequest = NO;
    }
    return self;
}

#pragma mark - Public

- (void)getTracksForMap:(SKMapView *)mapView withRegion:(SKCoordinateRegion)region {
    
    CLLocationCoordinate2D coordinate = [OSVLocationManager sharedInstance].currentMatchedPosition.coordinate;
    SKBoundingBox *box = [SKBoundingBox boundingBoxForRegion:region inMapViewWithSize:mapView.frame.size];

    self.mapView = mapView;

    [self getTracksForCoordinate:coordinate withBox:box];
}

- (void)getTracks {
    
    CLLocationCoordinate2D coordinate = [OSVLocationManager sharedInstance].currentMatchedPosition.coordinate;
    SKBoundingBox *box = [self boxAroundCoordinate:coordinate withDistance:500];
    
    [self getTracksForCoordinate:coordinate withBox:box];
}

- (OSVPolyline *)nearestPolylineToLocation:(CLLocation *)coordinate {
    OSVPolyline *bestPolyline = nil;
    double bestDistance = MAXFLOAT;
    
    CLLocation *originPoint = coordinate;
    [self.lock lock];
    for (OSVPolyline *polyline in self.bufferM) {
        
        if (polyline.coordinates.count == 1) {
            // we need at least 1 point
            
            CLLocation *spoint = polyline.coordinates[0];
            CLLocation *epoint = coordinate;
            double distance = [spoint distanceFromLocation:epoint];
            if (distance < bestDistance) {
                bestDistance = distance;
                bestPolyline = polyline;
            }
            continue;
        }
        
        for (NSInteger index = 0; index < polyline.coordinates.count - 1; index++) {
            CLLocation *startCoordinate = polyline.coordinates[index];
            CLLocation *endCoordinate = polyline.coordinates[index + 1];
            
            double distance;
            [OSVUtils nearestLocationToLocation:originPoint onLineSegmentLocationA:startCoordinate locationB:endCoordinate distance:&distance];
            
            if (distance < bestDistance) {
                bestDistance = distance;
                bestPolyline = polyline;
            }
        }
    }
    [self.lock unlock];
    
    if (bestPolyline && bestDistance < 25) {
       
        [self debugReder:bestPolyline];
        
        return bestPolyline;
    }
    
    return [OSVPolyline new];
}

//- (OSVPolyline *)nearestPolylineToLocation:(CLLocation *)coordinate {
//    OSVPolyline *bestPolyline = nil;
//    OSVPolyline *secBestPolyline = nil;
//    
//    MatchingParameters  bestPolylineParam;
//    bestPolylineParam.distance = MAXFLOAT;
//    bestPolylineParam.historycalAngle = 90;
//    
//    MatchingParameters  secBestPolylineParam;
//    secBestPolylineParam.distance = MAXFLOAT;
//    secBestPolylineParam.historycalAngle = 90;
//    
//    CLLocation *originPoint = coordinate;
//    CLLocation *prevOriginPoint = self.prevLocation;
//    
//    [self.lock lock];
//    for (OSVPolyline *polyline in self.bufferM) {
//        
//        if (polyline.coordinates.count == 1) {
//            // we need at least 1 point
//            
//            CLLocation *spoint = polyline.coordinates[0];
//            CLLocation *epoint = coordinate;
//            double distance = [spoint distanceFromLocation:epoint];
//            
//            if (distance < bestPolylineParam.distance) {
//                secBestPolylineParam.distance = bestPolylineParam.distance;
//                secBestPolylineParam.historycalAngle = 90;
//                secBestPolyline = bestPolyline;
//
//                bestPolylineParam.distance = distance;
//                bestPolylineParam.historycalAngle = 90;
//                bestPolyline = polyline;
//            }
//            
//            continue;
//        }
//        
//        for (NSInteger index = 0; index < polyline.coordinates.count - 1; index++) {
//            CLLocation *startCoordinate = polyline.coordinates[index];
//            CLLocation *endCoordinate = polyline.coordinates[index + 1];
//            
//            double distance;
//            [OSVUtils nearestLocationToLocation:originPoint
//                         onLineSegmentLocationA:startCoordinate
//                                      locationB:endCoordinate
//                                       distance:&distance];
//            
//            
//            if (distance < bestPolylineParam.distance) {
//                if (bestPolyline && bestPolyline != polyline) {
//                    secBestPolylineParam.distance = bestPolylineParam.distance;
//                    secBestPolylineParam.start = bestPolylineParam.start;
//                    secBestPolylineParam.end = bestPolylineParam.end;
//                    secBestPolylineParam.historycalAngle = 90;
//                    secBestPolyline = bestPolyline;
//                }
//                
//                bestPolylineParam.distance = distance;
//                bestPolylineParam.start = startCoordinate.coordinate;
//                bestPolylineParam.end = endCoordinate.coordinate;
//                bestPolylineParam.historycalAngle = 90;
//                bestPolyline = polyline;
//            }
//        }
//    }
//    [self.lock unlock];
//    
//    if (!self.prevLocation ||
//        [self.prevLocation distanceFromLocation:originPoint] > 20) {
//        self.prevLocation = originPoint;
//    }
//    
//    if (bestPolyline && bestPolylineParam.distance < 25) {
//        
//        if (prevOriginPoint &&
//            secBestPolyline != bestPolyline) {
//            if (bestPolylineParam.start.latitude != 0.0) {
//                bestPolylineParam.historycalAngle = [OSVUtils degreesBetweenLineAStart:bestPolylineParam.start
//                                                                              lineAEnd:bestPolylineParam.end
//                                                                            lineBStart:prevOriginPoint.coordinate
//                                                                              lineBEnd:originPoint.coordinate];
//                
//            }
//            
//            if (secBestPolylineParam.start.latitude != 0.0) {
//                secBestPolylineParam.historycalAngle = [OSVUtils degreesBetweenLineAStart:secBestPolylineParam.start
//                                                                                 lineAEnd:secBestPolylineParam.end
//                                                                               lineBStart:prevOriginPoint.coordinate
//                                                                                 lineBEnd:originPoint.coordinate];
//            }
//        }
//        
//        if (secBestPolyline &&
//            secBestPolylineParam.distance < 25 &&
//            bestPolylineParam.historycalAngle > secBestPolylineParam.historycalAngle + 10) {
//            //compare the angle of the most closest two polylines
//            //if the second most closes polyline is smaller then the best polyline with
//            //more then 30 degrees => second best polyline is more paralel
//            //=> bestPolyline is the second best polyline.
//            bestPolyline = secBestPolyline;
//        }
//        
//        [self debugReder:bestPolyline];
//        
//        return bestPolyline;
//    }
//    
//    return [OSVPolyline new];
//}

- (BOOL)hasCoverage {
    CLLocationCoordinate2D coordinate = [OSVLocationManager sharedInstance].currentMatchedPosition.coordinate;
    if (!self.loadedBox) {
        return NO;
    }
    
    return [self.loadedBox containsLocation:coordinate];
}

#pragma mark - Private

- (void)getTracksForCoordinate:(CLLocationCoordinate2D)coordinate withBox:(SKBoundingBox *)box {
    BOOL hasCoverage = self.hasCoverage;
    BOOL midContainsTop = [self.midBox containsLocation:box.topLeftCoordinate];
    BOOL midContainsBot = [self.midBox containsLocation:box.bottomRightCoordinate];
//    NSLog(@"___x___ will send request");
    if ((!hasCoverage ||
        !midContainsTop ||
        !midContainsBot) &&
        !self.isMakingRequest) {
        
        self.midBox = [self boxAroundCoordinate:coordinate withDistance:1500];
        SKBoundingBox *loadedBox = [self boxAroundCoordinate:coordinate withDistance:2000];
        
        self.isMakingRequest = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            self.isMakingRequest = NO;
        });
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//            NSLog(@"___x___ %@", [NSString stringWithFormat:@"requested Box:%p h:%d, mt:%d mb:%d", loadedBox, hasCoverage, midContainsTop, midContainsBot]);
            [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"requested Box:%p h:%d, mt:%d mb:%d", loadedBox, hasCoverage, midContainsTop, midContainsBot]  withLevel:LogLevelDEBUG];
            __block NSError *e;
            
            [self.lock lock];
            self.bufferV = [NSMutableArray array];
            [self.lock unlock];
            
            [[OSVSyncController sharedInstance].tracksController getSerialServerTracksInBoundingBox:(id<OSVBoundingBox>)loadedBox withZoom:16 withPartialCompletion:^(id<OSVSequence> sequence, OSVMetadata *metadata, NSError *error) {
//                NSLog(@"___x___  tracks pages - %ld loaded metadataPageIndex %p",metadata.pageIndex, metadata);

                if (error) {
//                    NSLog(@"___x___ receiverd error");
                    e = error;
                }
                
                if (!sequence) {
//                    NSLog(@"___x___ receiverd no sequence");
                    [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"received no sequence in box:%p error:%@", loadedBox, error]  withLevel:LogLevelDEBUG];
                    return;
                }
                
                NSArray *track = [sequence.track mutableCopy];
                OSVPolyline *polyline = [OSVPolyline new];
                polyline.coordinates = track;
                polyline.coverage = sequence.coverage;
                
                if ([OSVUserDefaults sharedInstance].showMapWhileRecording) {
//                    NSLog(@"___x___ add Sequ");                  
                    [self.delegate addPolyline:polyline];
                }
                
                [self.lock lock];
                [self.bufferV addObject:polyline];
                [self.lock unlock];
            } completion:^(OSVMetadata *mf) {
//                NSLog(@"___x___ receiverd completion block, %ld", mf.totalPages);
                [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"received completion for Box:%p", loadedBox]  withLevel:LogLevelDEBUG];

                if (!e && self.loadedBox != loadedBox) {
                    self.isMakingRequest = NO;

                    [self.delegate moveToMap];
                    
                    self.bufferM = self.bufferV;
                    
                    self.loadedBox = loadedBox;
//                    NSLog(@"___x___ receiverd no erorr will render loadded box");
                    [[OSVLogger sharedInstance] logMessage:[NSString stringWithFormat:@"received Box:%p", loadedBox]  withLevel:LogLevelDEBUG];
                }
            }];
        });
    }
}

- (SKBoundingBox *)boxAroundCoordinate:(CLLocationCoordinate2D)coordinate withDistance:(double)meters {
    
    SKBoundingBox *box = [SKBoundingBox new];
    box.topLeftCoordinate = CLLocationCoordinate2DMake(coordinate.latitude + [self metersToDecimal:meters], coordinate.longitude - [self metersToDecimal:meters]);
    box.bottomRightCoordinate = CLLocationCoordinate2DMake(coordinate.latitude - [self metersToDecimal:meters], coordinate.longitude + [self metersToDecimal:meters]);
    
    return box;
}

- (double)metersToDecimal:(double)meters {
    return meters / 110000;
}

- (void)setLoadedBox:(SKBoundingBox *)loadedBox {
    _loadedBox = loadedBox;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kdidLoadNewBox" object:nil userInfo:@{}];
}

- (void)debugReder:(OSVPolyline *)bestPolyline {
    if ([OSVUserDefaults sharedInstance].debugMatcher && self.bestPolyline != bestPolyline) {
        if (self.bestPolyline) {
            UIColor *purpleColor = [UIColor colorWithHex:0xbd10e0];
            self.bestPolyline.fillColor = [purpleColor colorWithAlphaComponent:MIN(self.bestPolyline.coverage, 10.0)/10.0 + 0.01];
            self.bestPolyline.strokeColor = [purpleColor colorWithAlphaComponent:MIN(self.bestPolyline.coverage, 10.0)/10.0 + 0.01];
            [self.mapView addPolyline:self.bestPolyline];
        }
        
        bestPolyline.fillColor = [UIColor redColor];
        bestPolyline.strokeColor = [UIColor redColor];

        [self.mapView addPolyline:bestPolyline];
        self.bestPolyline = bestPolyline;
    }
}

@end
