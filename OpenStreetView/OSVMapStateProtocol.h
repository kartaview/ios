//
//  OSVMapStateProtocol.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 26/01/16.
//  Copyright © 2016 Bogdan Sala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSVMapViewController.h"
#import "OSVSyncController.h"

@protocol OSVMapStateProtocol <NSObject>

@property (nonatomic, weak) OSVMapViewController        *viewController;
@property (nonatomic, strong) OSVSyncController         *syncController;

- (void)willChangeUIControllerFrom:(id<OSVMapStateProtocol>)controller animated:(BOOL)animated;

- (void)didReceiveMemoryWarning;

- (void)didTapBottomRightButton;

- (void)reloadVisibleTracks;


@end
