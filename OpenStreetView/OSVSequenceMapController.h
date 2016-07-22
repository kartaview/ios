//
//  OSVSequenceMapController.h
//  OpenStreetView
//
//  Created by Bogdan Sala on 12/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVMapStateProtocol.h"
#import "OSVSyncController.h"
#import  <SKMaps/SKMaps.h>

#define kCurrentAnnotationID 360000

@interface OSVSequenceMapController : NSObject <UICollectionViewDataSource, UICollectionViewDelegate, SKMapViewDelegate, OSVMapStateProtocol>

- (void)didTapRightButton;

- (void)setSelectedCell;
- (void)displayItemAtIndex:(NSIndexPath *)indexPath;

@property (nonatomic, strong) NSIndexPath       *selectedIndexPath;

@end
