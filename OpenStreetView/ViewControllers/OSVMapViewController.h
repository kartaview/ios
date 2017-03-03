//
//  ViewController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 09/09/15.
//  Copyright (c) 2015 Bogdan Sala. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SKMaps/SKMaps.h>
#import "OSVSequence.h"
#import "OSVPolyline.h"

@class OSVSequenceMapController;
@class OSVBasicMapController;
@protocol OSVMapStateProtocol;

@interface OSVMapViewController : UIViewController

@property (strong, nonatomic) id<OSVMapStateProtocol>   controller;
@property (weak, nonatomic) IBOutlet UIView             *mapContainer;
@property (strong, nonatomic) SKMapView                 *mapView;

@property (weak, nonatomic) IBOutlet UIButton           *bottomRightButton;

@property (nonatomic, strong) id<OSVSequence>           selectedSequence;
@property (nonatomic, strong) OSVPolyline               *selectedPolyline;
@property (nonatomic, strong) NSArray                   *selectedLayers;

@property (strong, nonatomic) OSVBasicMapController     *mapController;
@property (strong, nonatomic) OSVSequenceMapController  *sequenceMapController;

@property (nonatomic, strong) NSMutableArray<NSNumber *>        *polylineIDs;

@property (nonatomic, assign) BOOL                              shouldDisplayBack;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView    *actIndicator;

@end

