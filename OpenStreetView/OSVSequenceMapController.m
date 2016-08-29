//
//  OSVSequenceMapController.m
//  OpenStreetView
//
//  Created by Bogdan Sala on 12/11/15.
//  Copyright © 2015 Bogdan Sala. All rights reserved.
//

#import "OSVSequenceMapController.h"
#import "OSVPhoto.h"
#import "OSVUtils.h"
#import "OSVImageCollectionViewCell.h"

#import "KAProgressLabel.h"
#import "OSVReachablityController.h"
#import "UIColor+OSVColor.h"

#import "OSVBasicMapController.h"
#import "UIAlertView+Blocks.h"

#define kSpacing 2

@interface OSVSequenceMapController ()

@property (nonatomic, strong) UIView            *annotationView;

@end

@implementation OSVSequenceMapController

@synthesize viewController;
@synthesize syncController;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.annotationView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_point_position"]];
        self.selectedIndexPath = nil;
        self.syncController = [OSVSyncController sharedInstance];
    }
    
    return self;
}

- (void)willChangeUIControllerFrom:(id<OSVMapStateProtocol>)controller animated:(BOOL)animated {
    
    self.viewController.bottomRightButton.hidden = YES;
    
    [self.viewController.mapController showCurrentPostion:NO];
    
    if (self.viewController.selectedPolyline && self.viewController.selectedPolyline.identifier != self.viewController.selectedSequence.uid) {
        if (self.viewController.selectedPolyline.isLocal) {
            self.viewController.selectedPolyline.fillColor = [UIColor hex258DBA];
            self.viewController.selectedPolyline.strokeColor = [UIColor hex258DBA];
        } else {
            self.viewController.selectedPolyline.fillColor = [UIColor hex68BDE3];
            self.viewController.selectedPolyline.strokeColor = [UIColor hex68BDE3];
        }
        
        [self.viewController.mapView addPolyline:self.viewController.selectedPolyline];
        self.viewController.selectedPolyline = nil;
    }
            
    [self.viewController performSegueWithIdentifier:@"presentReview" sender:self];
}

- (void)didReceiveMemoryWarning {
    NSArray *uids = [self.syncController.tracksController.cache clearLevelTwoCache];

    for (NSNumber *uid in uids) {
        [self.viewController.mapView clearOverlayWithID:[uid intValue]];
    }
}

- (void)reloadVisibleTracks {
    
}

#pragma mark - UICollectionViewDatasource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.viewController.selectedSequence.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    OSVImageCollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"collectionViewCell" forIndexPath:indexPath];
    if (!self.selectedIndexPath) {
        [self setSelectedCell];
    }
    
    id<OSVPhoto> photo = self.viewController.selectedSequence.photos[indexPath.row];

    [self.syncController.tracksController loadThumbnailForPhoto:photo intoImageView:cell.imageView withCompletion:^(id<OSVPhoto> completePhoto, NSError *error) {
        completePhoto.thumbnail = nil;
    }];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self setSelectedCell];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake((collectionView.frame.size.width - kSpacing*6)/5.0, (collectionView.frame.size.height - kSpacing * 2));
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return kSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return kSpacing;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0,kSpacing,0,0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    id<OSVPhoto> photo = self.viewController.selectedSequence.photos[indexPath.row];
    [self.viewController performSegueWithIdentifier:@"presentFullScreen" sender:photo];
}

#pragma mark - Actions

- (void)didTapRightButton {

}

- (void)didTapBottomRightButton {

}

#pragma mark - Private

- (void)setSelectedCell {

}

#pragma mark -

- (void)displayItemAtIndex:(NSIndexPath *)indexPath {
    self.selectedIndexPath = indexPath;
}


@end